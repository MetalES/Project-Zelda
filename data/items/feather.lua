local item = ...
local volume_bgm = sol.audio.get_music_volume()

function item:on_created()
  self:set_savegame_variable("i1815")
  self:set_assignable(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("/common/big_item")
end

function item:on_obtaining() 
  sol.audio.set_music_volume(0)
end


function item:on_using()
  sol.audio.play_sound("jump")
  local hero = self:get_map():get_entity("hero")
  local direction4 = hero:get_direction()
  hero:start_jumping(direction4 * 2, 32, false)
  self:set_finished()
end


function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
end