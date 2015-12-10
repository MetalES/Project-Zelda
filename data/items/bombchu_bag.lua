local item = ...

function item:on_created()
  self:set_savegame_variable("item_bombchu_bag_possession")
end

function item:on_started()
  self:on_variant_changed(self:get_variant())
end

function item:on_variant_changed(variant)
  -- The bomb bag determines the maximum amount of the bomb counter.
  local bombchu_counter = self:get_game():get_item("bombchu_counter")
  local bombchu = self:get_game():get_item("bombchu")
  if variant == 0 then
    bombchu_counter:set_max_amount(0)
    bombchu:set_obtainable(false)
  else
    local max_amounts = {10, 30, 50}
    local max_amount = max_amounts[variant]

    bombchu_counter:set_variant(1)
    bombchu_counter:set_max_amount(max_amount)
    bombchu:set_obtainable(true)
  end
end

function item:on_obtaining(variant, savegame_variable)
  if variant > 0 then
    local bombchu_counter = self:get_game():get_item("bombchu_counter")
    bombchu_counter:set_amount(bombchu_counter:get_max_amount())
  end
end