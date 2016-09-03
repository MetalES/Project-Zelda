local hero_meta = sol.main.get_metatable("hero")
local diving_manager = require("scripts/gameplay/hero/diving_manager")

local was_loading
local number_of_spin = 0

local function play_sound(id)
  sol.audio.play_sound("characters/link/voice/" .. id)
end
  
local function sword_sound_id(self, id)
  self:set_sword_sound_id("characters/link/voice/" .. id)
end

-- Redefine the on_taking_damage event. It is called when the hero is hurt
-- by any entity.
function hero_meta:on_taking_damage(damage)
  local game = self:get_game()
  local hero_mode = game:get_value("hero_mode")
  local shield = game:get_ability("shield")
  
  if self:is_condition_active('frozen') then
    damage = damage * 3
    self:stop_frozen(true)
  end
  if damage < 1 then
    damage = 1
  end
  
  if hero_mode then
	if shield > 1 then
	  damage = math.floor(damage / (shield / 3))
	else 
	  damage = damage * 2
	end
  else 
	if shield > 1 then
	  damage = math.floor(damage / shield)
	else
	  damage = damage
	end
  end
  game:remove_life(damage)
end
  
-- Plays a sound when the hero is pushing / pulling something.
-- set bool to false if you want to stop the timers.
local function start_push_pull_sound(hero, bool)
  if bool then 
    if not hero:get_game():is_using_item() then
      sol.audio.play_sound("characters/link/voice/push")
	  hero.timer_push_effect = sol.timer.start(50, function()
	    sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	  end)
	  hero.timer_tunic_push_effect = sol.timer.start(2500, function()
	    if hero:get_state() == "pushing" or hero:get_state() == "pulling" then
	      hero:set_animation(hero:get_state() .. "_state2")
	    end
	  end)
	  hero.timer_push_sound = sol.timer.start(500, function()
	    sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	    return hero:get_state() == "pushing" or hero:get_state() == "pulling"
	  end)	   
    end
  else
    if hero.timer_push_effect ~= nil then hero.timer_push_effect:stop() end
	if hero.timer_tunic_push_effect ~= nil then hero.timer_tunic_push_effect:stop() end
	if hero.timer_push_sound ~= nil then hero.timer_push_sound:stop() end
  end
end
	
-- Create a beam on the sword if the skill has been learned.
local function shoot_sword_beam(hero, typeof)
  local direction = hero:get_direction()
  local dx, dy = 0, 0
  local x, y, layer = hero:get_position()
  
  if direction == 0 then dx, dy = 8, -5
  elseif direction == 1 then  dy = -12
  elseif direction == 2 then dx, dy = -8, -5 end
  
  local event = hero:get_game():get_map():create_custom_entity({
    model = typeof,
	x = x + dx,
	y = y + dy,
	width = 16,
	height = 16,
	layer = layer,
	direction = direction,
  })
  event:check_if_can_shoot()
end


function hero_meta:on_state_changed(state)
  local game = self:get_game()
  local life = game:get_life()
  local max_life = game:get_max_life()
  local sword = game:get_ability("sword")

  local random_sword_snd = math.random(4)
  local random_snd = math.random(2)
  local random_swordattack_spin_snd = math.random(0, 2)
  
  if state == "hurt" then
    play_sound("hurt" .. random_snd)
	return
  end
  	
  -- The hero is swinging the sword.
  if state == "sword swinging" then
    start_push_pull_sound(self, false) 
	if game:get_value("item_cloak_darkness_state") == 1 then
	  sword_sound_id(self, "cloak_attack" .. random_sword_snd)
	else
	  sword_sound_id(self, "attack" .. random_sword_snd) 
	end
    if life <= max_life / 4 and sword > 1 and game:is_skill_learned(3) then -- skill 3
	  shoot_sword_beam(self, "perish_beam")  
	elseif life == max_life and sword > 1 and game:is_skill_learned(4) then -- skill 4
	  shoot_sword_beam(self, "full_life_beam") 
	end
	return
  end
  
  -- The hero is loading the sword.
  if state == "sword loading" then
	if not game:is_skill_learned(1) then
	  game:simulate_command_released("attack")
	else
	  self:set_walking_speed(44)
	  was_loading = true
	end
	return
  end
  
  -- The hero is spin attacking.
  if state == "sword spin attack" then
	if game:get_value("item_cloak_darkness_state") ~= 0 then
	  play_sound("cloak_spin" .. random_swordattack_spin_snd)
	else
	  play_sound("spin" .. random_swordattack_spin_snd)
	end
	return
  end
  
  -- The hero is free.	
  if state == "free" then
    start_push_pull_sound(self, false) 
	if sol.menu.is_started(diving_manager) then sol.menu.stop(diving_manager) end
	if was_loading then self:set_walking_speed(88); was_loading = false end
	return
  end
  
  -- The hero is pushing / pulling something.
  if state == "pushing" or state == "pulling" then
    if not game:is_using_item() and not self:get_animation():match("boomerang") then
	  start_push_pull_sound(self, true) 
	end
  end
  
  -- The hero is grabbing something.
  if state == "grabbing" then
    start_push_pull_sound(self, false) 
	return
  end
	
  -- The hero is jumping.
  if state == "jumping" then
    play_sound("jump")
	return
  end
	
  -- The hero is swimming  
  if state == "swimming" then
	self:cancel_direction_fix()
	
	if game:has_item("flippers") then
	  self:get_game():set_custom_command_effect("attack", "return") 
      diving_manager:start(game)
	end 
	
	if game:get_value("item_cloak_darkness_state") == 0 then
	  sol.timer.start(self, 50, function()
		local lx, ly, llayer = self:get_position()
		local trail = self:get_map():create_custom_entity({
		  x = lx,
		  y = ly,
		  layer = llayer,
		  width = 16,
		  height = 16,
		  direction = 0,
		})
		
		local sprite = trail:create_sprite("effects/hero/swimming_trails")
		sprite:set_direction(self:get_direction())
		sprite:fade_out(12, function() trail:remove() end)
		
	    return self:get_state() == "swimming"
	  end)
	end
  end	
end

function hero_meta:on_position_changed()
  if self.on_custom_position_changed ~= nil then
    self:on_custom_position_changed()
	return
  end
end

-- Custom Functions 
-- The hero is being teleported somewhere else
function hero_meta:teleport_to(map_id, destination, transition)
  local map_id = map_id
  local destination = destination
  local transition = transition or "fade"
  local dest_map = "normal/"

  if self:get_game():get_value("hero_mode") then
    dest_map = "mirror/"
  end
  
  self:teleport(dest_map .. map_id, destination, transition)
end
  
-- The hero has picked something
function hero_meta:display_pickable_above_head(sprite, variant)
  local x, y, layer = self:get_position()
  local pickable_sprite = self:get_map():create_custom_entity({
    x = x,
    y = y - 8,
	layer = layer,
	width = 8,
	height = 8,
	direction = 0,
  })
  local sprites = pickable_sprite:create_sprite("entities/items")

  sprites:set_animation(sprite)
  
  if sprite == "heart" then
	sprites:set_frame(24)
    sprites:set_frame_delay(1800)
  end
  
  if variant then
    sprites:set_direction(variant - 1)
  end

  local movement_update = sol.timer.start(10, function()
	local lx, ly, ll = self:get_position()
	pickable_sprite:set_position(lx, ly - 24, ll)
	return true
  end)

  sol.timer.start(250, function() 
	sprites:fade_out(2, function() 
	  movement_update:stop()
	  pickable_sprite:remove()
	end) 
  end)
end

-- Item: Restore the hero direction and animation when he's walking on a stair
function hero_meta:restore_state_stairs()
  local input = {[0] = "left", [1] =  "up", [2] = "right", [3] =  "down"}
  local direction
  
  -- Return the current command pressed
  for i = 0, 3 do
    if self:get_game():is_command_pressed(input[i]) then
	  direction = i
    end
  end
  self:cancel_direction_fix()
  self:set_direction(direction)
  -- Restore the animation, and check if he has a shield
  self:set_animation("walking" .. (self:get_game():get_ability("shield") > 0 and "_with_shield" or "")) 
end

-- Trading sequence, the hero is showing an item to something
function hero_meta:show_item_to_object(item, callback)
  local game = self:get_game()
  local map = self:get_map()
  local animation_direction = item:get_variant()
  
  local sprite = map:create_custom_entity({
    x = 10,
	y = 10,
	layer = 1,
	width = 16,
	height = 16,
    sprite = "entities/items",  
  })
  
  sprite:get_sprite():set_animation(item)
  sprite:get_sprite():set_direction(animation_direction)



end

-- The Hero arrive from a hole, start an animation of him falling
-- TODO
function hero_meta:from_hole()
  self:freeze()
  local tunic = self:get_sprite("tunic")
  local shield = self:get_sprite("shield")
  local x, y, layer = self:get_position()

  tunic:set_xy(0, -320)
  if shield ~= nil then
    shield:get_xy(0, -320)
  end
  
  local movement = sol.movement.create("straight")
  movement:set_angle(3 * math.pi / 2)
  movement:set_speed(200)
  movement:set_max_distance(320)
  movement:set_ignore_obstacles(true)
  movement:start(tunic, function() self:unfreeze() end)
  -- movement:start(shield)

end

-- The hero is using an item (Bow, Hookshot, Boomerang, Dominion Rod). It's direction need to be locked
-- Function to set a fixed direction for the hero (or nil to disable it).
function hero_meta:set_fixed_direction(direction)
  if direction ~= nil then
    self.fixed_direction = direction
    self:get_sprite("tunic"):set_direction(direction)
  end
end
-- Function to get a fixed direction for the hero.
function hero_meta:get_fixed_direction()
  return self.fixed_direction
end
-- Function to set fixed stopped/walking animations for the hero (or nil to disable it).
function hero_meta:set_fixed_animations(stopped_animation, walking_animation)
  self.fixed_stopped_animation = stopped_animation
  self.fixed_walking_animation = walking_animation
end
-- Function to get fixed stopped/walking animations for the hero.
function hero_meta:get_fixed_animations()
  return self.fixed_stopped_animation, self.fixed_walking_animation
end

function hero_meta:cancel_direction_fix()
  self:set_fixed_animations(nil, nil)
  self.fixed_direction = nil
end

-- Initialize events to fix direction and animation for the tunic sprite of the hero.
-- To do it, we redefine the on_created and set_tunic_sprite_id events using the hero metatable.
do
  local function initialize_fixing_functions(hero)
    -- Define events for the tunic sprite.
	local game = hero:get_game()
    local sprite = hero:get_sprite("tunic")
	
    function sprite:on_animation_changed(animation)
      local fixed_stopped_animation = hero.fixed_stopped_animation
      local fixed_walking_animation = hero.fixed_walking_animation
	  
      local tunic_animation = sprite:get_animation()
	  local with_shield = hero:get_game():get_ability("shield") > 0 and "_with_shield" or ""
	  
	  if (tunic_animation == "pushing" or tunic_animation == "grabbing" or tunic_animation == "pulling") and ((fixed_walking_animation ~= nil and fixed_walking_animation ~= "lantern_walking") or game:is_using_item()) then 
	      hero:unfreeze()
	  
	  elseif tunic_animation == "stopped" .. with_shield and fixed_stopped_animation ~= nil then 
        if fixed_stopped_animation ~= tunic_animation then
          sprite:set_animation(fixed_stopped_animation)
		end
      elseif tunic_animation == "walking" .. with_shield and fixed_walking_animation ~= nil then 
        if fixed_walking_animation ~= tunic_animation then
          sprite:set_animation(fixed_walking_animation)
        end
	  end
    end
	
    function sprite:on_direction_changed(animation, direction)
      local fixed_direction = hero.fixed_direction
      local tunic_direction = sprite:get_direction()
      if fixed_direction ~= nil and fixed_direction ~= tunic_direction then
        sprite:set_direction(fixed_direction)
      end
    end
  end
  
  -- Initialize fixing functions when the hero is created.
  function hero_meta:on_created()
    initialize_fixing_functions(self)
  end
  
  -- Initialize fixing functions for the new sprite when the sprite is replaced for a new one.
  local old_set_tunic = hero_meta.set_tunic_sprite_id -- Redefine this function.
  function hero_meta:set_tunic_sprite_id(sprite_id)
    old_set_tunic(self, sprite_id)
    initialize_fixing_functions(self)
  end
end