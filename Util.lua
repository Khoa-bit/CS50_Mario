function generateQuads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetcounter = 1
    local quads = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            quads[sheetcounter] = love.graphics.newQuad(x * tilewidth,
                                                        y * tileheight,
                                                        tilewidth,
                                                        tileheight,
                                                        atlas:getDimensions()
                                                        )
            sheetcounter = sheetcounter + 1
        end
    end

    return quads
end