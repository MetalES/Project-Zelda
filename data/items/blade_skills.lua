local item = ...
local sound_played_on_brandish = "/common/big_item"

function item:on_created()
  self:set_savegame_variable("previous_skill_learned")
  self:set_sound_when_brandished(sound_played_on_brandish)
end

function item:on_obtaining()
sol.audio.set_music_volume(0)
end

function item:on_map_changed()
  if self:get_game():get_value("skill_2_learned") then
    for destructibles in self:get_map():get_entities("jar") do
     destructibles:set_can_be_cut(true)
    end
  end
end

function item:on_obtained(variant, savegame_variable)
self:get_game():set_skill_learned(variant, true)

if variant == 2 then 
  self:on_map_changed()
end

-- elseif self:get_variant() == 2 then -- Rock break
-- elseif self:get_variant() == 3 then -- Roll Dash, WIP
-- elseif self:get_variant() == 6 then -- Perish Beam, WIP
-- elseif self:get_variant() == 5 then -- Sword Beam, WIP
-- elseif self:get_variant() == 4 then -- Down Thrust, WIP
-- elseif self:get_variant() == 7 then -- Hurricane Blade, WIP
-- elseif self:get_variant() == 8 then -- Faster Spin Attack Loading, WIP
self:get_game():set_pause_allowed(true)
sol.audio.set_music_volume(self:get_game():get_value("old_volume"))
end