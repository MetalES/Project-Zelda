local map = ...
local game = map:get_game()

function map:on_started()
  game:display_fog("forest", 0, 0, 96)
end