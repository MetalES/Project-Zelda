local map = ...
local game = map:get_game()
local current_ghost = game:get_value("current_ghost")

-- TODO : ghosts exist on map, move them out of bound after cutscene

function map:on_started(destination)
sol.audio.play_music("/dungeons/arbiter_grounds_intro", function() 
sol.audio.play_music("/dungeons/arbiter_grounds_loop")end)
end

function scene_sensor:on_activated()
hero:freeze()
game:set_hud_enabled(false)

if game:get_value("i1820") >= 1 then hero:set_animation("walking_with_shield") else hero:set_animation("walking") end
--create the target movement for Link and start the cutscene right after
local target = sol.movement.create("target")
target:set_target(256, 184)
target:set_speed(44)
target:start(hero, function() hero:set_animation("stopped") 
--1e9 sets an infinite loop offset
map:move_camera(256, 152, 50, function() 
sol.timer.start(800, function() game:start_dialog("gameplay.logic._cannot_lift_should_cut") end)
hero:unfreeze()
end, 0, 1e9) -- map camera movement 
end) -- target movement 

local ghost_position = map:get_entity("ghost")
local ghost_target = sol.movement.create("target")
ghost_target:set_target(256,152)




end
