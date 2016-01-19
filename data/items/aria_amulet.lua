local item = ...

function item:on_created()
 self:set_savegame_variable("item_aria_amulet_possession")
 self:set_sound_when_brandished("common/big_item")
end