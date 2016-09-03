local cutscene_bars_builder = {}

function cutscene_bars_builder:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function cutscene_bars_builder:initialize(game)
  self.bar0, self.bar1 = sol.surface.create(320, 26), sol.surface.create(320, 27)
end

function cutscene_bars_builder:show_bars()
  self:move_surface(1, self.bar1)
  self:move_surface(3, self.bar0)
  self.bar0:fill_color({0,0,0})
  self.bar1:fill_color({0,0,0})
end

function cutscene_bars_builder:is_active()
  local _, y = self.bar0:get_xy()
  return y ~= 0
end

-- Move the surface
function cutscene_bars_builder:move_surface(angle, object, callback)
 local move = sol.movement.create("straight")
   move:set_speed(500)
   move:set_angle(angle * math.pi / 2)
   move:set_max_distance(26)
   move:start(object, function() if callback ~= nil then callback() end end)
end

-- Hide the bars.
function cutscene_bars_builder:hide_bars()
  self:move_surface(1, self.bar0)
  self:move_surface(3, self.bar1, function() 
    self.bar0:set_xy(0, 0)
	self.bar1:set_xy(0, 0)
	self.bar0:clear()
    self.bar1:clear()
  end)
end

function cutscene_bars_builder:on_paused()
  self.avoid_draw = true
end

function cutscene_bars_builder:on_unpaused()
  self.avoid_draw = false
end

function cutscene_bars_builder:on_draw(dst_surface)
  if not self.avoid_draw then
    self.bar0:draw(dst_surface, 0, -26)
    self.bar1:draw(dst_surface, 0 , 239)
  end
end

return cutscene_bars_builder