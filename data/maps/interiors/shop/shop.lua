local map = ...
local timer


function map:on_started()
self:get_game():show_map_name("water_temple")
--self:display_fog("forest_alt", 4, 7, 50)

local movement = sol.movement.create("straight")
movement:set_speed(16)
movement:set_max_distance(100)
movement:set_angle(3*math.pi/2)
movement:start(avoid_guard_2)

local movement2 = sol.movement.create("straight")
movement2:set_speed(16)
movement2:set_max_distance(100)
movement2:set_angle(0*math.pi/2)
movement2:start(avoid_guard_3)

end


function dd:on_activated()
if not show_bars then self:get_game():show_bars() end

map:move_camera(10, 10, 10, function()

sol.audio.play_sound("common/door/mecanical_open")
sol.timer.start(1500, function()
sol.audio.set_music_volume(sol.audio.get_music_volume() / 3)
timer = sol.timer.start(15000, function() 
  sol.audio.set_music_volume(self:get_game():get_value("old_volume")) 
  dd:set_activated(false) 
  dd_2:set_activated(false) 
  sol.audio.play_sound("objects/on_switch") 
end)
timer:set_with_sound_effect(true)
timer:set_suspended_with_map(true)
end)
end, 2000,1500 )

end

function dd_2:on_activated()
self:get_game():clear_map_name()
self:get_game():show_map_name("0", "boss_name")
--timer:set_remaining_time(15000)
--timer:set_with_sound_effect(true)
--imer:set_suspended_with_map(true)
end
