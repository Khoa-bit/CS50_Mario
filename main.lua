local push = require "push"

require "Util"
require "Map"
require "Player"

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

function love.load()
    math.randomseed(os.time())
    
    map = Map()

    love.graphics.setDefaultFilter("nearest", "nearest")
    push:setupScreen(
        VIRTUAL_WIDTH,
        VIRTUAL_HEIGHT,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        {
            fullscreen = false,
            resizable = false,
            vsync = true
        }
    )

    medium_font = love.graphics.newFont("Pixeled.ttf", 10)
    smallFont = love.graphics.newFont("Pixeled.ttf", 5)

    love.keyboard.keysPressed = {}
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    map:update(dt)

    love.keyboard.keysPressed = {}
end

function love.draw()
    push:apply("start")
    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))
    love.graphics.clear(108/255, 140/255, 255/255, 255/255)
    -- love.graphics.setFont(medium_font)
    -- love.graphics.print("hello world", 100, 100)
    map:render()

    push:apply("end")
end

function displayFPS(x, y)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    love.graphics.print("FPS: " .. (love.timer.getFPS()), x, y)
    love.graphics.setColor(1, 1, 1, 1)
end
