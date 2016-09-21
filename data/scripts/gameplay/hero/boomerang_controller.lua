local boomerang_controller = {
  slot = "item_1",          -- Slot of the Item, replaced dynamically
  boomerang = nil,          -- Boomerang Entity
  distance = 150,           -- Max Distance
  speed = 164,              -- Speed of the Boomerang
  state = 0,                -- State of the Boomerang (integers)
  shot = false,             -- Is it shot ?
  canceled_active = false,  -- Is the boomerang still active while canceling ?
}

-- Set which build-in hero state can interrupt this item
local state = {"swimming", "jumping", "falling", "stairs", "hurt", "plunging", "treasure"}
local alt_state = {"swimming", "jumping", "stairs", "plunging"}
-- Set which item is compatible for the fast item switching feature
local items = {"hookshot", "bow", "dominion_rod"}
-- Set script related variable
local force_stop, avoid_return, ended_by_pickable = false, false, false
local timer = nil

local function set_aminations(hero, num)
  local prefix = {"boomerang_free_", "boomerang_armed_"}
  hero:set_fixed_animations(prefix[num] .. "stopped", prefix[num] .. "walking")
end

local function state_met(hero, cond)
  local met
  for i = 1, 4 do
    met = cond == "not" and hero:get_state() ~= alt_state[i] or hero:get_state() == alt_state[i]
  end
  return met
end

function boomerang_controller:start_boomerang(game, level)
  self.level = level
  self.game = game
  self.hero = game:get_hero()
  
  local hero = self.hero
  
  if hero.shield == nil then
    hero.shield = game:get_ability("shield")
    game:set_ability("shield", 0)
  end
  
  if self.level == 2 then
    self.distance = 204
    self.speed = 204
  end
  
  if game.is_going_to_another_item then 
	game:set_item_on_use(false)
	game.is_going_to_another_item = false 
  else 
    self.game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
  end
  
  hero:set_animation("boomerang_outro", function()
    self.state = 1
	hero:set_walking_speed(40)
	hero:set_fixed_direction(hero:get_direction())
	set_aminations(hero, 1)
	hero:unfreeze()
	
	game:set_custom_command_effect("attack", "return")
	
    self.canceled_active = false
	avoid_return = false
    sol.menu.start(game:get_map(), self)
  end)

  sol.audio.play_sound("common/item_show")
  self:start_ground_check() 
end

function boomerang_controller:start_ground_check()
  local hero = self.hero
  
  local function end_by_collision() 
    local state = hero:get_state()
	force_stop = true
    if state == "treasure" then ended_by_pickable = true end
	self.canceled_active = true
	if state == "stairs" then
	  hero:restore_state_stairs()
	end
	sol.menu.stop(boomerang_controller)
  end

  sol.timer.start(self, 10, function()
    local item_name = self.game:get_item_assigned(2) or nil
    local item_opposite = item_name ~= nil and item_name:get_name() or nil
    local item = item_opposite == "boomerang" or nil
	
    for _, state in ipairs(state) do
	  if hero:get_state() == state then
		hero:cancel_direction_fix()
	    end_by_collision() 
		return
	  end
	end

	-- Check if the item has changed
	self.slot = item and "item_2" or "item_1"
	
	-- Check if the boomerang is still assigned on a slot
	if not self.game:is_suspended() then
	  local assigned_1 = self.game:get_item_assigned(1) ~= nil and self.game:get_item_assigned(1):get_name() or nil 
	  local assigned_2 = self.game:get_item_assigned(2) ~= nil and self.game:get_item_assigned(2):get_name() or nil
	
	  if (assigned_1 == nil or assigned_1 ~= "boomerang") and (assigned_2 == nil or assigned_2 ~= "boomerang") then  
	    self:stop_boomerang()
	    return
	  end
	
	  -- If unpaused and if the input is released while aiming, shoot the boomerang
	  if not self.game:is_command_pressed(self.slot) and self.state == 2 and not self.shot then 
		self.game:simulate_command_released(self.slot)
	  end
	end
  return true
  end)
end

function boomerang_controller:stop_boomerang()
  if self.boomerang ~= nil then
	self.canceled_active = true
  end
  sol.menu.stop(self)
  return
end

function boomerang_controller:create_boomerang()
  local game = self.game
  local map = game:get_map()
  local hero = self.hero
  local script = self
  
  local x, y, layer = hero:get_position()
  local going_back = false
  local direction = hero:get_direction()
  local entities_caught = {}
  local hook_x, hook_y = 0, 0
  local boomerang_sprite, boomerang, go, stop, go_back
  
  if direction == 0 then 
    hook_x = 10
	hook_y = -5;
  elseif direction == 1 then 
    hook_y = -10
  elseif direction == 2 then 
    hook_x = -10
	hook_y = -5
  end

  local function set_can_traverse_rules(entity)
    entity:set_can_traverse("crystal", true)
    entity:set_can_traverse("crystal_block", true)
    entity:set_can_traverse("jumper", true)
    entity:set_can_traverse("stairs", function(other, stairs)
	  local _, _, sl = stairs:get_position()
	  return sl < layer
	end)
    entity:set_can_traverse("stream", true)
    entity:set_can_traverse("switch", true)
    entity:set_can_traverse("teletransporter", true)
    entity:set_can_traverse_ground("deep_water", true)
    entity:set_can_traverse_ground("shallow_water", true)
    entity:set_can_traverse_ground("hole", true)
    entity:set_can_traverse_ground("lava", true)
    entity:set_can_traverse_ground("prickles", true)
    entity:set_can_traverse_ground("low_wall", true)
    entity.apply_cliffs = true
  end

  -- Starts the boomerang movement from the hero.
  function go()
    local times_played = 0
    sol.audio.play_sound("items/boomerang/firing_start")
	
	sol.timer.start(50, function()
	  times_played = times_played + 1
	  
	  if times_played == 5 then
	    sol.audio.play_sound("items/boomerang/firing_loop")
	    times_played = 0
	  end
	
	  local lx, ly, llayer = boomerang:get_position()
	  local trail = map:create_custom_entity({
		x = lx,
		y = ly,
		layer = llayer,
		direction = 0,
		width = 8,
		height = 8,
		sprite = "entities/item_boomerang",
	  })
	  
	  trail:get_sprite():fade_out(6, function() trail:remove() end)
	  return self.shot
	end)
  
    local movement = sol.movement.create("straight")
    movement:set_speed(script.speed)
    movement:set_angle(direction * math.pi / 2)
	movement:set_smooth(false)
    movement:set_max_distance(script.distance)
    movement:start(boomerang)

    function movement:on_obstacle_reached()
	  local boomerang_sprite_x, boomerang_sprite_y = boomerang:get_position()
	  map:create_collision(boomerang_sprite_x + hook_x, (boomerang_sprite_y + 8) + hook_y, layer)
      go_back()
    end

    function movement:on_finished()
      go_back()
    end
  end

  -- Makes the boomerang come back to the hero.
  -- Does nothing if the boomerang is already going back.
  function go_back()
    if going_back then
      return
    end
	
    local movement = sol.movement.create("target")
    movement:set_speed(script.speed + 16)
    movement:set_target(hero)
    movement:set_ignore_obstacles(true)
    movement:start(boomerang)
	
    going_back = true

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(boomerang:get_position())
      end
    end

  end

  -- Destroys the boomerang and restores control to the player
  function stop()
	self.shot = false
	self.state = 3
	
    if boomerang ~= nil then
      boomerang:remove()
	  script.boomerang = nil
    end

	if hero:get_state() == "free" and not game:is_current_scene_cutscene() and not game:is_using_item() then
	  avoid_return = true
	  hero:set_animation("boomerang_catch", function() 
	    avoid_return = false
		hero:unfreeze()
		sol.audio.play_sound("common/item_show")
	  end)
	  
	  sol.audio.play_sound("characters/link/voice/catch_boomerang")
	end
	
    sol.timer.start(120, function()
	  if hero:get_state() == "free" then
 	    if game:is_using_item() then
	      self.state = 0
	      self.canceled_active = false -- this was off
		  force_stop = false
		  sol.audio.play_sound("common/item_show") 
	      sol.menu.stop(self)
		  return
		else
		  hero:unfreeze()
		end
	  end
	  
	  if not self.canceled_active then 
	    if sol.menu.is_started(self) then
	      hero:set_walking_speed(50)
	      self.state = 1
	      set_aminations(hero, 1)
	      if game:is_command_pressed(self.slot) then script:on_command_pressed(self.slot) end
		else
		  sol.menu.stop(self)
		  return
		end
	  else
	    -- The item is not active anymore
	    self.canceled_active = false
	    self.state = 0
	    for i, state in ipairs(state) do
	      if hero:get_state() == state then 
		    if state == state_met(hero, "not") then
		      if not game:is_current_scene_cutscene() and not game:is_using_item() then
		        sol.menu.stop(script)
		      end
		    else
		      game:show_cutscene_bars(false)
		      force_stop = true
			  sol.menu.stop(script)
		    end
		  end
	    end
		hero:set_walking_speed(88)		
	  end
    avoid_return = false
    end)
  end

  -- Create the boomerang.
  boomerang = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x + hook_x,
    y = y + hook_y,
    width = 8,
    height = 8,
  })
  
  boomerang:set_origin(4, 6)
  boomerang:set_drawn_in_y_order(true)
  script.boomerang = boomerang

  -- Set up boomerang sprites.
  boomerang_sprite = boomerang:create_sprite("entities/item_boomerang")
  boomerang_sprite:set_direction(0)

  -- Set what can be traversed by the boomerang.
  set_can_traverse_rules(boomerang)

  -- Set up collisions.
  boomerang:add_collision_test("overlapping", function(boomerang, entity)
    local boomerang_sprite_x, boomerang_sprite_y = boomerang:get_position()
    local entity_type = entity:get_type()
	
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the boomerang.
      if going_back then
        stop()
      end
	end
	
    if entity_type == "crystal" then
      -- Activate crystals.
      if not going_back then
        sol.audio.play_sound("switch")
        map:change_crystal_state()
		map:create_collision(boomerang_sprite_x + hook_x, (boomerang_sprite_y + 8) + hook_y, layer)
        go_back()
      end
    elseif entity_type == "switch" then
      -- Activate solid switches.
      local sprite = entity:get_sprite()
      if not going_back and sprite ~= nil and sprite:get_animation_set() == "entities/solid_switch" then
        if entity:is_activated() then
          sol.audio.play_sound("sword_tapping")
        else
          sol.audio.play_sound("switch")
          entity:set_activated(true)
        end
		map:create_collision(boomerang_sprite_x + hook_x, (boomerang_sprite_y + 8) + hook_y, layer)
        go_back()
      end
    elseif entity.is_boomerang_catchable ~= nil and entity:is_boomerang_catchable() then
      -- Catch the entity with the boomerang.
      if not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(boomerang:get_position())
        boomerang:set_modified_ground("traversable")  -- Don't let the caught entity fall in holes.
        go_back()
      end
	elseif entity:get_type() == "enemy" then
      local reaction = entity:get_attack_boomerang(enemy_sprite)
      entity:receive_attack_consequence("boomerang", reaction)
      go_back()
    end
  end)

  -- Start the movement.
  go()
end

function boomerang_controller:on_command_pressed(command)
  local game = self.game
  local hero = self.hero
  
  local suspended = game:is_suspended()
  local another_item = game.is_going_to_another_item
  local opposite = self.slot == "item_1" and "1" or "2"
  local item_name = game:get_item_assigned(opposite) or nil
  local state = self.state
  local item_opposite = item_name ~= nil and item_name:get_name() or nil
  
  if command == "pause" then
    return false
  end
  
  if not suspended and not avoid_return then
    if command == self.slot and state == 1 and self.boomerang == nil then
	  self.state = 3
	  
	  avoid_return = true
	  sol.audio.play_sound("common/item_show")
		
	  hero:freeze()
	  hero:set_animation("boomerang_intro")
		
	  sol.timer.start(self, 100, function()
	    set_aminations(hero, 2)
        hero:set_walking_speed(30)
	    self.state = 2
	    avoid_return = false
	    if not game:is_command_pressed(self.slot) then game:simulate_command_released(self.slot) end
	    hero:unfreeze() 
	  end)
	  
	elseif command == "attack" and not another_item then
	  sol.menu.stop(self)
	  sol.audio.play_sound("common/item_show")
	  
	  if self.boomerang ~= nil then
		self.canceled_active = true
	  end
	  
	elseif command == "item_" .. opposite and item_opposite ~= nil then
	  for _, item in ipairs(items) do
	    if item_opposite == item then
		  hero:freeze()
		  game.is_going_to_another_item = true
		  force_stop = true
		  sol.menu.stop(self)
		
		  if self.boomerang ~= nil then
		    self.canceled_active = true
		  end

		  game:get_item(item_opposite):set_state(0)
	      game:set_custom_command_effect("action", nil)
	      game:get_item(item_opposite):on_using()
		  
	    end
	  end
    end
  end

  return true
end

function boomerang_controller:on_command_released(command)
  local hero = self.hero
  
  if command == self.slot and self.state == 2 and not self.game:is_suspended() then
	
    self.state = 3
    avoid_return = true
	
    hero:freeze()
	hero:set_animation("boomerang_shoot")
	
	hero:get_sprite():set_ignore_suspend(false)
	local t = sol.timer.start(self, 180, function()
	  self.shot = true
	  self:create_boomerang()
	  sol.audio.play_sound("items/boomerang/firing_start0")
	  sol.audio.play_sound("characters/link/voice/throw0")
	  hero:set_walking_speed(50)
	  set_aminations(hero, 1)
	  hero:unfreeze() 
	  avoid_return = false
	end)
	t:set_suspended_with_map(true)
  end
end

function boomerang_controller:on_finished()
  local game = self.game
  local hero = self.hero
  
  self.state = 0
  
  hero:set_walking_speed(88)
  game:set_custom_command_effect("attack", nil)
  game:set_custom_command_effect("action", nil)
  
  if game:is_cutscene_bars_enabled() and not game:is_current_scene_cutscene() and not ended_by_pickable and not game.is_going_to_another_item then
    game:show_cutscene_bars(false)
  end
  
  if not force_stop then
    hero:freeze()
	hero:set_animation("boomerang_outro", function()	  
	  if not game:is_current_scene_cutscene() then
	    hero:unfreeze()
	  else
	    hero:unfreeze()
	    hero:set_animation("stopped" .. (game:get_ability("shield") > 0 and "_with_shield" or ""))
		hero:freeze()
  	  end
	end)
  end
  
  force_stop = false
  ended_by_pickable = false
  avoid_return = false
  
  hero:cancel_direction_fix()
  
  if game.is_using_lantern then
    hero:set_fixed_animations("lantern_stopped", "lantern_walking")
  else
    game:set_ability("shield", hero.shield)
    hero.shield = nil
  end
  
  sol.timer.stop_all(self)
end

return boomerang_controller