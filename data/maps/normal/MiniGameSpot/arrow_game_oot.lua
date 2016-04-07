local map = ...
local score = 0
local max_rupee = 10
local element_destroyed

function map:on_started()
  sol.audio.play_music("interiors/minigame_shoot_room_intro", function()
  sol.audio.play_music("interiors/minigame_shoot_room_loop") end)
  obstacle_game_started:set_enabled(false)
end

for element_destroyed in map:get_entities("destroy_effect") do
   element_destroyed.on_created = function()
     score = score + 10
   end
end