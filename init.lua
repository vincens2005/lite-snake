-- mod-version:2 lite-xl 2.0
local core = require "core"
local common = require "core.common"
local style = require "core.style"
local command = require "core.command"
local config = require "core.config"
local View = require "core.view"
local keymap = require "core.keymap"

style.snake_color = {common.color "#00df00"}
style.apple_color = {common.color "#ff0000"}

config.snake_size = 20 * SCALE
config.snake_length = 8
config.snake_wall_die = true
config.snake_fps_fac = 5

local SnakeView = View:extend()

function SnakeView:new()
	SnakeView.super.new(self)
	self.is_snake = true
	self.frame_fac = 0
	self.game_size = {
		x = 0,
		y = 0
	}
	self.score = 0
	self.snake = {}
	self.apple_pos = {}
	self.direction = "LEFT"
	self.initted = false
end

function SnakeView:init()
	self.initted = true
	self.score = 0
	self:randomize_apple()
	self:build_snake()
end

function SnakeView:get_name()
	return "Snake!"
end

function SnakeView:build_snake()
	self.snake = {}
	for i = 1, config.snake_length, 1 do
		self.snake[i] = {
			x = math.floor(self.game_size.x / 2) + i,
			y = math.floor(self.game_size.y / 2)
		}
	end
end

function SnakeView:randomize_apple()
	math.randomseed(os.time())
	local random1 = math.random()
	math.randomseed(random1 * os.time())
	local random2 = math.random()

	self.apple_pos = {
		x = math.floor(random1 * self.game_size.x),
		y = math.floor(random2 * self.game_size.y)
	}
end

function SnakeView:lengthen_snake()
	self.snake[#self.snake + 1] = {
		-- these values will be replaced later
		x = -5,
		y = -5
	}
end

function SnakeView:move_snake()
	if self.snake[1] == nil then return end
	local new_snake = {
		{
			x = self.snake[1].x,
			y = self.snake[1].y
		}
	}

	if self.direction == "RIGHT" then
		new_snake[1].x = new_snake[1].x + 1
	end

	if self.direction == "LEFT" then
		new_snake[1].x = new_snake[1].x - 1
	end

	if self.direction == "UP" then
		new_snake[1].y = new_snake[1].y - 1
	end

	if self.direction == "DOWN" then
		new_snake[1].y = new_snake[1].y + 1
	end

	-- wrap snake
	if not config.snake_wall_die then
		if new_snake[1].x < 0 then
			new_snake[1].x = self.game_size.x
		end

		if new_snake[1].x > self.game_size.x then
			new_snake[1].x = 0
		end

		if new_snake[1].y < 0 then
			new_snake[1].y = self.game_size.y
		end

		if new_snake[1].y > self.game_size.y then
			new_snake[1].y = 0
		end
	elseif new_snake[1].y > self.game_size.y or new_snake[1].y < 0 or new_snake[1].x > self.game_size.x or new_snake[1].x < 0 then
		-- reset game
		self:init()
	end


	for i,_ in ipairs(self.snake) do
		if i ~= 1 then
			new_snake[i] =  {
				x = self.snake[i - 1].x,
				y = self.snake[i - 1].y
			}
		end
	end

	self.snake = new_snake
end

function SnakeView:update(...)
	self.game_size = {
		x = math.floor(self.size.x / config.snake_size),
		y = math.floor(self.size.y / config.snake_size)
	}

	-- initialize game
	if not self.initted and self.size.x > 0 then
		self:init()
	end

	if self.frame_fac ~= config.snake_fps_fac then
		goto end_of_update
	end

	self:move_snake()
	self.frame_fac = 0

	if self.snake[1].x == self.apple_pos.x and self.snake[1].y == self.apple_pos.y then
			self.score = self.score + 1
			self:randomize_apple()
			self:lengthen_snake()
	end

	::end_of_update::
	self.frame_fac = self.frame_fac + 1
	SnakeView.super.update(self, ...)
end

function SnakeView:draw()
	self:draw_background(style.background)
	if self.apple_pos.x == nil then return end
	core.redraw = true

	local x, y = self:get_content_offset()

	-- draw apple
	renderer.draw_rect(self.apple_pos.x * config.snake_size + x, self.apple_pos.y  * config.snake_size + y, config.snake_size, config.snake_size, style.apple_color)

	-- draw snake
	for _, segment in ipairs(self.snake) do
		renderer.draw_rect(segment.x * config.snake_size + x, segment.y * config.snake_size + y, config.snake_size, config.snake_size, style.snake_color)
	end

	-- display score
	local score = string.format("%d", self.score)
	renderer.draw_text(style.big_font, score, x + 5, y, style.dim)
end

local old_key_pressed = keymap.on_key_pressed
function keymap.on_key_pressed(k)
	if core.active_view.is_snake then
		if core.active_view.direction ~= "UP" and (k == "s" or k == "down") then
			core.active_view.direction = "DOWN"
		end

		if core.active_view.direction ~= "DOWN" and (k == "w" or k == "up") then
			core.active_view.direction = "UP"
		end

		if core.active_view.direction ~= "LEFT" and (k == "d" or k == "right") then
			core.active_view.direction = "RIGHT"
		end

		if core.active_view.direction ~= "RIGHT" and (k == "a" or k == "left") then
			core.active_view.direction = "LEFT"
		end
	end
	return old_key_pressed(k)
end

local function open_snake_view()
	local node = core.root_view:get_active_node()
	node:add_view(SnakeView())
end

command.add(nil, {
	["snake:open"] = open_snake_view
})

return SnakeView
