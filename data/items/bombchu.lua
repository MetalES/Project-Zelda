local item = ...

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
end

function item:on_started()
  local bombchu_bag = self:get_game():get_item("bombchu_bag")
  self:set_obtainable(bombchu_bag:has_variant())
end

function item:on_obtaining(variant, savegame_variable)
  local amounts = {1, 3, 5}
  local amount = amounts[variant]
  self:get_game():get_item("bombchu_counter"):add_amount(amount)
end