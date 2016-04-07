local game = ...

-- This script handles global properties of a particular savegame.

-- Include the various game features.
sol.main.load_file("scripts/menus/pause")(game)
sol.main.load_file("scripts/menus/game_over")(game)
sol.main.load_file("scripts/menus/dialog_box")(game)
sol.main.load_file("scripts/hud/hud")(game)
sol.main.load_file("scripts/dungeons")(game)
sol.main.load_file("scripts/equipment")(game)
sol.main.load_file("scripts/gameplay/fog")(game)
sol.main.load_file("scripts/gameplay/time_system")(game)
sol.main.load_file("scripts/gameplay/cutscene_manager")(game)
sol.main.load_file("scripts/gameplay/screen/transition_manager")(game)
local camera_manager = require("scripts/camera_manager")
local condition_manager = require("scripts/hero_condition")

function game:on_started()
  -- Set up the dialog box, HUD, hero conditions and effects.
  self:set_ability("shield", (self:get_value("current_shield") or 0))
  self:get_hero():set_shield_sprite_id("hero/shield"..(self:get_value("current_shield") or 0))
  condition_manager:initialize(self)
  self:initialize_dialog_box()
  self:initialize_hud()
  camera = camera_manager:create(self)
end

function game:on_finished()
  -- Clean what was created by on_started().
  self:set_item_on_use(false)
  self:quit_hud()
  self:quit_dialog_box()
  sol.audio.set_music_volume(self:get_value("old_volume"))
  camera = nil
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

function game:fade_audio(targetsound, timetransit)
  sol.timer.start(sol.main, timetransit, function()
    if targetsound > sol.audio.get_music_volume() then
	  sol.audio.set_music_volume(sol.audio.get_music_volume() + 1)
	else
	  sol.audio.set_music_volume(sol.audio.get_music_volume() - 1)
	end
    if sol.audio.get_music_volume() == targetsound then
      return false
    end
  return true
  end)
end

-- This event need to be call when you start a cutscene or a dialog triggered by a sensor
-- It basically stop the current item and restore the hero to it's default animation.
function game:stop_all_items()
  for i = 1, 2 do
    local slot = self:get_value("_item_slot_" .. i )
    if self:get_value("item_"..slot.."_state") > 0 then 
	  self:get_item(slot):transit_to_finish()
	end
  end
end

function game:set_current_scene_cutscene(boolean)
  local boolean = boolean or false
  if boolean then
    self.is_cutscene = true
  else
    self.is_cutscene = false
  end
end

function game:is_current_scene_cutscene()
  return self.is_cutscene
end

-- The player is currently using an item, signal the engine.
function game:set_item_on_use(boolean)
  local boolean = boolean or false
  if boolean then
    self.using_an_item = true
  else
    self.using_an_item = false
  end
end

function game:is_using_item()
  return self.using_an_item
end

-- Blade Skills Management
function game:is_skill_learned(skill_index)
  return self:get_value("skill_" .. skill_index .. "_learned")
end

function game:set_skill_learned(skill_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("skill_" .. skill_index .. "_learned", learned)
end

function game:add_mail(name)
  local mail_bag = self:get_item("mail_bag")
  local value = mail_bag:get_amount() + 1
  
  self:set_value("mail_" .. value .. "_name", name)
  self:set_value("mail_" .. value .. "_obtained", true)
  self:set_value("mail_" .. value .. "_opened", false)
  self:set_value("mail_" .. value .. "_highlighted", false)
  self:set_value("total_mail", self:get_value("total_mail") or 0 + 1)
  mail_bag:add_amount(1)
  
  self:get_hero():start_treasure("mail")
end

function game:has_mail(value)
  return self:get_value("mail_" .. value .. "_obtained")
end

function game:get_mail_name(value)
  return self:get_value("mail_" .. value .. "_name")

end

-- This event is called when a new map has just become active.
function game:on_map_changed(map)
  -- Notify the hud.
  self:start_tone_system()
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


function game:enable_all_input()
self:set_command_keyboard_binding("up", self.keyboard_up) 
self:set_command_keyboard_binding("down", self.keyboard_down)  
self:set_command_keyboard_binding("left", self.keyboard_left)
self:set_command_keyboard_binding("right", self.keyboard_right) 
self:set_command_keyboard_binding("action", self.keyboard_action)
self:set_command_keyboard_binding("attack", self.keyboard_attack)
self:set_command_keyboard_binding("pause", self.keyboard_pause)

self:set_command_joypad_binding("up", self.joypad_up) 
self:set_command_joypad_binding("down", self.joypad_down)  
self:set_command_joypad_binding("left", self.joypad_left)   
self:set_command_joypad_binding("right", self.joypad_right) 
self:set_command_joypad_binding("action", self.joypad_action)
self:set_command_joypad_binding("attack", self.joypad_attack)
self:set_command_joypad_binding("pause", self.joypad_pause)

  if self.input_management_include_item then
    self:set_command_keyboard_binding("item_1", self.keyboard_item_1)
    self:set_command_keyboard_binding("item_2", self.keyboard_item_2)
	self:set_command_joypad_binding("item_1", self.joypad_item_1)
	self:set_command_joypad_binding("item_2", self.joypad_item_2)
  end
end

function game:disable_all_input(include_item)
  self.input_management_include_item = include_item
  
  self.keyboard_up = self:get_command_keyboard_binding("up") 
  self.keyboard_down = self:get_command_keyboard_binding("down") 
  self.keyboard_left = self:get_command_keyboard_binding("left")
  self.keyboard_right = self:get_command_keyboard_binding("right") 
  self.keyboard_action = self:get_command_keyboard_binding("action") 
  self.keyboard_attack = self:get_command_keyboard_binding("attack") 
  self.keyboard_item_1 = self:get_command_keyboard_binding("item_1") 
  self.keyboard_item_2 = self:get_command_keyboard_binding("item_2") 
  self.keyboard_pause = self:get_command_keyboard_binding("pause")  

  self.joypad_up = self:get_command_joypad_binding("up") 
  self.joypad_down = self:get_command_joypad_binding("down") 
  self.joypad_left = self:get_command_joypad_binding("left") 
  self.joypad_right = self:get_command_joypad_binding("right") 
  self.joypad_action = self:get_command_joypad_binding("action") 
  self.joypad_attack = self:get_command_joypad_binding("attack") 
  self.joypad_item_1 = self:get_command_joypad_binding("item_1") 
  self.joypad_item_2 = self:get_command_joypad_binding("item_2") 
  self.joypad_pause = self:get_command_joypad_binding("pause") 

  self:set_command_keyboard_binding("up", nil) 
  self:set_command_keyboard_binding("down", nil)  
  self:set_command_keyboard_binding("left", nil)  
  self:set_command_keyboard_binding("right", nil)  
  self:set_command_keyboard_binding("attack", nil)
  self:set_command_keyboard_binding("action", nil)
  self:set_command_keyboard_binding("pause", nil)

  self:set_command_joypad_binding("up", nil)  
  self:set_command_joypad_binding("down", nil)  
  self:set_command_joypad_binding("left", nil)  
  self:set_command_joypad_binding("right", nil) 
  self:set_command_joypad_binding("action", nil)
  self:set_command_joypad_binding("attack", nil)
  self:set_command_joypad_binding("pause", nil)

  if include_item then
    self:set_command_keyboard_binding("item_1", nil)
    self:set_command_keyboard_binding("item_2", nil)
	self:set_command_joypad_binding("item_1", nil)
    self:set_command_joypad_binding("item_2", nil)
  end

-- Make sure all input are released
self:simulate_command_released("attack")
self:simulate_command_released("action")
self:simulate_command_released("item_1")
self:simulate_command_released("item_2")
self:simulate_command_released("up")
self:simulate_command_released("down")
self:simulate_command_released("left")
self:simulate_command_released("right")
end

-- Run the game.
sol.main.game = game
game:start()