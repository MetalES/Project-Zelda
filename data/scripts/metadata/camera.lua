local camera = sol.main.get_metatable("camera")


function camera:shake(x, y, force, direction8, max_distance, map, suspend, ignore_obstacle)
  local hx, hy , _ = map:get_hero():get_position()
  local w, h = map:get_size()
  local x, y, dx, dy
  
  if direction % 2 == 0 then 
    x = w/2; y = hy; dx = 8; dy = 0
  else 
    x = hx; y = h/2; dx = 0; dy = 8 
  end
  
  local mov0 = sol.movement.create("straight")
  mov0:set_speed(force)
  mov0:set_angle(direction8)
  mov0:set_max_distance(max_distance)
  mov0:start(self)
  
  -- map:move_camera(x+dx, y+dy, speed, function() 
	-- map:move_camera(x-dx, y-dy, speed, function()
	  -- self:quake(map, direction, length)
	-- end, 0, length)
  -- end, 0, length)
  
  
end


-- function enemy:quake(map, direction, length)
  -- local speed = 700
  -- local hx, hy, _ = map:get_hero():get_position()
  -- local w, h = map:get_size()
  -- local x, y, dx, dy
  -- if direction%2 == 0 then x = w/2; y = hy; dx = 8; dy = 0
  -- else x = hx; y = h/2; dx = 0; dy = 8 end
  -- map:move_camera(x+dx, y+dy, speed, function() 
	-- map:move_camera(x-dx, y-dy, speed, function()
	  -- self:quake(map, direction, length)
	-- end, 0, length)
  -- end, 0, length)
-- end