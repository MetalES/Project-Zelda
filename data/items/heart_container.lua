local item = ...
local volume_bgm = sol.audio.get_music_volume()

function item:on_created()
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("heart_container")
end


function item:on_obtaining(variant, savegame_variable) 
  sol.audio.set_music_volume(0)
end

function item:on_obtained(variant, savegame_variable)
  local game = self:get_game()
  game:add_max_life(4)
  game:set_life(game:get_max_life())
  self:get_game():add_stamina(50)
  sol.audio.set_music_volume(volume_bgm)
end
