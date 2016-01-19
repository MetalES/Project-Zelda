local song = ...
local song_name = "zelda_lullaby"

function song:on_created()
  self:set_savegame_variable(song_name.."learned")
end

function song:on_obtaining()
self:get_game():get_hero():set_animation("ocarina_brandish")
end