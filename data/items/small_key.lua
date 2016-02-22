local item = ...
local volume_bgm = item:get_game():get_value("old_volume")


function item:on_created()
  self:set_shadow("small")
  self:set_brandish_when_picked(true)
  self:set_sound_when_picked("picked_small_key")  
  self:set_sound_when_brandished("/common/minor_item")

end


function item:on_obtaining(variant, savegame_variable) 
  sol.audio.set_music_volume(0)
  self:get_game():add_small_key()
end


function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
self:get_game():show_cutscene_bars(false)
end