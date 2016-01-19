local item = ...

function item:on_created()
  self:set_savegame_variable("item_deku_nuts_bag_possession")
end

function item:on_started()
  self:on_variant_changed(self:get_variant())
end

function item:on_variant_changed(variant)
  local deku_counter = self:get_game():get_item("deku_nuts_counter")
  local deku = self:get_game():get_item("deku_nuts")
  if variant == 0 then
    deku_counter:set_max_amount(0)
    deku:set_obtainable(false)
  else
    local max_amounts = {10, 30, 50}
    local max_amount = max_amounts[variant]

    deku_counter:set_variant(1)
    deku_counter:set_max_amount(max_amount)

    deku:set_obtainable(true)
  end
end

function item:on_obtaining(variant, savegame_variable)
  if variant > 0 then
    local deku_counter = self:get_game():get_item("deku_nuts_counter")
    deku_counter:set_amount(deku_counter:get_max_amount())
  end
end