local class = require "middleclass"

require "Animation"

Player = class("Player")

local MOVE_SPEED = 22
local SLOW_VELOCITY = 18
local JUMP_VELOCITY = 700
local GRAVITY = 60

function Player:initialize(map)
    self.map = map
    self.texture = love.graphics.newImage("graphics/mario&luigi.png")
    self.width = 17
    self.height = 16
    self.x = map.tileWidth * 10
    self.y = map.tileHeight * (map.mapHeight / 2 - 1) - self.height

    self.dx = 0
    self.dy = 0

    self.SFX = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['coin'] = love.audio.newSource('sounds/coin.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static')
    }

    self.frames = generateQuads(self.texture, self.width, self.height)

    self.state = 'idle'
    self.direction = 'right'

    self.animations = {
        ['idle'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[1]
            },
            interval = 1
        },
        ['walking'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[2], self.frames[3], self.frames[4]
            },
            interval = 0.08
        },
        ['jumping'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[6]
            },
            interval = 1
        }
    }

    self.animation = self.animations['idle']

    self.behaviors = {
        ['idle'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = - JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.SFX['jump']:play()
            elseif love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = self.dx - MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = self.dx + MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            else
                self.animation = self.animations['idle']
            end

            -- Check if there's a tile beneath us
            if not self.map:collides(self.map:atTile(self.x, self.y + self.height).id) and
                not self.map:collides(self.map:atTile(self.x + self.width - 2, self.y + self.height).id) then
                    self.state = 'jumping'
                    self.animation = self.animations['jumping']
            end
        end,
        ['walking'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = - JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.SFX['jump']:play()
            elseif love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = self.dx - MOVE_SPEED
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = self.dx + MOVE_SPEED
            else
                self.state = 'idle'
            end

            -- Check for collisions
            self:checkRightCollisions()
            self:checkLeftCollisions()

            -- Check if there's a tile beneath us
            if not self.map:collides(self.map:atTile(self.x, self.y + self.height).id) and
                not self.map:collides(self.map:atTile(self.x + self.width - 2, self.y + self.height).id) then
                    self.state = 'jumping'
                    self.animation = self.animations['jumping']
            end
        end,
        ['jumping'] = function(dt)
            if love.keyboard.isDown('a') then
                self.dx = self.dx - MOVE_SPEED
                self.direction = 'left'
            elseif love.keyboard.isDown('d') then
                self.dx = self.dx + MOVE_SPEED
                self.direction = 'right'
            end

            self.dy = math.min(map.tileHeight * (map.mapHeight / 2 - 1) - self.height, self.dy + GRAVITY)

            if self.map:collides(self.map:atTile(self.x, self.y + self.height).id) or
                self.map:collides(self.map:atTile(self.x + self.width - 2, self.y + self.height).id) then
                    self.dy = 0
                    self.y = (self.map:atTile(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
                    self.animation = self.animations['idle']
                    self.state = 'idle'
            end

            -- Check for collisions
            self:checkRightCollisions()
            self:checkLeftCollisions()
        end

    }
end

function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)

    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
    
    if not love.keyboard.wasPressed('d') then
        if self.dx >= 0 then
            self.dx = math.max(0, self.dx - SLOW_VELOCITY)
        end
    end
    if not love.keyboard.wasPressed('a') then
        if self.dx <= 0 then
            self.dx = math.min(0, self.dx + SLOW_VELOCITY)
        end
    end

    -- Check collisions when Jumping
    if self.dy < 0 then
        if self.map:atTile(self.x, self.y).id ~= TILE_EMPTY or
            self.map:atTile(self.x + self.width - 2, self.y).id ~= TILE_EMPTY then
                -- Reset jump speed
                self.dy = 0

                -- Change tile id and add sound effect
                local playCoin = false
                local playHit = false
                if self.map:atTile(self.x, self.y).id == SECRET_BOX then
                    self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
                        math.floor(self.y / self.map.tileHeight) + 1, SECRET_BOX_HIT)
                    playCoin = true
                else
                    playHit = true
                end
                if self.map:atTile(self.x + self.width - 2, self.y).id == SECRET_BOX then
                    self.map:setTile(math.floor((self.x + self.width - 2) / self.map.tileWidth) + 1,
                        math.floor(self.y / self.map.tileHeight) + 1, SECRET_BOX_HIT)
                    playCoin = true
                else
                    playHit = true
                end

                if playCoin then
                    self.SFX['coin']:play()
                elseif playHit then
                    self.SFX['hit']:play()
                end
        end
    end
end

function Player:render()
    local scaleX
    if self.direction == 'left' then
        scaleX = -1
    else
        scaleX = 1
    end

    love.graphics.draw(self.texture, self.animation:getCurrentFrame(),
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
        0, scaleX, 1, math.floor(self.width / 2), math.floor(self.height / 2))
end

function Player:checkRightCollisions()
    if self.dx > 0 then
        if self.map:collides(self.map:atTile(self.x + self.width, self.y).id) or
            self.map:collides(self.map:atTile(self.x + self.width, self.y + self.height - 1).id) then
                self.dx = 0
                self.x = (self.map:atTile(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width + 1
        end
    end
end

function Player:checkLeftCollisions()
    if self.dx < 0 then
        if self.map:collides(self.map:atTile(self.x - 2, self.y).id) or
            self.map:collides(self.map:atTile(self.x - 2, self.y + self.height - 1).id) then
                self.dx = 0
                self.x = math.floor((self.map:atTile(self.x, self.y).x * self.map.tileWidth - self.width + 2))
        end
    end
end