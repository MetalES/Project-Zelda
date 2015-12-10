local item = ...

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
end

function item:on_started()
  local deku_bag = self:get_game():get_item("deku_nuts_bag")
  self:set_obtainable(deku_bag:has_variant())
end

function item:on_obtaining(variant, savegame_variable)
  local amounts = {1, 5, 10}
  local amount = amounts[variant]
  self:get_game():get_item("deku_nuts_counter"):add_amount(amount)
end