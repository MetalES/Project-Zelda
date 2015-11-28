local bars = {} 

function bars:new(game)

  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function bars:initialize(game)

  self.game = game
  self.surface = sol.surface.create(320, 26)
  self.surface:fill_color({0,0,0})
  self.surface:set_opacity(255)
  self.surface:set_xy(-186,-56) --30 - 26

  self.surface2 = sol.surface.create(320, 26)
  self.surface2:fill_color({0,0,0})
  self.surface2:set_opacity(255)
  self.surface2:set_xy(-186,210) --184 + 26

end

function bars:on_started()
go_up()
go_down()
end

function bars:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function go_up()
  local m = sol.movement.create("straight")
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(26)
  m:start(surface2)
end

function go_down()
  local m = sol.movement.create("straight")
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(26)
  m:start(surface)
end


function bars:on_draw(dst_surface)

  local x, y = self.dst_x, self.dst_y
  local width, height = dst_surface:get_size()
  if x < 0 then
    x = width + x
  end
  if y < 0 then
    y = height + y
  end
  self.surface:draw(dst_surface, x, y)
  self.surface2:draw(dst_surface, x, y)

end

return bars