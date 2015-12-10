local game = ...

-- This script handles global properties of a particular savegame.

-- Include the various game features.
sol.main.load_file("scripts/menus/pause")(game)
sol.main.load_file("scripts/menus/game_over")(game)
sol.main.load_file("scripts/menus/dialog_box")(game)
sol.main.load_file("scripts/hud/hud")(game)
sol.main.load_file("scripts/dungeons")(game)
sol.main.load_file("scripts/equipment")(game)
sol.main.load_file("scripts/particle_emitter")(game)
local camera_manager = require("scripts/camera_manager")
local condition_manager = require("scripts/hero_condition")

function game:on_started()
  -- Set up the dialog box, HUD, hero conditions and effects.
  condition_manager:initialize(self)
  self:initialize_dialog_box()
  self:initialize_hud()
  camera = camera_manager:create(game)
end

function game:on_finished()
  if show_bars == true and not starting_cutscene then game:hide_bars() end
  sol.audio.set_music_volume(game:get_value("old_volume"))
  
  self:quit_hud()
  self:quit_dialog_box()
  camera = nil

  self:set_ability("tunic", game:get_value("item_saved_tunic"))
  self:set_ability("sword", game:get_value("item_saved_sword"))
  self:set_ability("shield", game:get_value("item_saved_shield"))

  self:set_command_keyboard_binding("action", self:get_value("item_saved_kb_action"))
  self:set_command_keyboard_binding("item_1", self:get_value("item_1_kb_slot"))
  self:set_command_keyboard_binding("item_2", self:get_value("item_2_kb_slot"))

  self:set_command_joypad_binding("action", self:get_value("item_saved_jp_action"))
  self:set_command_joypad_binding("item_1", self:get_value("item_1_jp_slot"))
  self:set_command_joypad_binding("item_2", self:get_value("item_2_jp_slot"))
  
end

-- This event need to be call when you start a cutscene
function game:stop_all_items()
local slot1 = self:get_value("_item_slot_1")
local slot2 = self:get_value("_item_slot_2")
-- if an item is active, call transit_to_finish() and reset it's value
	if self:get_value("item_"..slot1.."_state") > 0 then 
	self:get_item(slot1):transit_to_finish()
	self:set_value("item_"..slot1.."_state", 0)
	else if self:get_value("item_"..slot2.."_state") > 0 then
	self:get_item(slot2):transit_to_finish()
	self:set_value("item_"..slot2.."_state", 0)
	end
	end
end

function game:show_bars()
show_bars = true
end

function game:hide_bars()
bars_dispose = true
end

function game:start_cutscene()
starting_cutscene = true
end

function game:stop_cutscene()
starting_cutscene = false
end

-- This event is called when a new map has just become active.
function game:on_map_changed(map)
  -- Notify the hud.
  self:hud_on_map_changed(map)
end

function game:on_paused()
  self:hud_on_paused()
  self:start_pause_menu()
end

function game:on_unpaused()
  self:stop_pause_menu()
  self:hud_on_unpaused()
end

function game:get_player_name()
  return self:get_value("player_name")
end

function game:set_player_name(player_name)
  self:set_value("player_name", player_name)
end

-- Returns whether the current map is in the inside world.
function game:is_in_inside_world()
  return self:get_map():get_world() == "inside_world"
end

-- Returns whether the current map is in the outside world.
function game:is_in_outside_world()
  return self:get_map():get_world() == "outside_world" or self:get_map():get_world() == "outside_north"
end

-- Returns whether the current map is in a dungeon.
function game:is_in_dungeon()
  return self:get_dungeon() ~= nil
end

-- Returns/sets the current time of day
function game:get_time_of_day()
  if game:get_value("time_of_day") == nil then game:set_value("time_of_day", "day") end
  return game:get_value("time_of_day")
end

function game:set_time_of_day(tod)
  if tod == "day" or tod == "night" then
    game:set_value("time_of_day", tod)
  end
  return true
end

function game:switch_time_of_day()
  if game:get_value("time_of_day") == "day" then
    game:set_value("time_of_day", "night")
  else
    game:set_value("time_of_day", "day")
  end
  return true
end
-- Run the game.
sol.main.game = game
game:start()