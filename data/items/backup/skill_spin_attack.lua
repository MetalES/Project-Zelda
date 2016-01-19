local item = ...
local sound_played_on_brandish = "/common/big_item"

function item:on_created()
  self:set_savegame_variable("spin_attack_learned")
  self:set_sound_when_brandished(sound_played_on_brandish)
end

-- elseif self:get_variant() == 2 then -- Rock break, WIP
-- elseif self:get_variant() == 3 then -- Roll Dash, WIP
-- elseif self:get_variant() == 4 then -- Down Thrust, WIP
-- elseif self:get_variant() == 5 then -- Sword Beam, WIP
-- elseif self:get_variant() == 6 then -- Perish Beam, WIP
-- game:set_value("skill_perish_beam", true)
-- elseif self:get_variant() == 7 then -- Hurricane Blade, WIP
-- elseif self:get_variant() == 8 then -- Faster Spin Attack Loading, WIP