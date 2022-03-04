local class = require "middleclass"

Map = class("Map")

TILE_BRICK = 1

TILE_EMPTY = 30

local TILE_POLISH = 34

SECRET_BOX = 25
SECRET_BOX_HIT = 26


local BUSH1 = 309
local BUSH2 = 310
local BUSH3 = 311

local FLAG1 = 314
local FLAG2 = 281

local CLOUDTOP1 = 661
local CLOUDTOP2 = 662
local CLOUDTOP3 = 663
local CLOUDBOT1 = 694
local CLOUDBOT2 = 695
local CLOUDBOT3 = 696

SCROLL_SPEED = 62

function Map:initialize(w, h)
    self.gameState = 'play'

    self.mapWidth = 100
    self.mapHeight = 28

    self.tileWidth = 16
    self.tileHeight = 16
    self.spriteSheet = love.graphics.newImage("graphics/block_sprites_sheet.png")
    self.tileSprite = generateQuads(self.spriteSheet, self.tileWidth, self.tileHeight)
    self.tiles = {} 

    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    self.music = love.audio.newSource('music/Overworld.mp3', 'static')
    self.win = love.audio.newSource('music/Air_Horn.mp3', 'static')
    self.cod_hitsound = love.audio.newSource('sounds/hitsound.wav', 'static')

    self.camX = 0
    self.camY = -3

    for y = 1, self.mapHeight / 2 do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    for y = self.mapHeight / 2, self.mapHeight do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_BRICK)
        end
    end

    local x = 1
    while x < self.mapWidth do
        -- Generate Cloud
        if x < self.mapWidth - 3 then
            if math.random(20) == 1 then

                local start_cloud = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, start_cloud, CLOUDTOP1)
                self:setTile(x + 1, start_cloud, CLOUDTOP2)
                self:setTile(x + 2, start_cloud, CLOUDTOP3)
                self:setTile(x, start_cloud + 1, CLOUDBOT1)
                self:setTile(x + 1, start_cloud + 1, CLOUDBOT2)
                self:setTile(x + 2, start_cloud + 1, CLOUDBOT3)
            end
        end

        -- Generate Bush
        if x < self.mapWidth - 3 then
            if math.random(20) == 1 then

                local start_bush = self.mapHeight / 2 - 1

                self:setTile(x, start_bush, BUSH1)
                self:setTile(x + 1, start_bush, BUSH2)
                self:setTile(x + 2, start_bush, BUSH3)
            end
        end

        if x < self.mapWidth - 24 then
            -- Genenerate Gap
            if math.random(20) == 1 then
                for j = self.mapHeight / 2, self.mapHeight do
                    self:setTile(x, j, TILE_EMPTY)
                    self:setTile(x + 1, j, TILE_EMPTY)
                end 
            end
            
            -- Generate Columns
            if math.random(20) == 1 then
                self:setTile(x,self.mapHeight / 2 - 1, TILE_BRICK)
                self:setTile(x,self.mapHeight / 2 - 2, TILE_BRICK)
            end

            -- Generate Secret box
            if math.random(20) == 1 then

                self:setTile(x, self.mapHeight / 2 - 5, SECRET_BOX)
            end
        end
        
        x = x + 1
    end

    -- Create Stairs
    local step = 1
    for x = self.mapWidth - 20, self.mapWidth - 14 do
        for y = 1, step do
            self:setTile(x, (self.mapHeight / 2) - y, TILE_POLISH)
            if step == 7 then
                self:setTile(x + 1, (self.mapHeight / 2) - y, TILE_POLISH)
            end

        end
        step = step + 1
    end

    -- Create Flag
    local startFlag = self.mapWidth - 5
    local flagBase = self.mapHeight / 2 - 1

    self:setTile(startFlag, flagBase, TILE_POLISH)
    for h = 1, 8 do
        self:setTile(startFlag, flagBase - h, FLAG1)
    end
    self:setTile(startFlag, flagBase - 9, FLAG2)

    self.player = Player(self)

    -- Start background music
    self.music:setLooping(true)
    self.music:setVolume(0.25)
    self.music:play()
    self.cod_hitsound:setVolume(0.15)

    -- Set font
    medium_font = love.graphics.newFont("Pixeled.ttf", 10)
end

function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

function Map:atTile(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:collides(tile)
    -- Define our collidable tiles
    local collidables = {
        TILE_BRICK, TILE_POLISH, SECRET_BOX, SECRET_BOX_HIT
    }

    -- Check for colide flag
    if tile == FLAG1 then
        self.gameState = 'win'
    end

    -- Iterate and return if our tile type matches
    for _, v in ipairs(collidables) do
        if tile == v then
            return true
        end
    end

    return false
end

function Map:update(dt)
    if self.gameState == 'play' then 
        self.camX = math.max(0,
            math.min(self.player.x - VIRTUAL_WIDTH / 2,
                math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

        self.player:update(dt)
    end

    if self.gameState == 'win' then
        self.music:stop()
        self.win:play()
        self.cod_hitsound:play()
    end
end

function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            love.graphics.draw(self.spriteSheet, self.tileSprite[self:getTile(x, y)],
                (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
        end
    end

    if self.gameState == 'win' then
        love.graphics.setFont(medium_font)
        love.graphics.print("VICTORY", self.camX + VIRTUAL_WIDTH * 2 / 5,
                        self.camY + VIRTUAL_HEIGHT / 5)
    end
    displayFPS(self.camX + 10, self.camY + 10)
    self.player:render()
end