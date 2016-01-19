local item = ...
local game = item:get_game()

local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = false

local volume_bgm = game:get_value("old_volume")

function item:on_created()
  self:set_savegame_variable("blade_skill_learned")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end

function item:on_obtaining()
sol.audio.set_music_volume(0)
end

function item:on_obtained(variant, savegame_variable)
if self:get_variant() == 1 then -- Spin Attack
game:set_value("skill_spin_attack", true)
-- elseif self:get_variant() == 2 then -- Rock break, WIP
-- elseif self:get_variant() == 3 then -- Roll Dash, WIP
-- elseif self:get_variant() == 4 then -- Down Thrust, WIP
-- elseif self:get_variant() == 5 then -- Sword Beam, WIP
-- elseif self:get_variant() == 6 then -- Perish Beam, WIP
-- game:set_value("skill_perish_beam", true)
-- elseif self:get_variant() == 7 then -- Hurricane Blade, WIP
-- elseif self:get_variant() == 8 then -- Faster Spin Attack Loading, WIP
game:set_pause_allowed(true)
end
end