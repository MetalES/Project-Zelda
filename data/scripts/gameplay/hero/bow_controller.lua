--[[
/script\Bow Controller Script.
/author\Made by MetalZelda - 21.02.2016

/desc\Controller script for the bow.
/instruction\This script overwrite the hero:start_bow(). See quest_manager.

/copyright\Credits if you plan to use the script would be nice. Not for resale. Script and project are part of educationnal project.
]]

local game = ...
local bow_controller = {}

local slot = "item_1"
local item = "bow"
local sound_dir = "/items/"..item.."/"
local tunic = game:get_value("item_saved_tunic")
local new_x, new_y, gx, gy
local is_halted_by_anything_else, avoid_return = false

-- Initialize game accessible functions
function game:start_bow_control()
  sol.menu.start(self:get_map(), bow_controller)
end

function game:stop_bow()
  sol.menu.stop(bow_controller)
end

local function set_state(int)
  game:set_value("item_"..item.."_state", int)
end

local function get_state()
  return game:get_value("item_"..item.."_state")
end

function bow_controller:on_started()
  if game:get_value("_item_slot_2") == item then slot = "item_2" end 
  game:get_item(item):store_equipment()
  game:set_item_on_use(true)
  game:show_cutscene_bars(true)
  sol.audio.play_sound("common/bars_dungeon")
  sol.audio.play_sound("common/item_show")
  game:get_hero():set_animation("bow_shoot", function()
    game:get_hero():set_walking_speed(40)
    game:get_hero():unfreeze()
	game:get_hero():set_tunic_sprite_id(game:get_item(item).BowFreeState)
	game:set_custom_command_effect("attack", "return") 
	if game:get_value("item_bow_max_arrow_type") > 0 then
	  game:set_custom_command_effect("action", "change")
	end
  end)
  self:start_ground_check() 
end

function bow_controller:start_ground_check()

  local function end_by_collision() is_halted_by_anything_else = true; game:stop_bow() end
  local function end_by_pickable() is_halted_by_anything_else = true; game:stop_bow() end

  sol.timer.start(self, 50, function()
	local lx, ly, layer = game:get_hero():get_position()
	-- systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
	-- Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
	-- this is just a placeholder until the function will be back
	if game:get_hero():get_direction() == 0 then new_x = -1; new_y = 0; gx = 1; gy = 0
	elseif game:get_hero():get_direction() == 1 then new_x = 0; new_y = 1 ; gy = -1;  gx = 0
	elseif game:get_hero():get_direction() == 2 then new_x = 1; new_y = 0 ; gy = 0;  gx = -1
	elseif game:get_hero():get_direction() == 3 then new_x = 0; new_y = -1; gy = 1;  gx = 0
	end
	  
	if game:get_map():get_ground(lx + gx, ly + gy, layer) == "lava" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic) end_by_collision() end
    if game:get_hero():get_state() == "hurt" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
	if game:get_hero():get_state() == "swimming" or game:get_hero():get_state() == "jumping" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic); game:get_hero():set_position(lx + new_x, ly + new_y); end_by_collision() end
	if game:get_hero():get_state() == "falling" or game:get_hero():get_state() == "stairs" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
	if game:get_hero():get_state() == "treasure" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
	if game:get_hero():get_animation() == "swimming_stopped" then game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end

  return true
  end)
end

function bow_controller:on_command_pressed(command)
  local hero = game:get_hero()

  if command == slot and not game.is_building_new_arrow then
    avoid_return = true
	sol.audio.play_sound(sound_dir.."arming")
	sol.timer.start(50, function()
	  set_state(2)
	  game:get_hero():set_animation("stopped")
	  game:get_hero():set_tunic_sprite_id(game:get_item(item).BowStateArmed)
	  game:get_hero():unfreeze()
	  avoid_return = false
	  game:get_hero():set_walking_speed(28)
	end)
  end
  
  if command == "attack" and not avoid_return then
    game:stop_bow()
	game:get_hero():freeze()
	game:set_custom_command_effect("attack", nil)
    game:get_item(item):transit_to_finish()
	handled = true
  end
end

function bow_controller:on_key_pressed(key)
  if key == (game:get_value("item_saved_kb_action") or game:get_value("item_saved_jp_action")) and not game.is_building_new_arrow then
    game.next_arrow = true
	game.is_building_new_arrow = true
	avoid_return = false
	game:simulate_command_released(slot)
	game:get_hero():unfreeze()
	sol.timer.start(50, function()
	  game:get_hero():set_tunic_sprite_id(game:get_item(item).BowFreeState)
	  game:get_hero():set_animation("stopped")
	  set_state(1)
	end)
  end
end

function bow_controller:on_command_released(command)
  if command == slot and get_state() == 2 then
	avoid_return = true
	game:get_hero():set_tunic_sprite_id(game:get_item(item).BowShoot)
	  if game:get_item(item):get_amount() > 0 then       
		game:get_hero():shoot_bullet("arrow", "arrow", 256, 200, false, false)
		sol.audio.play_sound(sound_dir.."shoot")
		game:get_item(item):remove_amount(1)
	  else
	    sol.audio.play_sound(sound_dir.."no_arrows_shoot")
	  end
	game:get_hero():freeze()
	set_state(1)
	sol.timer.start(self, 60, function()
      game:get_hero():set_tunic_sprite_id(game:get_item(item).BowFreeState)
	  avoid_return = false
	  game:get_hero():unfreeze()
	  game:get_hero():set_walking_speed(40)
  end)
  end
end

function bow_controller:on_finished()  
  local function restore_player_abilities() game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")) end
  if not game:is_current_scene_cutscene() then game:show_cutscene_bars(false) end
  
  game:get_hero():set_walking_speed(88)
  game:set_custom_command_effect("attack", nil)
  game:set_custom_command_effect("action", nil)
  game:set_item_on_use(false)
  game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
  game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
  game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))
  game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
  game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
  game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
  set_state(0)
  avoid_return = false
  
  if not is_halted_by_anything_else then
	sol.audio.play_sound("common/item_show") 
	game:get_hero():freeze()
	game:get_hero():set_tunic_sprite_id(game:get_item(item).BowShoot)
	sol.timer.start(120, function()
	  restore_player_abilities()
	  game:get_hero():set_tunic_sprite_id("hero/tunic"..tunic)
	  game:get_hero():unfreeze()
	  if not game:is_current_scene_cutscene() then game:set_pause_allowed(true) game:get_hero():unfreeze() end
	  game:get_item(item):set_finished()
	end)
  else
    is_halted_by_anything_else = false
	restore_player_abilities()
    game:get_item(item):set_finished()
  end   
  
  sol.timer.stop_all(self)
end