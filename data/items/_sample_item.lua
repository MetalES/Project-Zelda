local item = ...
local game = item:get_game()
-- item configuration
local item_name = "fire_rod"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

-- Sample item code : Fire Rod (example)

--[[ 
Use this code if you need to rework or make any item.
On_using only freeze the hero as stated by the api, but you can unfreeze him and extend the code (giving more gameplay features).

item_manager is now obsolete, all items can be made within it's file without depending on /scripts/item/item_manager.

rename item_name's value by the name of the file(without .lua)
the input thing is stored in the slot variable listed above

How it works technically :
  - when the item starts, all variable are stored in a separated savestate value (local function store_equipment()).
  - item_x (the opposite slot of the current item) is temporary disabled to avoid any confusion.
  - a looping timed function check if the input is released during the starting animation, during this phase, on_using hero:freeze() is currently running (rod)
  - savegame values in store_equipment are for reputting values for set_command_controller_binding, else they will be nil, even if savex.dat has their value and option menu in pause menu is corrupted.

What you need :
  - in the game savegame file creation, set values to :
      - "item_saved_tunic" 1 
	  - "item_saved_sword" 0
	  - "item_saved_shield" 0
      - inputs (stored in store_equipment)
  - in /scripts/menus/pause_option, add a condition that dynamically change value for store_equipment() savegame values
  - in /scripts/menus/savegames, initialize default values of store_equipment
	  
Support Joypad
--]]

function item:on_created()
  self:set_savegame_variable(item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end

function item:on_map_changed()
local tunic = game:get_ability("tunic")
local tunic_ref = game:get_value("item_saved_tunic") or tunic
if fire_rod ~= nil then fire_rod:remove() end
if fire_rod_process ~= nil then fire_rod_process:stop(); fire_rod_process = nil end 
if rod_sync ~= nil then rod_sync:stop() end
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
    game:set_value("item_saved_action", kb_action_key)
	game:set_value("item_1_kb_slot", kb_item_1_key)
	game:set_value("item_2_kb_slot", kb_item_2_key)
	game:set_value("item_saved_jp_action", jp_action_key)
	game:set_value("item_1_jp_slot", jp_item_1_key)
	game:set_value("item_2_jp_slot", jp_item_2_key)
	
    game:set_pause_allowed(false)
	
end

function item:on_using()
local map = game:get_map()
local hero = game:get_hero()

local new_x = 0 -- temp value (issue 7)
local new_y = 0 -- temp value (issue 7)

local x, y, layer = hero:get_position()
local direction = hero:get_direction()

local tunic = game:get_ability("tunic")

-- read the 2 item slot.
  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end

  hero:set_animation("rod")

  local fire_rod = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/fire_rod/rod",
  })

-- pre-check function, if the player release the key, abandon.
check = sol.timer.start(10, function()
if game:is_command_pressed(slot) ~= true and game:get_value("is_cutscene") ~= true then
fire_rod:remove()
if fire_rod_process ~= nil then hero:set_tunic_sprite_id("hero/tunic"..tunic); fire_rod_process:stop(); fire_rod_process = nil end 
if rod_sync ~= nil then rod_sync:stop() end
self:set_finished()
end
return true
end)


fire_rod_process = sol.timer.start(300,function()
store_equipment()
fire_rod:remove()
check:stop()
hero:unfreeze()

hero:set_tunic_sprite_id("hero/item/fire_rod/rod_moving_tunic_"..tunic)
hero:set_walking_speed(55)

  local fire_rod_move = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/fire_rod/rod_moving",
  })
  

rod_sync = sol.timer.start(10, function()
local lx, ly, layer = hero:get_position()
--systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
--Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
-- this is just a placeholder until the function will be back

if hero:get_direction() == 0 then new_x = -1; new_y = 0 
elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
end

fire_rod_move:set_position(hero:get_position()) 
fire_rod_move:set_direction(hero:get_direction())
 
if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); rod_sync:stop(); fire_rod_move:remove(); fire_timer:stop(); magic_timer:stop(); self:set_finished() end
if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); rod_sync:stop(); fire_rod_move:remove(); fire_timer:stop(); magic_timer:stop(); self:set_finished() end
if hero:get_state() == "falling" or hero:get_state() == "stairs" then 
  self:set_finished()  
  rod_sync:stop()
  fire_rod_move:remove()
  fire_timer:stop()
  magic_timer:stop()
end
return true
end)
  
magic_timer = sol.timer.start(200, function()
if fire_timer ~= nil then
self:get_game():remove_magic(1)
end
return true
end)

fire_timer = sol.timer.start(100, function()
if game:is_command_pressed(slot) and game:get_value("is_cutscene") ~= true then
  if self:get_game():get_magic() > 0 then self:shoot_fire() end
else
  hero:set_walking_speed(88)
  hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
  
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("sword", game:get_value("item_saved_sword"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  
game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))


  game:set_pause_allowed(true)
  hero:unfreeze()
  rod_sync:stop()
  fire_rod_move:remove()
  fire_timer:stop()
  magic_timer:stop()
  self:set_finished()
  
end
return true
end)

end)
  if fire_timer ~= nil then fire_timer:stop() end
  if magic_timer ~= nil then magic_timer:stop() end
end


-- Creates some fire on the map.
function item:shoot_fire()
  local hero = self:get_game():get_hero()
  local direction = hero:get_direction()
  local dx, dy
  if direction == 0 then
    dx, dy = 14, -16
  elseif direction == 1 then
    dx, dy = -8, -35
  elseif direction == 2 then
    dx, dy = -20, -16
  else
    dx, dy = 2, -4
  end

  local x, y, layer = hero:get_position()
  local fire = self:get_game():get_map():create_custom_entity({
    model = "fire",
    x = x + dx,
    y = y + dy,
    layer = layer,
    direction = direction,
  })
  
 sol.audio.play_sound(sound_dir.."shoot")

local fire_mvt = sol.movement.create("straight")
fire_mvt:set_angle(hero:get_direction() * math.pi / 2)
fire_mvt:set_speed(200)
fire_mvt:set_max_distance(32)
fire_mvt:set_smooth(false)
fire_mvt:start(fire)
end


function item:set_finished()
if fire_timer ~= nil then fire_timer:stop() end
if magic_timer ~= nil then magic_timer:stop() end
if check ~= nil then check:stop() end
if rod_sync ~= nil then rod_sync:stop() end
if fire_rod_move ~= nil then fire_rod_move:remove() end

local hero = game:get_hero()
local tunic = game:get_ability("tunic")
local shield = game:get_ability("shield")
local sword = game:get_ability("sword")
-- if values doesn't exist, just grab the value in local above.
local tunic_ref = game:get_value("item_saved_tunic") or tunic
local shield_ref = game:get_value("item_saved_shield") or shield
local sword_ref = game:get_value("item_saved_sword") or sword

hero:unfreeze()
hero:set_walking_speed(88)
if hero:get_tunic_sprite_id() ~= "hero/tunic"..tunic_ref then hero:set_tunic_sprite_id("hero/tunic" ..tunic_ref) end

game:set_ability("tunic", tunic_ref)
game:set_ability("sword", sword_ref)
game:set_ability("shield", shield_ref)

game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))

game:set_pause_allowed(true)
end


-- Initialize the metatable of appropriate entities to work with the fire.
local function initialize_meta()

  -- Add Lua fire properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_fire_reaction ~= nil then
    -- Already done.
    return
  end

  enemy_meta.fire_reaction = 3  -- 3 life points by default.
  enemy_meta.fire_reaction_sprite = {}
  function enemy_meta:get_fire_reaction(sprite)

    if sprite ~= nil and self.fire_reaction_sprite[sprite] ~= nil then
      return self.fire_reaction_sprite[sprite]
    end
    return self.fire_reaction
  end

  function enemy_meta:set_fire_reaction(reaction, sprite)

    self.fire_reaction = reaction
  end

  function enemy_meta:set_fire_reaction_sprite(sprite, reaction)

    self.fire_reaction_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also
  -- take into account the fire.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_fire_reaction("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_fire_reaction_sprite(sprite, "ignored")
  end

end
initialize_meta()