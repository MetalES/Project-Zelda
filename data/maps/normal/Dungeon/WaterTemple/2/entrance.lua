local map = ...
local game = map:get_game()
local hero = map:get_entity("hero")

map.overlay_angles = {
  7 * math.pi / 4
}
map.overlay_step = 1

function map:set_overlay()
  map.overlay = sol.surface.create("fogs/forest_alt.png")
  map.overlay:set_opacity(16)
  map.overlay_m = sol.movement.create("straight")
  map.restart_overlay_movement()

end

function map:restart_overlay_movement()
  map.overlay_m:set_speed(4) 
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
  local camera_x, camera_y = self:get_camera_position()
  local overlay_width, overlay_height = map.overlay:get_size()
  local screen_width, screen_height = destination_surface:get_size()
  local x, y = camera_x, camera_y
  x, y = -math.floor(x), -math.floor(y)
  x = x % overlay_width - 16 * overlay_width --2
  y = y % overlay_height - 16 * overlay_height
  local dst_y = y
  while dst_y < screen_height + overlay_height do
    local dst_x = x
    while dst_x < screen_width + overlay_width do
      map.overlay:draw(destination_surface, dst_x, dst_y)
      dst_x = dst_x + overlay_width
    end
    dst_y = dst_y + overlay_height
  end
end

if not game:get_value("chest_appeared") then chest:get_sprite():fade_out(1); chest:set_enabled(false) end

function test:on_activated()
game:set_value("is_cutscene",true)
game:set_pause_allowed(false)
sol.audio.play_sound("/common/secret_discover_minor")
game:set_hud_enabled(false)

sol.timer.start(10, function() hero:freeze() end)

sol.timer.start(100, function()
local x, y, layer = chest:get_position()
local chest_effect = map:create_custom_entity({
      x = x,
      y = y - 1, -- -5
      layer = layer + 1,
      direction = 0,
      sprite = "entities/dungeon/gameplay_sequence_chest_appearing",
    })

  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(2)
  m:set_angle(math.pi / 2)
  m:set_max_distance(32)
  m:start(chest_effect)

chest_effect:get_sprite():fade_out(1)
chest_effect:get_sprite():fade_in(30)

sol.audio.play_sound("/common/chest_appear")

sol.timer.start(2900, function()
chest:set_enabled(true)
chest:get_sprite():fade_in(40) 
end)

sol.timer.start(5000, function()
chest_effect:get_sprite():fade_out(10) 
end)
sol.timer.start(6000, function()
hero:unfreeze()
game:set_value("is_cutscene",false)
game:set_pause_allowed(true)
game:set_value("chest_appeared", true)
game:set_hud_enabled(true)
chest_effect:remove()
end)

end)


end

