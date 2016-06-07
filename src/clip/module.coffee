exports = class ClipRegion
    constructor: (@gf, @overlay) ->
        @fill = @gf.state
            shader: fs.open('fill.shader')
            colorWrite: [false, false, false, true]
            vertexbuffer:
                pointers: [
                    {name:'position', size:2}
                ]
        
        @holes = @gf.state
            shader: fs.open('holes.shader')
            colorWrite: [false, false, false, true]
            vertexbuffer:
                pointers: [
                    {name:'position', size:2}
                ]
        
        @clear = @gf.state
            shader: fs.open('clear.shader')
            colorWrite: [false, false, false, true]

        @dirty = false
        @haveFills = false
        @haveHoles = false

    check: ->
        if @dirty and @overlay.map? and @data?
            @upload()
            return true
        else
            return false

    draw: (southWest, northEast, verticalSize, verticalOffset) ->
        @clear.draw()

        if @haveFills
            @fill
                .float('verticalSize', verticalSize)
                .float('verticalOffset', verticalOffset)
                .vec2('slippyBounds.southWest', southWest.x, southWest.y)
                .vec2('slippyBounds.northEast', northEast.x, northEast.y)
                .draw()

        if @haveHoles
            @holes
                .float('verticalSize', verticalSize)
                .float('verticalOffset', verticalOffset)
                .vec2('slippyBounds.southWest', southWest.x, southWest.y)
                .vec2('slippyBounds.northEast', northEast.x, northEast.y)
                .draw()

    set: (@data) ->
        @dirty = true

    project: (coords) ->
        for i in [0...coords.length] by 2
            {x,y} = @overlay.map.project({lat:coords[i+1], lng:coords[i]}, 0).divideBy(256)
            coords[i] = x
            coords[i+1] = y
        return

    upload: ->
        @dirty = false

        intView = new Int32Array(@data)

        fillTriangleCount = intView[0]
        fillVertexCount = fillTriangleCount*3
        fillValueCount = fillVertexCount*2

        fills = new Float32Array(@data, 4, fillValueCount).slice()
        holes = new Float32Array(@data, 4+fills.byteLength).slice()

        if fills.length > 0
            @haveFills = true
            @project fills
            @fill.vertices fills
        else
            @haveFills = false

        if holes.length > 0
            @haveHoles = true
            @project holes
            @holes.vertices holes
        else
            @haveHoles = false
