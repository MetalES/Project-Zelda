local map = ...


function map:on_started()
  sol.audio.play_music("interiors/minigame_shoot_room_intro", function()
  sol.audio.play_music("interiors/minigame_shoot_room_loop") end)
end