earcut = require 'earcut'
fs = require 'fs'
path = require 'path'
process = require 'process'

tessellate = (data) ->
    vertices = new Float32Array(data.length*2)
    for [x,y], i in data
        vertices[i*2] = x
        vertices[i*2+1] = y
    indices = earcut(vertices)
    result = new Float32Array(indices.length*2)
    for index, i in indices
        x = vertices[index*2]
        y = vertices[index*2+1]
        result[i*2] = x
        result[i*2+1] = y
    return result

concat = (data) ->
    length = 0
    for vertices in data
        length += vertices.length

    result = new Float32Array(length)
    i = 0
    for vertices in data
        result.set(vertices, i)
        i += vertices.length
    return result

flatten = (data) ->
    if typeof(data[0][0][0]) == 'number'
        data = [data]
    else if typeof(data[0][0][0][0]) == 'number'
        null
    else
        throw new Error('unknown geojson format')

    fills = []
    holes = []

    for shape in data
        fills.push tessellate(shape[0])
        for hole in shape[1...]
            holes.push tessellate(hole)

    fills = concat(fills)
    holes = concat(holes)

    fillVertexCount = fills.length/2
    fillTriangleCount = fillVertexCount/3

    result = new ArrayBuffer(4+fills.byteLength+holes.byteLength)
    intView = new Int32Array(result)
    intView[0] = fillTriangleCount

    floatView = new Float32Array(result, 4)
    floatView.set(fills)
    floatView.set(holes, fills.length)
    return result

if require.main == module
    infileName = process.argv[2]
    if infileName? and path.extname(infileName) == '.json'
        outfileName = infileName[...infileName.length-5] + '.vertices'
        console.log 'converting', infileName, '->', outfileName

        data = JSON.parse(fs.readFileSync(infileName, encoding:'utf-8'))
        data = flatten(data)
        fs.writeFileSync(outfileName, new Buffer(data))
