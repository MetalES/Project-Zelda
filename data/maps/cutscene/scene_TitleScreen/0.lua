local map = ...
local game = map:get_game()
local title_screen = require("scripts/menus/titlescreen")
local s = sol.surface.create(320, 240)
s:fill_color({0,0,0})

game:set_hud_enabled(false)
game:set_clock_enabled(false)

function map:on_started()
  game:display_fog("forest", 0, 0, 96)
  sol.menu.start(self, title_screen)
end

function map:on_draw(dst_surface)
  if game.building_file_select then
    s:draw(dst_surface, 0, 0)
  end
end