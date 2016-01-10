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
sol.main.load_file("scripts/menus/credits")(game)
sol.main.load_file("entities/object/shop/shop_manager")(game)
local camera_manager = require("scripts/camera_manager")
local condition_manager = require("scripts/hero_condition")

function game:on_started()
  -- Set up the dialog box, HUD, hero conditions and effects.
  condition_manager:initialize(self)
  self:initialize_dialog_box()
  self:initialize_hud()
  camera = camera_manager:create(game)
  if show_bars == true and self:get_value("starting_cutscene") ~= true then game:hide_bars() end
end

function game:on_finished()
  sol.audio.set_music_volume(self:get_value("old_volume"))
  if show_bars == true and self:get_value("starting_cutscene") ~= true then game:hide_bars() end
  self:set_value("starting_cutscene", false)

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
self:set_value("starting_cutscene", true) --todo on entity & game_over
end

function game:stop_cutscene()
self:set_value("starting_cutscene", false)
end

function game:is_skill_learned(skill_index)
  return self:get_value("skill_" .. skill_index .. "_learned")
end

function game:set_skill_learned(skill_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("skill_" .. skill_index .. "_learned", learned)
end

function game:is_ocarina_song_learned(song_index)
  return self:get_value("song_" .. song_index .. "_learned")
end

function game:set_ocarina_song_learned(song_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("song_" .. song_index .. "_learned", learned)
end

function game:set_hour(hour, minute, day)
--if none have been declared then set to 0
  if hour == nil then
    hour = 0
  elseif minute == nil then 
    minute = 0
  elseif day == nil then 
    day = self:get_value("current_day")
  end
  self:set_value("current_hour", hour)
  self:set_value("current_minute", minute)
  self:set_value("current_day", day)
end

function game:using_item(value)
self:set_value("using_item", true) -- todo on item
end

function game:item_finished()
self:set_value("using_item", false)
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

function game:enable_all_input()
game:set_command_keyboard_binding("up", game:get_value("kb_up")) 
game:set_command_keyboard_binding("down", game:get_value("kb_down"))  
game:set_command_keyboard_binding("left", game:get_value("kb_left"))
game:set_command_keyboard_binding("right", game:get_value("kb_right")) 
game:set_command_keyboard_binding("action", game:get_value("kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))
game:set_command_keyboard_binding("attack", game:get_value("kb_attack"))
game:set_command_keyboard_binding("pause", game:get_value("kb_pause"))

game:set_command_joypad_binding("up", game:get_value("jp_up")) 
game:set_command_joypad_binding("down", game:get_value("jp_down"))  
game:set_command_joypad_binding("left", game:get_value("jp_left"))   
game:set_command_joypad_binding("right", game:get_value("jp_right")) 
game:set_command_joypad_binding("action", game:get_value("jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
game:set_command_joypad_binding("attack", game:get_value("jp_attack"))
game:set_command_joypad_binding("pause", game:get_value("jp_pause"))
end

function game:disable_all_input()
local kb_up = game:get_command_keyboard_binding("up") 
local kb_down = game:get_command_keyboard_binding("down") 
local kb_left = game:get_command_keyboard_binding("left") 
local kb_right = game:get_command_keyboard_binding("right") 
local kb_attack = game:get_command_keyboard_binding("attack") 
local kb_action = game:get_command_keyboard_binding("action") 
local kb_pause = game:get_command_keyboard_binding("pause") 
local jp_up = game:get_command_joypad_binding("up") 
local jp_down = game:get_command_joypad_binding("down") 
local jp_left = game:get_command_joypad_binding("left") 
local jp_right = game:get_command_joypad_binding("right") 
local jp_attack = game:get_command_joypad_binding("attack") 
local jp_action = game:get_command_joypad_binding("action") 
local jp_pause = game:get_command_joypad_binding("pause") 

game:set_value("kb_up", kb_up)
game:set_value("kb_down", kb_down)
game:set_value("kb_left", kb_left)
game:set_value("kb_right", kb_right)
game:set_value("kb_attack", kb_attack)
game:set_value("kb_action", kb_action)
game:set_value("kb_pause", kb_pause)

game:set_value("jp_up", jp_up)
game:set_value("jp_down", jp_down)
game:set_value("jp_left", jp_left)
game:set_value("jp_right", jp_right)
game:set_value("jp_attack", jp_attack)
game:set_value("jp_action", jp_action)
game:set_value("jp_pause", jp_pause)

game:set_command_keyboard_binding("up", nil) 
game:set_command_keyboard_binding("down", nil)  
game:set_command_keyboard_binding("left", nil)  
game:set_command_keyboard_binding("right", nil)  
game:set_command_keyboard_binding("item_1", nil)
game:set_command_keyboard_binding("item_2", nil)
game:set_command_keyboard_binding("attack", nil)
game:set_command_keyboard_binding("action", nil)
game:set_command_keyboard_binding("pause", nil)

game:set_command_joypad_binding("up", nil)  
game:set_command_joypad_binding("down", nil)  
game:set_command_joypad_binding("left", nil)  
game:set_command_joypad_binding("right", nil) 
game:set_command_joypad_binding("item_1", nil)
game:set_command_joypad_binding("item_2", nil)
game:set_command_joypad_binding("action", nil)
game:set_command_joypad_binding("attack", nil)
game:set_command_joypad_binding("pause", nil)

-- Make sure all input are released
game:simulate_command_released("attack")
game:simulate_command_released("action")
game:simulate_command_released("item_1")
game:simulate_command_released("item_2")
game:simulate_command_released("up")
game:simulate_command_released("down")
game:simulate_command_released("left")
game:simulate_command_released("right")
end
-- Run the game.
sol.main.game = game
game:start()