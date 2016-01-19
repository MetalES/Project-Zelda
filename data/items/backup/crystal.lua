local item = ...

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(false)
  self:set_brandish_when_picked(false)
end

-- Obtaining Magic Crystal
function item:on_obtaining(variant, savegame_variable)
  local crystal_counter = self:get_game():get_item("crystal_counter")
  if crystal_counter:get_variant() == 0 then
    crystal_counter:set_variant(1)
  end
  crystal_counter:add_amount(1)
end
