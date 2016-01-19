local item = ...
local game = item:get_game()

local item_name = "fire_rod"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"
local volume_bgm = game:get_value("old_volume")

local state = 0
local fire_rod
local fire_rod_check
local fire_timer
local fire_rod_timer
local fire_rod_sync
local fire_rod_process

-- Fire Rod

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
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
game:get_hero():freeze()
game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
game:set_ability("sword", game:get_value("item_saved_sword"))
game:get_hero():set_walking_speed(88)
if show_bars == true and game:get_value("starting_cutscene") ~= true then game:hide_bars() end
if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
game:get_hero():unfreeze()
self:set_finished()
end
end

function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

if fire_timer ~= nil then fire_timer:stop() end
if fire_rod_timer ~= nil then fire_rod_timer:stop() end
if fire_rod_check ~= nil then fire_rod_check:stop() end
if fire_rod_sync ~= nil then fire_rod_sync:stop() end
if fire_rod ~= nil then fire_rod:remove() end
        
game:set_custom_command_effect("attack", nil)
game:item_finished()

hero:freeze()
hero:set_walking_speed(88)

sol.audio.play_sound("common/item_show")
hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))
game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_ability("sword", game:get_value("item_saved_sword"))
hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true); hero:unfreeze() end
self:set_finished()
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

function item:on_using()
local map = game:get_map()
local hero = game:get_hero()
local new_x = 0 -- temp value (issue 7)
local new_y = 0 -- temp value (issue 7)
local x, y, layer = hero:get_position()
local direction = hero:get_direction()
local tunic = game:get_value("item_saved_tunic")

local function end_by_collision() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if fire_timer ~= nil then fire_timer:stop() end if fire_rod_timer ~= nil then fire_rod_timer:stop(); item:set_finished() end if fire_rod_check ~= nil then fire_rod_check:stop(); item:set_finished() end if fire_rod_sync ~= nil then fire_rod_sync:stop(); item:set_finished() end if fire_rod ~= nil then fire_rod:remove(); item:set_finished() end item:set_finished(); game:set_pause_allowed(true) end
local function end_by_pickable() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); item:set_finished(); game:set_pause_allowed(true) end

  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end
  game:using_item()
  
  hero:set_animation("rod")
  fire_rod = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/fire_rod/rod",
  })
  state = 1

-- pre-fire_rod_check function, if the player release the key, abandon.
fire_rod_check = sol.timer.start(10, function()
if not game:is_command_pressed(slot) and not game:get_value("starting_cutscene") then
fire_rod:remove()
if fire_rod_process ~= nil then hero:set_tunic_sprite_id("hero/tunic"..tunic); fire_rod_process:stop(); fire_rod_process = nil end 
if fire_rod_sync ~= nil then fire_rod_sync:stop() end
self:transit_to_finish()
end
return true
end)

fire_rod_process = sol.timer.start(300,function()
item:store_equipment()
fire_rod_check:stop()
hero:unfreeze()

hero:set_tunic_sprite_id("hero/item/fire_rod/rod_moving_tunic_"..tunic)
hero:set_walking_speed(55)

fire_rod:get_sprite():set_animation("walking")

fire_rod_sync = sol.timer.start(10, function()
local lx, ly, layer = hero:get_position()
--systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
--Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input fire_rod_checking and values instead of direction fire_rod_checking
-- this is just a placeholder until the function will be back

if hero:get_direction() == 0 then new_x = -1; new_y = 0 
elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
end

fire_rod:set_position(hero:get_position()) 
fire_rod:set_direction(hero:get_direction())
 
if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
if hero:get_state() == "falling" or hero:get_state() == "stairs" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
if hero:get_state() == "treasure" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
return true
end)
  
fire_rod_timer = sol.timer.start(200, function()
if fire_timer ~= nil then
game:remove_magic(1)
end
return true
end)

fire_timer = sol.timer.start(100, function()
if game:is_command_pressed(slot) and not starting_cutscene then
  if game:get_magic() > 0 then self:shoot_fire() end
else
  hero:set_walking_speed(88)
  hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
  
  game:set_pause_allowed(true)
  hero:unfreeze()
  
  fire_rod_sync:stop(); fire_rod_sync = nil
  fire_rod:remove()
  fire_timer:stop(); fire_timer = nil
  fire_rod_timer:stop(); fire_rod_timer = nil
  
  self:transit_to_finish()
  
end
return true
end)

end)
  if fire_timer ~= nil then fire_timer:stop() end
  if fire_rod_timer ~= nil then fire_rod_timer:stop() end
end


-- Creates some fire on the map.
function item:shoot_fire()
  local hero = game:get_hero()
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
  local fire = game:get_map():create_custom_entity({
    model = "fire_beam",
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
if fire_rod_timer ~= nil then fire_rod_timer:stop() end
if fire_rod_check ~= nil then fire_rod_check:stop() end
if fire_rod_sync ~= nil then fire_rod_sync:stop() end
if fire_rod ~= nil then fire_rod:remove() end
game:item_finished()

state = 0

game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
end


-- Initialize the metatable of appropriate entities to work with the fire.
local function initialize_meta()

  -- Add Lua fire properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_fire_reaction ~= nil then
    -- Already done.
    return
  end

  enemy_meta.fire_reaction = 2  -- 2 life points by default.
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