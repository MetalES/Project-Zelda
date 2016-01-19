local item = ...
local game = item:get_game()

local item_name = "ice_rod"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

local volume_bgm = game:get_value("old_volume")

-- Ice Rod

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value("item_"..item_name.."_state", 0)
end

function item:on_obtained()
  if show_bars == true and not starting_cutscene then game:hide_bars() end
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_map_changed()
if game:get_value("item_"..item_name.."_state") > 0 then 
game:set_ability("sword", game:get_value("item_saved_sword"))
game:get_hero():set_tunic_sprite_id("hero/tunic" ..game:get_value("item_saved_tunic"))
if not starting_cutscene then game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
self:set_finished()
end
end

function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

if ice_timer ~= nil then ice_timer:stop() end
if ice_magic_timer ~= nil then ice_magic_timer:stop() end
if ice_check ~= nil then ice_check:stop() end
if ice_rod_sync ~= nil then ice_rod_sync:stop() end
if ice_rod ~= nil then ice_rod:remove() end
        
game:set_custom_command_effect("attack", nil)

hero:freeze()
hero:set_walking_speed(88)

sol.audio.play_sound("common/item_show")
hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))
game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_ability("sword", game:get_value("item_saved_sword"))
hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
self:set_finished()
game:set_pause_allowed(true)
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

local function end_by_collision() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if ice_timer ~= nil then ice_timer:stop() end if ice_magic_timer ~= nil then ice_magic_timer:stop(); item:set_finished() end; if ice_check ~= nil then ice_check:stop(); item:set_finished() end; if ice_rod_sync ~= nil then ice_rod_sync:stop(); item:set_finished() end; if ice_rod ~= nil then ice_rod:remove(); item:set_finished() end; item:set_finished(); game:set_pause_allowed(true) end
local function end_by_pickable() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); item:set_finished(); game:set_pause_allowed(true) end

-- read the 2 item slot.
  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end

  hero:set_animation("rod")
  ice_rod = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/ice_rod/rod",
  })
  game:set_value("item_"..item_name.."_state", 1)

-- pre-check function, if the player release the key, abandon.
ice_check = sol.timer.start(10, function()
if game:is_command_pressed(slot) ~= true and not starting_cutscene then
ice_rod:remove()
if ice_rod_process ~= nil then hero:set_tunic_sprite_id("hero/tunic"..tunic); ice_rod_process:stop(); ice_rod_process = nil end 
if ice_rod_sync ~= nil then ice_rod_sync:stop() end
self:set_finished()
end
return true
end)

ice_rod_process = sol.timer.start(300,function()
item:store_equipment()
ice_check:stop()
hero:unfreeze()

hero:set_tunic_sprite_id("hero/item/fire_rod/rod_moving_tunic_"..tunic)
hero:set_walking_speed(55)

ice_rod:get_sprite():set_animation("walking")

ice_rod_sync = sol.timer.start(10, function()
local lx, ly, layer = hero:get_position()
--systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
--Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
-- this is just a placeholder until the function will be back

if hero:get_direction() == 0 then new_x = -1; new_y = 0 
elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
end

ice_rod:set_position(hero:get_position()) 
ice_rod:set_direction(hero:get_direction())
 
if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
if hero:get_state() == "falling" or hero:get_state() == "stairs" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
if hero:get_state() == "treasure" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
return true
end)
  
ice_magic_timer = sol.timer.start(200, function()
if ice_timer ~= nil then
game:remove_magic(1)
end
return true
end)

ice_timer = sol.timer.start(100, function()
if game:is_command_pressed(slot) and not starting_cutscene then
  if game:get_magic() > 0 then self:shoot_ice() end
else
  hero:set_walking_speed(88)
  hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
  
  game:set_pause_allowed(true)
  hero:unfreeze()
  
  ice_rod_sync:stop(); ice_rod_sync = nil
  ice_rod:remove()
  ice_timer:stop(); ice_timer = nil
  ice_magic_timer:stop(); magic_timer = nil
  
  self:transit_to_finish()
  
end
return true
end)

end)
  if ice_timer ~= nil then ice_timer:stop() end
  if ice_magic_timer ~= nil then ice_magic_timer:stop() end
end


-- Creates some fire on the map.
function item:shoot_ice()
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
  local ice = game:get_map():create_custom_entity({
    model = "ice_beam",
    x = x + dx,
    y = y + dy,
    layer = layer,
    direction = direction,
  })
  
 sol.audio.play_sound(sound_dir.."shoot")

local ice_mvt = sol.movement.create("straight")
ice_mvt:set_angle(hero:get_direction() * math.pi / 2)
ice_mvt:set_speed(200)
ice_mvt:set_max_distance(32)
ice_mvt:set_smooth(false)
ice_mvt:start(ice)
end


function item:set_finished()
if ice_timer ~= nil then ice_timer:stop() end
if ice_magic_timer ~= nil then ice_magic_timer:stop() end
if ice_check ~= nil then ice_check:stop() end
if ice_rod_sync ~= nil then ice_rod_sync:stop() end
if ice_rod ~= nil then ice_rod:remove() end

local hero = game:get_hero()

hero:unfreeze()

game:set_value("item_"..item_name.."_state", 0)

game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
end


-- Initialize the metatable of appropriate entities to work with the fire.
local function initialize_meta()

  -- Add Lua ice beam properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_ice_reaction ~= nil then
    -- Already done.
    return
  end

  enemy_meta.ice_reaction = "immobilized"
  enemy_meta.ice_reaction_sprite = {}
  function enemy_meta:get_ice_reaction(sprite)

    if sprite ~= nil and self.ice_reaction_sprite[sprite] ~= nil then
      return self.ice_reaction_sprite[sprite]
    end
    return self.ice_reaction
  end

  function enemy_meta:set_ice_reaction(reaction, sprite)

    self.ice_reaction = reaction
  end

  function enemy_meta:set_ice_reaction_sprite(sprite, reaction)

    self.ice_reaction_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also
  -- take into account the ice.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_ice_reaction("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_ice_reaction_sprite(sprite, "ignored")
  end

end
initialize_meta()
