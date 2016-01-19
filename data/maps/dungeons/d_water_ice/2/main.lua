local map = ...

function map:on_started(destination)
self:get_game():show_map_name("forest_temple")
self:get_game():display_fog("forest_alt", 4, 7, 16)
end
