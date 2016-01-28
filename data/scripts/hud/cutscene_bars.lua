local cutscene_bars_builder = {}

function cutscene_bars_builder:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function cutscene_bars_builder:initialize(game)
  self.game = game
  self.bar0, self.bar1 = sol.surface.create(320, 26), sol.surface.create(320, 27)
  self.bar0:fill_color({0,0,0})
  self.bar1:fill_color({0,0,0})
  self.state = 0
  self.initialized = false
  self.displaying_bars = false
end

function cutscene_bars_builder:on_started()
  self:check()
end

function cutscene_bars_builder:check()
    if self.game.display_cutscene_bars and not self.game.dispose_cutscene_bars and not self.initialized then
      self:display_bars()
	  self.initialized = true
    elseif self.game.display_cutscene_bars and  self.game.dispose_cutscene_bars then
	  self:display_bars()
	  self.initialized = false
	end
	
  sol.timer.start(self.game, 250, function()
     self:check()
  end)
end

function cutscene_bars_builder:display_bars()
-- Movements
 local up = sol.movement.create("straight")
	   up:set_speed(500)
	   up:set_angle(math.pi / 2)
       up:set_max_distance(26)
 local down = sol.movement.create("straight")
	   down:set_speed(500)
	   down:set_angle(3 * math.pi / 2)
       down:set_max_distance(26)
	   
  if self.state == 0 then
    self.displaying_bars = true
    up:start(self.bar1)  
    down:start(self.bar0)  
	self.state = 1
  elseif self.state == 1 then
    up:start(self.bar0)  
    down:start(self.bar1, function()
	  self.state = 0
	  self.game.display_cutscene_bars = false
	  self.game.dispose_cutscene_bars = false
	  self.displaying_bars = false
	  self.initialized = false
	end)  
  end
end

function cutscene_bars_builder:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function cutscene_bars_builder:on_draw(dst_surface)
  if self.displaying_bars then
  self.bar0:draw(dst_surface, 0, -26)
  self.bar1:draw(dst_surface, 0 , 239)
  end
end

return cutscene_bars_builder