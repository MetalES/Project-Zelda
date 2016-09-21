local camera_meta = sol.main.get_metatable("camera")

function camera_meta:quake(map, direction, length)
  local speed = 700
  local map = self:get_map()
  local hx, hy, _ = map:get_hero():get_position()
  local w, h = map:get_size()
  local x, y, dx, dy
  if direction%2 == 0 then x = w/2; y = hy; dx = 8; dy = 0
  else x = hx; y = h/2; dx = 0; dy = 8 end
  map:move_camera(x+dx, y+dy, speed, function() 
	map:move_camera(x-dx, y-dy, speed, function()
	  self:quake(map, direction, length)
	end, 0, length)
  end, 0, length)
end