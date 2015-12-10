local item = ...

function item:on_created()
  self:set_savegame_variable("i1820")
end

function item:on_variant_changed(variant)
  -- The possession state of the shield determines the built-in ability "shield".
  self:get_game():set_ability("shield", variant)
  self:get_game():set_value("item_saved_shield", variant)
  self:get_game():get_hero():set_shield_sprite_id("hero/shield"..variant)
end