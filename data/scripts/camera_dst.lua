local cos, sin = math.cos, math.sin

local camera = {}
camera.__index = camera

smooth.smooth = {}


function camera.smooth.damped(stiffness)
	assert(type(stiffness) == "number", "Invalid parameter: stiffness = "..tostring(stiffness))
	return function(dx,dy, s)
		local dts = love.timer.getDelta() * (s or stiffness)
		return dx*dts, dy*dts
	end
end


local function new(x,y, zoom, rot, smoother)
	x,y  = x or love.graphics.getWidth()/2, y or love.graphics.getHeight()/2
	zoom = zoom or 1
	rot  = rot or 0
	return setmetatable({x = x, y = y, scale = zoom, rot = rot}, camera)
end

function camera:move(dx,dy)
	self.x, self.y = self.x + dx, self.y + dy
	return self
end

function camera:pos()
	return self.x, self.y
end

function camera:rotate(phi)
	self.rot = self.rot + phi
	return self
end

function camera:rotateTo(phi)
	self.rot = phi
	return self
end

function camera:zoom(mul)
	self.scale = self.scale * mul
	return self
end

function camera:zoomTo(zoom)
	self.scale = zoom
	return self
end

function camera:attach()
local getWidth, getHeight = screen:get_size()
	local cx,cy = love.graphics.getWidth()/(2*self.scale), love.graphics.getHeight()/(2*self.scale)
	love.graphics.push()
	self.scale(self.scale)
	love.graphics.translate(cx, cy)
	love.graphics.rotate(self.rot)
	love.graphics.translate(-self.x, -self.y)
end

function camera:detach()
	love.graphics.pop()
end

function camera:draw(func)
	self:attach()
	func()
	self:detach()
end

function camera:cameraCoords(x,y)
	-- x,y = ((x,y) - (self.x, self.y)):rotated(self.rot) * self.scale + center
	local w,h = love.graphics.getWidth(), love.graphics.getHeight()
	local c,s = cos(self.rot), sin(self.rot)
	x,y = x - self.x, y - self.y
	x,y = c*x - s*y, s*x + c*y
	return x*self.scale + w/2, y*self.scale + h/2
end

function camera:worldCoords(x,y)
	-- x,y = (((x,y) - center) / self.scale):rotated(-self.rot) + (self.x,self.y)
	local w,h = love.graphics.getWidth(), love.graphics.getHeight()
	local c,s = cos(-self.rot), sin(-self.rot)
	x,y = (x - w/2) / self.scale, (y - h/2) / self.scale
	x,y = c*x - s*y, s*x + c*y
	return x+self.x, y+self.y
end

function camera:mousePos()
	return self:worldCoords(love.mouse.getPosition())
end

-- camera scrolling utilities - adapted from 

--- Lock camera's x coordinate.
-- @param x X coordinate (in world coordinates) to lock to.
-- @param smoother Overriding smoothing function (optional).
-- @param ... Additional parameters to the smoothing function (optional).
-- @return The camera.
function camera:lockX(x, smoother, ...)
	local dx, dy = (smoother or self.smoother)(x - self.x, self.y, ...)
	self.x = self.x + dx
	return self
end

function camera:lockY(y, smoother, ...)
	local dx, dy = (smoother or self.smoother)(self.x, y - self.y, ...)
	self.y = self.y + dy
	return self
end

function camera:lockPos(x,y, smoother, ...)
	return self:move((smoother or self.smoother)(x - self.x, y - self.y, ...))
end

function camera:lockWindow(x, y, x_min, x_max, y_min, y_max, smoother, ...)
	-- figure out displacement in camera coordinates
	x,y = self:cameraCoords(x,y)
	local dx, dy = 0,0
	if x < x_min then
		dx = x - x_min
	elseif x > x_max then
		dx = x - x_max
	end
	if y < y_min then
		dy = y - y_min
	elseif y > y_max then
		dy = y - y_max
	end

	-- transform displacement to movement in world coordinates
	local c,s = cos(-self.rot), sin(-self.rot)
	dx,dy = (c*dx - s*dy) * self.scale, (s*dx + c*dy) * self.scale

	-- move
	self:move((smoother or self.smoother)(dx,dy,...))
end

-- the module
return setmetatable({new = new, smooth = camera.smooth},
	{__call = function(_, ...) return new(...) end})