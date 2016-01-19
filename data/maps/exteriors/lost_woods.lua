local map = ...

function map:on_started(destination)
  --self:get_game():display_fog("forest", 0, 0, 96)
  self:get_game():show_map_name("inside_lost_woods")
  sol.audio.play_music("exteriors/lost_woods_intro", function()
   sol.audio.play_music("exteriors/lost_woods_loop")end)
end
