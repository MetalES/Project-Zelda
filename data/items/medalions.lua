local item = ...

function item:on_created()
self:set_savegame_variable("medalion")
end

function item:on_variant_changed(variant)
self:get_game():set_value("medalion_"..variant.."_obtained", true)
end