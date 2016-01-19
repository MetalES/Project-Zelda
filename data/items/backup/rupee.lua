local item = ...
local game = item:get_game()

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_sound_when_picked("picked_rupee")
  self:set_brandish_when_picked(false)
end

function item:on_obtaining(variant, savegame_variable)
  local amounts = {1, 5, 20, 50, 100, 300}
  local amount = amounts[variant]
  local x, y, layer = game:get_hero():get_position()

self:get_game():add_money(amount)
end