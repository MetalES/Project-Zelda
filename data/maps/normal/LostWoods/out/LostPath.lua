local map = ...
local game = map:get_game()

local function is_playing_music()
  return sol.audio.get_music() ~= nil
end

local function play_music()
  if not is_playing_music() then
    game:show_map_name("inside_lost_woods")
    sol.audio.play_music("exterior_lost_woods_intro", function()
      sol.audio.play_music("exterior_lost_woods_loop")
    end)
  end
end

function map:on_started()
  game:display_fog("forest", 0, 0, 96)
  --play_music()
end

function map:on_opening_transition_finished(destination)
  if destination == from_ocarina then
    game:get_item("ocarina"):warp_in()
    play_music()
  end
end