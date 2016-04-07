local map = ...
local game = map:get_game()
local e_timer
local timer
local minigame = require("scripts/gameplay/objects/minigame/point_based_minigame")

sol.menu.start(game, minigame)
local _,  height = map:get_size()

--boomerang:set_enabled(false)

function map:on_started(destination)
  game:display_fog("forest", 0, 0, 96)
  game:show_map_name("forest_temple")
  self:start_field_bgm()
end

function switch:on_activated()
  sol.audio.set_music_volume(sol.audio.get_music_volume() / 3)
  timer = sol.timer.start(game, 18000, function()
    sol.audio.set_music_volume(game:get_value("old_volume"))
    switch:set_activated(false)    
  end)
  timer:set_suspended_with_map(true)
  timer:display_timer(game)
end

function test:on_activated()
  map:get_entity("red_white"):intro()
end

function miniboss_finished:on_activated()
  game:fade_audio(0, 10)
  game:show_cutscene_bars(true)
  game:set_hud_enabled(false)
  game:set_clock_enabled(false)
  map:spawn_chest(boomerang, "/common/secret_discover_minor", false, true, "dungeon_forbidden_woods")
end

red_white.on_dead = function()
  e_timer = sol.timer.start(map, 1000, function()
    miniboss_finished:on_activated()
  end)
  e_timer:set_suspended_with_map(true)
end

function o:on_activated()
  game:get_item("ocarina"):start_learn_song(8, "harp")
end

function o_4:on_activated()
  game:set_explored_dungeon_room(1, 0, 5)
end

function o_5:on_activated()
  testmenu:set_point(100)
end

function camera:on_activated()
  print("(tkr")
end 