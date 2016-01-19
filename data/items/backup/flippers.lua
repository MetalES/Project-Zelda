local item = ...
local volume_bgm = sol.audio.get_music_volume()

function item:on_created()
  self:set_savegame_variable("b1816")
self:set_sound_when_brandished("/common/big_item")
end

function item:on_obtaining() 
  sol.audio.set_music_volume(0)
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
end

function item:on_variant_changed(variant)
  -- the possession state of the flippers determines the built-in ability "swim"
  self:get_game():set_ability("swim", variant)
end
