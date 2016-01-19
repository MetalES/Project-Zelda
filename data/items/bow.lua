local item = ...
local game = item:get_game()

-- code is going to be extended for Elemental arrows, WIP

local item_name = "bow"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"
local volume_bgm = game:get_value("old_volume")

local state = 0
local arrow_type = 0 --normal, 1 = fire, 2 = ice, 3 = light
local can_shoot = false
local avoid_return = false
local bow_sync
local bow_timer

-- TODO : -Elemental Arrows (Fire, Ice, Light is already made, wrightmat's default code include it)
--        -Direction Fix
--        -disable hero heatures while using the item (pushing, pulling, etc)

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_amount_savegame_variable("item_"..item_name.."_current_amount")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end

function item:on_obtained()
  if show_bars == true and game:get_value("starting_cutscene") ~= true then game:hide_bars() end
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_map_changed()
if state > 0 then 
-- freeze the hero reset it to frame 0 so it avoid the frame error
game:get_hero():freeze()
game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
game:set_ability("sword", game:get_value("item_saved_sword"))
game:get_hero():set_walking_speed(88)
if show_bars == true and game:get_value("starting_cutscene") ~= true then game:hide_bars() end
if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
game:set_custom_command_effect("attack", nil)
game:get_hero():unfreeze()
self:set_finished()
end
end

function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

if bow_sync ~= nil then bow_sync:stop(); bow_sync = nil end
if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil end
        
game:set_custom_command_effect("attack", nil)

hero:freeze()
hero:set_walking_speed(88)

sol.audio.play_sound("common/item_show")

hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))
game:set_ability("shield", game:get_value("item_saved_shield"))
hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))

if show_bars == true and game:get_value("starting_cutscene") ~= true then game:hide_bars() end

hero:set_animation("bow_shoot", function()
hero:unfreeze(); 
game:set_ability("sword", game:get_value("item_saved_sword"));
if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true); hero:unfreeze() end;
item:set_finished(); 
end)
end

function item:store_equipment()
    local kb_action_key = game:get_command_keyboard_binding("action")
	local kb_item_1_key = game:get_command_keyboard_binding("item_1")
	local kb_item_2_key = game:get_command_keyboard_binding("item_2")
	local jp_action_key = game:get_command_joypad_binding("action")
	local jp_item_1_key = game:get_command_joypad_binding("item_1")
	local jp_item_2_key = game:get_command_joypad_binding("item_2")
	
    game:set_ability("sword", 0)
    game:set_ability("shield", 0)
	
    game:set_command_keyboard_binding("action", nil)
	game:set_command_joypad_binding("action", nil)
	
	if game:get_value("_item_slot_1") ~= item_name then game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil) end
	if game:get_value("_item_slot_2") ~= item_name then game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil) end

    game:set_value("item_saved_kb_action", kb_action_key)
	game:set_value("item_1_kb_slot", kb_item_1_key)
	game:set_value("item_2_kb_slot", kb_item_2_key)
	game:set_value("item_saved_jp_action", jp_action_key)
	game:set_value("item_1_jp_slot", jp_item_1_key)
	game:set_value("item_2_jp_slot", jp_item_2_key)
	
    game:set_pause_allowed(false)
end

-- now, we have pressed it's input, tell the game what to do

function item:on_using()  
local map = game:get_map()
local hero = game:get_hero()
local tunic = game:get_value("item_saved_tunic")

if game:get_value("_item_slot_1") == item_name then slot = "item_1"
elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end
game:using_item()

--logical functions
local function recheck()
sol.timer.start(40, function()
hero:set_tunic_sprite_id("hero/item/bow/bow_moving_free_tunic"..tunic)
state = 1
can_shoot = false
avoid_return = false
hero:unfreeze()
hero:set_walking_speed(40)
end)
end

local function end_by_collision() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if show_bars == true and game:get_value("starting_cutscene") ~= true then game:hide_bars() end;  item:set_finished(); game:set_pause_allowed(true) end
local function end_by_pickable() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); item:set_finished(); game:set_pause_allowed(true) end

-- item

if state == 0 then 
	item:store_equipment()

	  if not show_bars then game:show_bars() end

	sol.audio.play_sound("common/bars_dungeon")
	sol.audio.play_sound("common/item_show")
	hero:set_animation("bow_shoot")
	sol.timer.start(40, function()
	hero:set_walking_speed(40)
	hero:unfreeze()
	state = 1
	hero:set_tunic_sprite_id("hero/item/bow/bow_moving_free_tunic"..tunic)
		
bow_sync = sol.timer.start(10, function()
	local lx, ly, layer = hero:get_position()
	game:set_custom_command_effect("attack", "return")
		
--systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
--Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
-- this is just a placeholder until the function will be back

	if hero:get_direction() == 0 then new_x = -1; new_y = 0 
	elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
	elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
	elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
	end
 
	if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
	if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
	if hero:get_state() == "falling" or hero:get_state() == "stairs" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
	if hero:get_state() == "treasure" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
	if hero:get_animation() == "swimming_stopped" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end

	if game:is_command_pressed("attack") and not avoid_return then
    	hero:freeze()
	    game:set_custom_command_effect("attack", nil)
	if bow_sync ~= nil then bow_sync:stop(); bow_sync = nil; item:transit_to_finish() end
	end
return true
end) --bow_sync
end) --sol.timer.start
      
	  
elseif state == 1 then

if game:is_command_pressed(slot) then
avoid_return = true
hero:set_tunic_sprite_id("hero/tunic"..tunic)
  if item:get_amount() == 0 then
	hero:set_animation("bow_arming_no_arrow")
	sol.timer.start(50, function()
    	    sol.audio.play_sound(sound_dir.."arming")
			hero:set_animation("stopped")
		    hero:set_tunic_sprite_id("hero/item/bow/bow_moving_no_arrow_tunic"..tunic)
		    hero:unfreeze()
		    can_shoot = true
			avoid_return = false
		    hero:set_walking_speed(28)
		  end)
   else
	hero:set_animation("bow_arming_arrow")
	  sol.timer.start(50, function()
		sol.audio.play_sound(sound_dir.."arming")
		hero:set_animation("stopped")
		hero:set_tunic_sprite_id("hero/item/bow/bow_moving_with_arrow_tunic"..tunic)
		hero:unfreeze()
		can_shoot = true
		avoid_return = false
		hero:set_walking_speed(28)
	  end)
    end
	
bow_timer = sol.timer.start(30, function() --10
if not game:is_command_pressed(slot) and can_shoot then
    avoid_return = true
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
		if item:get_amount() > 0 then
			shoot_arrow()
			hero:freeze()
			if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil; recheck() end
		else
			hero:freeze()
			sol.audio.play_sound(sound_dir.."no_arrows_shoot")
			if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil; recheck() end
		end
game:using_item()
end
return true 
end)
end
end --if item_state
 
 function shoot_arrow()
      sol.audio.play_sound(sound_dir.."shoot")
      self:remove_amount(1)
      local x, y = hero:get_center_position()
      local _, _, layer = hero:get_position()
	  local ax, ay
	  
	  if hero:get_direction() == 0 then ax = 0; ay = - 1
	  elseif hero:get_direction() == 1 then ax = - 3; ay = 0 
	  elseif hero:get_direction() == 2 then ax = 0; ay = - 1
	  else ax = 0; ay = 0 end
	  
      local arrow = map:create_custom_entity({
        x = x + ax,
        y = y + ay,
        layer = layer,
        direction = hero:get_direction(),
        model = "arrow",
      })
      arrow:set_force(self:get_force())
      arrow:set_sprite_id(self:get_arrow_sprite_id())
      arrow:go()	  
 end 
 
end --function

function item:set_finished()
if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil end
if bow_sync ~= nil then bow_sync:stop(); bow_sync = nil end

game:item_finished()
game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))

state = 0
can_shoot = false
avoid_return = false
end

-- things bellow are logical item function, untouched

function item:on_amount_changed(amount)
  if self:get_variant() ~= 0 then
    if amount == 0 then
      self:set_variant(1)
    else
      self:set_variant(2)
    end
  end
end

function item:on_obtaining(variant, savegame_variable)
  local arrow = game:get_item("arrow")
  local quiver = game:get_item("quiver")

  sol.audio.set_music_volume(0)

  if not quiver:has_variant() then
    -- Give the first quiver and some arrows with the bow.
    quiver:set_variant(1)
    self:add_amount(30)
    arrow:set_obtainable(true)
  else
    -- Set the max value of the bow counter.
    local max_amounts = {30, 60, 100}
    local max_amount = max_amounts[quiver:get_variant()]
    self:set_max_amount(max_amount)
  end
  if amount == 0 then self:set_variant(1) else self:set_variant(2) end
end

function item:get_force()
  return 2
end

function item:get_arrow_sprite_id()
  return "entities/arrow"
end

-- Initialize the metatable of appropriate entities to work with custom arrows.
local function initialize_meta()
  -- Add Lua arrow properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.set_attack_arrow ~= nil then
    -- Already done.
    return
  end

  enemy_meta.arrow_reaction = "force"
  enemy_meta.arrow_reaction_sprite = {}
  function enemy_meta:get_attack_arrow(sprite)
    if sprite ~= nil and self.arrow_reaction_sprite[sprite] ~= nil then
      return self.arrow_reaction_sprite[sprite]
    end

    if self.arrow_reaction == "force" then
      -- Replace by the current force value.
      local game = self:get_game()
 -- TODO : Elemental Arrows
      -- if game:has_item("bow_light") then
        -- return game:get_item("bow_light"):get_force()
      -- end
      return game:get_item("bow"):get_force()
    end

    return self.arrow_reaction
  end

  function enemy_meta:set_attack_arrow(reaction, sprite)
    self.arrow_reaction = reaction
  end

  function enemy_meta:set_attack_arrow_sprite(sprite, reaction)
    self.arrow_reaction_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also take into account arrows.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_attack_arrow("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_attack_arrow_sprite(sprite, "ignored")
  end
end

initialize_meta()