local item = ...

-- Gold Skulltula for Quest Status Screen

function item:on_created()
  self:set_savegame_variable("current_number_of_skulltulas")
  self:set_amount_savegame_variable("amount_of_skulltulas")
  self:set_sound_when_brandished("common/big_item")
  self:set_max_amount(100)
end

function item:on_obtaining()
  self:add_amount(1)
end