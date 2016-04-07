local map = ...
local game = map:get_game()
local water_delay = 500
local default_water_level = 3
local water_level = 0

--local overlay = sol.surface.create("hud/cutscene_bars.png")


-- Water function
function water_test:on_activated()
sol.audio.play_sound("/common/switch_crystal_hit")
end

function map:on_draw(destination_surface)
--overlay:draw(destination_surface)
end
