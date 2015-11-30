local item = ...
local game = item:get_game()

-- Fire Rod - Four Swords Adventure style

--[[
Un-solved Issue listing
#Issue 7 : Direction Fix
--]]

function item:on_created()
  self:set_savegame_variable("i1853")
  self:set_assignable(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("/common/big_item")
end

function item:on_map_changed()
if fire_rod ~= nil then fire_rod:remove() end
if fire_rod_process ~= nil then fire_rod_process:stop(); fire_rod_process = nil end 
if rod_sync ~= nil then rod_sync:stop() end
self:set_finished()
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    local sword = game:get_ability("sword")
    game:set_ability("sword", 0)
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
    local kb_action_key = game:get_command_keyboard_binding("action")
    game:set_command_keyboard_binding("action", nil)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
    game:set_value("item_saved_action", kb_action_key)
    game:set_pause_allowed(false)
end

function item:on_using()
local map = game:get_map()
local hero = game:get_hero()

local new_x = 0
local new_y = 0

local x, y, layer = hero:get_position()
local direction = hero:get_direction()

local tunic = game:get_ability("tunic")

-- read the 2 item slot.
local fire_rod_slot
if game:get_value("_item_slot_1") == "fire_rod" then fire_rod_slot = "item_1"
elseif game:get_value("_item_slot_2") == "fire_rod" then fire_rod_slot = "item_2" end
print("1"..fire_rod_slot)
-- we are starting the item. check if another item is currently used by the hero. If yes, destroy the other item in order to start this one. (WIP)
if game:get_value("currently_using_item") == true then print("another item is on_using") end

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
if game:is_command_pressed(fire_rod_slot) ~= true and game:get_value("is_cutscene") ~= true then
fire_rod:remove()
if fire_rod_process ~= nil then fire_rod_process:stop(); fire_rod_process = nil end 
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
if game:is_command_pressed(fire_rod_slot) and game:get_value("is_cutscene") ~= true then
  if self:get_game():get_magic() > 0 then self:shoot_fire() end
else
  hero:set_walking_speed(88)
  hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("sword", game:get_value("item_saved_sword"))
  game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
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
  fire_timer:stop()
  magic_timer:stop()
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
  
 sol.audio.play_sound("/items/rod/fire/shoot")

local fire_mvt = sol.movement.create("straight")
fire_mvt:set_angle(hero:get_direction() * math.pi / 2)
fire_mvt:set_speed(200)
fire_mvt:set_max_distance(32)
fire_mvt:set_smooth(false)
fire_mvt:start(fire)
end


function item:set_finished()
-- destroy timers
fire_timer:stop()
magic_timer:stop()
check:stop()
rod_sync:stop()

local hero = self:get_game():get_hero()

hero:unfreeze()

hero:set_walking_speed(88)
hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
game:set_ability("tunic", game:get_value("item_saved_tunic"))
game:set_ability("sword", game:get_value("item_saved_sword"))
game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
game:set_ability("shield", game:get_value("item_saved_shield"))
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