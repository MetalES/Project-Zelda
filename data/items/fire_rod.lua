local item = ...
local game = item:get_game()

<<<<<<< HEAD
-- fire rod - Four Swords Adventure style
-- todo : timers are buggy
-- Work in progress test phase
--[[
dialogs = work  (attempt count : 1)
treasure = work (attempt count : 3)
on_using = work (attempt count : 20)
playtest = work

#Issue 6 : hero animation is frozen, same as the rod
--]]
=======
-- fire rod - Four Swords Adventure style - Work in Progress - 95%
>>>>>>> origin/master

function item:on_created()
  self:set_savegame_variable("i1853")
  self:set_assignable(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("/common/big_item")
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

--freeze_hero, play animation of arming the rod, and then unfreeze
-- hero can't pass stairs, jumpers, etcs
--debug test pass. It works perfectly.

hero:set_animation("rod")
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  
  local fire_rod = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/fire_rod/rod",
  })

-- pre-check function, if the player release the key, abandon.
check = sol.timer.start(10, function()
if sol.input.is_key_pressed("x") ~= true and game:get_value("is_cutscene") ~= true then
fire_rod:remove()
if fire_rod_process ~= nil then fire_rod_process:stop(); fire_rod_process = nil end -- destroy the process (fix#5)
if rod_sync ~= nil then rod_sync:stop() end
self:set_finished()
end
return true
end)


fire_rod_process = sol.timer.start(300,function()
store_equipment()
fire_rod:remove()
hero:unfreeze()
check:stop()

local tunic = game:get_ability("tunic")
hero:set_tunic_sprite_id("hero/item/fire_rod/rod_moving.tunic_"..tunic)
hero:set_walking_speed(55)

  local fire_rod_move = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/fire_rod/rod_moving",
  })

rod_sync = sol.timer.start(10, function()
fire_rod_move:set_position(hero:get_position()) 
fire_rod_move:set_direction(hero:get_direction()) 
return true
end)
  
magic_timer = sol.timer.start(300, function()
if fire_timer ~= nil then
self:get_game():remove_magic(1)
end
return true
end)

<<<<<<< HEAD
fire_timer = sol.timer.start(100, function()
if sol.input.is_key_pressed("x") and game:get_value("is_cutscene") ~= true then
  if self:get_game():get_magic() > 0 then self:shoot_fire() end
=======
fire_timer = sol.timer.start(50, function()
if sol.input.is_key_pressed("x") then -- add joypad and get the item slot.
if self:get_game():get_magic() > 0 then self:shoot_fire() end
>>>>>>> origin/master
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
<<<<<<< HEAD
return true
=======
  return true
>>>>>>> origin/master
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
<<<<<<< HEAD
    layer = layer,
    direction = direction,
  })
  
 sol.audio.play_sound("/items/rod/fire/shoot")
=======
    layer = layer
    --sprite = "entities/fire_burns" don't work...
  }
>>>>>>> origin/master

local fire_mvt = sol.movement.create("straight")
fire_mvt:set_angle(hero:get_direction() * math.pi / 2)
fire_mvt:set_speed(200)
fire_mvt:set_max_distance(32)
fire_mvt:set_smooth(false)
fire_mvt:start(fire)
end
<<<<<<< HEAD


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
=======
>>>>>>> origin/master
