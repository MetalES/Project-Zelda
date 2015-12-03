local item = ...
local game = item:get_game()

local item_name = "bow"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true

local volume_bgm = sol.audio.get_music_volume()

-- TODO : -Elemental Arrows (Fire, Ice, Light is already made, wrightmat's default code include it)
--        -Direction Fix
--        -disable hero heatures while using the item (pushing, pulling, etc)
--        -initialisation of the bow mechanism

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_amount_savegame_variable("item"..item_name.."_current_amount")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value(item_name.."_state", 0)
end

function item:on_obtained()
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_started()
  game:set_value(item_name.."_state", 0)
end

function item:on_map_changed()
local tunic = game:get_ability("tunic")
local tunic_ref = game:get_value("item_saved_tunic") or tunic

if game:get_hero():get_tunic_sprite_id() ~= "hero/tunic"..tunic_ref then game:get_hero():set_tunic_sprite_id("hero/tunic" ..tunic_ref) end
self:set_finished()
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    local sword = game:get_ability("sword")
    local shield = game:get_ability("shield")
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

    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
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
local tunic = game:get_ability("tunic")

-- read the 2 item slot.
  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end

--logical functions
local function recheck()
sol.timer.start(75, function() -- 100
game:set_value(item_name.."_state", 1)
game:set_value(item_name.."_can_shoot", false)
hero:unfreeze()
hero:set_walking_speed(40)
hero:set_tunic_sprite_id("hero/item/bow/bow_moving_free_tunic"..tunic)	
end)
end

local function transit_to_finish()
sol.audio.play_sound("common/item_show")
hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
    sol.timer.start(100, function()
    hero:set_walking_speed(88)
	hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))

	if bow_sync ~= nil then bow_sync:stop(); bow_sync = nil end
	if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil end

	hero:unfreeze()
	game:set_value(item_name.."_state", 0)
	self:set_finished()
    end)
item:set_finished()
end

-- item

if game:get_value(item_name.."_state") == 0 then 
	store_equipment()
	sol.audio.play_sound("common/bars_dungeon")
	sol.audio.play_sound("common/item_show")
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
      sol.timer.start(100, function()
	    hero:set_walking_speed(40)
		hero:unfreeze()
		print("item_state"..game:get_value(item_name.."_state"))
		game:set_value(item_name.."_state", 1)
		print("item_state"..game:get_value(item_name.."_state"))
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
 
		if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); bow_timer:stop(); bow_timer = nil; self:set_finished() end
		if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); self:set_finished() end
		if hero:get_state() == "falling" or hero:get_state() == "stairs" then hero:set_tunic_sprite_id("hero/tunic"..tunic); self:set_finished() end

		if game:is_command_pressed("attack") and game:get_value("is_cutscene") ~= true then
		hero:freeze()
		game:set_custom_command_effect("attack", nil)
		if bow_sync ~= nil then bow_sync:stop(); bow_sync = nil; transit_to_finish() end
		end
		return true
		end)
	  end)
	  
  elseif game:get_value(item_name.."_state") == 1 then
if game:is_command_pressed(slot) and game:get_value("is_cutscene") ~= true then
  if item:get_amount() == 0 then
	hero:set_tunic_sprite_id("hero/item/bow/bow_arming_no_arrow_tunic"..tunic)
		  sol.timer.start(50, function()
    	    sol.audio.play_sound("/items/bow/arming")
		    hero:set_tunic_sprite_id("hero/item/bow/bow_moving_no_arrow_tunic"..tunic)
		    hero:unfreeze()
		    game:set_value(item_name.."_can_shoot", true)
		    hero:set_walking_speed(28)
		  end)
   else
   	hero:set_tunic_sprite_id("hero/item/bow/bow_arming_arrow_tunic1")
	  sol.timer.start(50, function()
		sol.audio.play_sound("/items/bow/arming")
		hero:set_tunic_sprite_id("hero/item/bow/bow_moving_with_arrow_tunic"..tunic)
		hero:unfreeze()
		game:set_value(item_name.."_can_shoot", true)
		hero:set_walking_speed(28)
	  end)
    end
	
bow_timer = sol.timer.start(10, function()
if not game:is_command_pressed(slot) and game:get_value(item_name.."_can_shoot") == true and game:get_value("is_cutscene") ~= true then
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
		if item:get_amount() > 0 then
			shoot_arrow()
			hero:freeze()
			if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil; recheck() end
		else
			hero:freeze()
			sol.audio.play_sound("/items/bow/no_arrows_shoot")
			if bow_timer ~= nil then bow_timer:stop(); bow_timer = nil; recheck() end
		end
end
return true 
end)
end
end --if item_state
 
 function shoot_arrow()
      sol.audio.play_sound("/items/bow/shoot")
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

local hero = game:get_hero()
local tunic = game:get_ability("tunic")
local shield = game:get_ability("shield")
local sword = game:get_ability("sword")

local tunic_ref = game:get_value("item_saved_tunic") or tunic
local shield_ref = game:get_value("item_saved_shield") or shield
local sword_ref = game:get_value("item_saved_sword") or sword

hero:set_walking_speed(88)
game:set_ability("tunic", tunic_ref)
game:set_ability("sword", sword_ref)
game:set_ability("shield", shield_ref)

game:set_pause_allowed(true)

game:set_custom_command_effect("attack", nil)

game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))

game:set_value(item_name.."_state", 0)
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