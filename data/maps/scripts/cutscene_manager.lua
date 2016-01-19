local game = ...
local cutscene_pointer = game:get_value("cutscene_pointer") or nil -- no cutscene to play in the current map or not found
--Define all of minor in-game cutscene here, WIP
function game:cutscene_on_started()
self:set_value("starting_cutscene", true)
self:stop_all_items()
if not show_bars then self:show_bars() end
end

function game:start_cutscene(cutscene_pointer)
self:cutscene_on_started()
end