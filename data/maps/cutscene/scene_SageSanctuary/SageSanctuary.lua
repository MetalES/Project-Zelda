local map = ...
local game = map:get_game()
local cutscene = require("scripts/gameplay/cutscene_manager")
 -- 152 72


function map:on_opening_transition_finished(destination)
  cutscene:load_cutscene_data("SageSanctuary", self)
end