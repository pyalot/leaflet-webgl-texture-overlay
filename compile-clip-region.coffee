earcut = require 'earcut'
fs = require 'fs'
path = require 'path'
process = require 'process'

if require.main == module
    infileName = process.argv[2]
    console.log infileName
    if infileName? and path.extname(infileName) == '.json'
        outfileName = infileName[...infileName.length-5] + '.vertices'

        data = JSON.parse(fs.readFileSync(infileName, encoding:'utf-8'))
        data = earcut.flatten(data)

        triangles = earcut(data.vertices, data.holes, data.dimensions)
        triangles = new Int32Array(triangles) #might need change to Float32Array for lat/lng
        fs.writeFileSync(outfileName, new Buffer(triangles.buffer))
