local map = ...

function map:on_started(destination)
if destination == from_outside then
self:get_game():show_map_name("water_temple")
end
self:get_game():display_fog("forest_alt", 4, 7, 16)
end
