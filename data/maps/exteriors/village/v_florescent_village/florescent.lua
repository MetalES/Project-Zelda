local map = ...
local game = map:get_game()

map.overlay_angles = {
  7 * math.pi / 4
}
map.overlay_step = 1

function map:set_overlay()

  map.overlay = sol.surface.create("fogs/overworld_smallcloud.png")
  map.overlay:set_opacity(96)
  map.overlay_m = sol.movement.create("straight")
  map.restart_overlay_movement()

end

function map:restart_overlay_movement()

  map.overlay_m:set_speed(16) 
  map.overlay_m:set_max_distance(100)
  map.overlay_m:set_angle(map.overlay_angles[map.overlay_step])
  map.overlay_step = map.overlay_step + 1
  if map.overlay_step > #map.overlay_angles then
    map.overlay_step = 1
  end
  map.overlay_m:start(map.overlay, function()
    map:restart_overlay_movement()
  end)

end

function map:on_started(destination)
  map:set_overlay()

end

function map:on_draw(destination_surface)

  -- Make the overlay scroll with the camera, but slightly faster to make
  -- a depth effect.
  local camera_x, camera_y = self:get_camera_position()
  local overlay_width, overlay_height = map.overlay:get_size()
  local screen_width, screen_height = destination_surface:get_size()
  local x, y = camera_x, camera_y
  x, y = -math.floor(x), -math.floor(y)

  -- The overlay's image may be shorter than the screen, so we repeat its
  -- pattern. Furthermore, it also has a movement so let's make sure it
  -- will always fill the whole screen.
  x = x % overlay_width - 16 * overlay_width --2
  y = y % overlay_height - 16 * overlay_height

  local dst_y = y
  while dst_y < screen_height + overlay_height do
    local dst_x = x
    while dst_x < screen_width + overlay_width do
      -- Repeat the overlay's pattern.
      map.overlay:draw(destination_surface, dst_x, dst_y)
      dst_x = dst_x + overlay_width
    end
    dst_y = dst_y + overlay_height
  end

end

local function random_walk(npc)

  local m = sol.movement.create("random_path")
  m:set_speed(16)
  m:start(npc)
end

random_walk(butterfly)
random_walk(butterfly_2)
random_walk(butterfly_3)
