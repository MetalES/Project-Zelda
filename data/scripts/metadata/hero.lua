local hero_meta = sol.main.get_metatable("hero")
local diving_manager = require("scripts/gameplay/hero/diving_manager")

local was_loading, super_spin_timer
local number_of_spin = 0

-- Redefine the on_taking_damage event. It is called when the hero is hurt
-- by any entity.
function hero_meta:on_taking_damage(damage)
  local damage = damage
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
  local dx, dy
  local x, y, layer = hero:get_position()
  
  if direction == 0 then dx, dy = 8, -5
  elseif direction == 1 then dx, dy = 0, -12
  elseif direction == 2 then dx, dy = -8, -5
  else dx, dy = 0, 0 end
  
  local event = hero:get_game():get_map():create_custom_entity({
    model = typeof,
	x = x + dx,
	y = y + dy,
	layer = layer,
	direction = direction,
  })
  event:check_if_can_shoot()
end

-- Event called when the state of the hero has changed.
function hero_meta:on_state_changed(state)
  local random_sword_snd = math.random(4)
  local random_snd = math.random(2)
  local random_swordattack_spin_snd = math.random(0, 2)

  -- Event: The hero is swinging the sword.
  if state == "sword swinging" then -- sword sound
    start_push_pull_sound(self, false) 
	local game = self:get_game()
	if game:get_value("item_cloak_darkness_state") == 1 then
	  self:set_sword_sound_id("characters/link/voice/cloak_attack"..random_sword_snd)
	else
	  self:set_sword_sound_id("characters/link/voice/attack"..random_sword_snd) 
	end
    if game:get_life() <= game:get_max_life() / 4 and game:get_ability("sword") > 1 and game:is_skill_learned(3) then -- skill 3
	  shoot_sword_beam(self, "perish_beam")  
	elseif game:get_life() == game:get_max_life() and game:get_ability("sword") > 1 and game:is_skill_learned(4) then -- skill 4
	  shoot_sword_beam(self, "full_life_beam") 
	end
  -- Event: The hero is loading the sword.
  elseif state == "sword loading" then
	local game = self:get_game()
	if not game:is_skill_learned(1) then
	  game:simulate_command_released("attack")
	else
	  self:set_walking_speed(44)
	  was_loading = true
	end
  -- Event: The hero is spin attacking.
  elseif state == "sword spin attack" then
	local game = self:get_game()
	if game:get_value("item_cloak_darkness_state") ~= 0 then
	  sol.audio.play_sound("characters/link/voice/cloak_spin"..random_swordattack_spin_snd)
	else
	  sol.audio.play_sound("characters/link/voice/spin"..random_swordattack_spin_snd)
	end
	if game:is_skill_learned(7) then -- super spin attack (todo, test with a menu)
	  super_spin_timer = sol.timer.start(600, function()
	    if game:is_command_pressed("attack") and number_of_spin <= 7 then
		  local tunic = game:get_ability("tunic")
		  self:set_tunic_sprite_id("hero/tunic2")
		  self:set_tunic_sprite_id("hero/tunic"..tunic)
		  self:get_sprite():set_frame_delay(10)
		  number_of_spin = number_of_spin + 1
		else
		  number_of_spin = 0 
		  return false
		end
		return number_of_spin <= 8
	  end)
	end
  -- Event: The hero is hurt.
  elseif state == "hurt" then
	sol.audio.play_sound("characters/link/voice/hurt"..random_snd)
  -- Event: The hero is free (not dependant of a build-in object).	
  elseif state == "free" then
    start_push_pull_sound(self, false) 
	if sol.menu.is_started(diving_manager) then sol.menu.stop(diving_manager) end
	if was_loading then self:set_walking_speed(88); was_loading = false end
  -- Event: The hero is pushing / pulling something.
  elseif state == "pushing" or state == "pulling" then
    if not self:get_game():is_using_item() then
	  start_push_pull_sound(self, true) 
	end
  -- Event: The hero is grabbing something.
  elseif state == "grabbing" then
    start_push_pull_sound(self, false) 
  -- Event: The hero is jumping.
  elseif state == "jumping" then
    sol.audio.play_sound("characters/link/voice/jump")
  -- Event: The hero is swimming  
  elseif state == "swimming" then
    local game = self:get_game()
	
	if game:has_item("flippers") then
	  self:get_game():set_custom_command_effect("attack", "return") 
      diving_manager:start(self:get_game())
	end 
	
	if game:get_value("item_cloak_darkness_state") == 0 then
	  sol.timer.start(50, function()
		local lx, ly, llayer = self:get_position()
		local trail = self:create_custom_entity({
		  x = lx,
		  y = ly,
		  layer = llayer,
		  direction = self:get_direction(),
		  sprite = "effects/hero/swimming_trails",
		})
		trail:get_sprite():set_animation(self:get_game():get_hero():get_animation())
		trail:get_sprite():fade_out(12, function() trail:remove() end)
	  return self:get_state() == "swimming"
	  end)
	end
  end	
end 


function hero_meta:on_position_changed()  
  if self.is_diving then
	self:set_walking_speed(37)
  end
end

-- Custom Functions 
function hero_meta:set_direction_to_fix(dir)
  self.fixed_direction = dir
end

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
	direction = 0,
	sprite = "entities/items",
  })

  pickable_sprite:get_sprite():set_animation(sprite)
  if pickable_sprite:get_sprite():get_animation() == "heart" then
	pickable_sprite:get_sprite():set_frame(24)
    pickable_sprite:get_sprite():set_frame_delay(160)
  end
  if variant then
    pickable_sprite:get_sprite():set_direction(variant - 1)
  end

  local movement_update = sol.timer.start(10, function()
	local lx, ly, ll = self:get_position()
	pickable_sprite:set_position(lx, ly - 24, ll)
	return true
  end)

  sol.timer.start(250, function() 
	pickable_sprite:get_sprite():fade_out(2, function() 
	  movement_update:stop()
	  pickable_sprite:remove()
	end) 
  end)
end

-- The hero is using an item (Bow, Hookshot, Boomerang, Dominion Rod). It's direction need to be locked (Diarandor)
-- Function to set a fixed direction for the hero (or nil to disable it).
function hero_meta:set_fixed_direction(direction)
  self.fixed_direction = direction
  self:get_sprite("tunic"):set_direction(direction)
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

-- Initialize events to fix direction and animation for the tunic sprite of the hero.
-- To do it, we redefine the on_created and set_tunic_sprite_id events using the hero metatable.
do
  local function initialize_fixing_functions(hero)
    -- Define events for the tunic sprite.
    local sprite = hero:get_sprite("tunic")
    function sprite:on_animation_changed(animation)
      local fixed_stopped_animation = hero.fixed_stopped_animation
      local fixed_walking_animation = hero.fixed_walking_animation
      local tunic_animation = sprite:get_animation()
      if tunic_animation == "stopped" and fixed_stopped_animation ~= nil then 
        if fixed_stopped_animation ~= tunic_animation then
          sprite:set_animation(fixed_stopped_animation)
        end
      elseif tunic_animation == "walking" and fixed_walking_animation ~= nil then 
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