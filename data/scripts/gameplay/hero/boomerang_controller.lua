local boomerang_controller = {}
-- Preload everything, these values are loaded when the game creates the item. So the game don't need to load them when called
boomerang_controller.slot  = "item_1";
boomerang_controller.opposite_slot  = "item_2";
boomerang_controller.opposite_slot_to_number  = 2;
boomerang_controller.current_tunic  = "";
boomerang_controller.distance = 204;
boomerang_controller.speed = 204;
boomerang_controller.collision_sprite  = "entities/item.collision";
boomerang_controller.boomerang_sprite  = "entities/boomerang";
boomerang_controller.hook_x = 0;
boomerang_controller.hook_y = 0;
boomerang_controller.hero_free_tunic = "";
boomerang_controller.hero_armed_tunic = "";
boomerang_controller.new_x = 0;
boomerang_controller.new_y = 0;
boomerang_controller.gx = 0;
boomerang_controller.gy = 0;
boomerang_controller.lx = 0;
boomerang_controller.ly = 0;
boomerang_controller.llayer = 0;
boomerang_controller.current_boomerang = nil -- the current boomerang entity
 
local is_halted_by_anything_else = false
local avoid_return = false
local from_teleporter = false
local is_shot = false
local ended_by_pickable = false
local has_canceled_while_boomerang_active = false
local has_pressed_cancel = false
local has_received_boomerang = false

function boomerang_controller:start_boomerang(game, level)
  self.level = level
  self.game = game
  avoid_return = true
  
  if self.level == 1 then
    self.distance = 150
	self.speed = 164
  else
    self.distance = 204
    self.speed = 204
  end
  
  if self.game.is_going_to_another_item then 
	self.game:set_item_on_use(false)
  else 
    self.game:set_value("current_shield", self.game:get_ability("shield"))
    self.game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
	self.game:set_ability("shield", 0)
	self.game:get_hero():set_shield_sprite_id("hero/shield_item")
  end
  
   
  self.game:get_hero():set_animation("boomerang_outro", function()
    self.game:set_value("item_boomerang_state", 1)
    self.game:get_hero():set_walking_speed(45)
    self.game:get_hero():unfreeze()
    self.game:get_hero():set_tunic_sprite_id(self.hero_free_tunic)
	self.game:set_custom_command_effect("attack", "return")
	self.game.is_going_to_another_item = false 
    has_canceled_while_boomerang_active = false
	avoid_return = false
    sol.menu.start(self.game:get_map(), self)	-- do not inherit this menu to the whole game, since it is disabled when transitionning to another map
  end)

  for teleporter in self.game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  is_halted_by_anything_else = true
      has_canceled_while_boomerang_active = false
	  self.current_boomerang = nil
	  from_teleporter = true
	  is_shot = false
	  if not self.game:is_current_scene_cutscene() then self.game:show_cutscene_bars(false) end
	  self.game:get_hero():freeze()
	  self:stop_boomerang()
	end
  end
  sol.audio.play_sound("common/item_show")
  self:start_ground_check() 
end

function boomerang_controller:start_ground_check()
  local hero = self.game:get_hero()
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
    is_halted_by_anything_else = true
	has_canceled_while_boomerang_active = true
	if hero:get_state() == "hurt" then hero:set_invincible(true, 1000) hero:set_blinking(true, 1000) end
	boomerang_controller:stop_boomerang() 
  end

  sol.timer.start(self, 50, function()
	self.lx, self.ly, self.llayer = self.game:get_hero():get_position()
	
	-- Todo : when hero:on_direction_changed() will be available, delete this, and replace the whole thing by input checking and values instead of direction checking
	
	if hero:get_direction() == 0 then self.new_x = -1; self.new_y = 0; self.gx = 1; self.gy = 0
	elseif hero:get_direction() == 1 then self.new_x = 0; self.new_y = 1 ; self.gy = -1;  self.gx = 0
	elseif hero:get_direction() == 2 then self.new_x = 1; self.new_y = 0 ; self.gy = 0;  self.gx = -1
	elseif hero:get_direction() == 3 then self.new_x = 0; self.new_y = -1; self.gy = 1;  self.gx = 0
	end

	if hero:get_state() == "swimming" or (hero:get_state() == "jumping" and not is_shot) then hero:set_position(self.lx + self.new_x, self.ly + self.new_y); end_by_collision() end
	if (hero:get_state() == "falling" and hero:get_animation() == "boomerang_catch") or hero:get_state() == "stairs" or hero:get_animation() == "swimming_stopped" or hero:get_state() == "hurt" or self.game:get_map():get_ground(self.lx + self.gx, self.ly + self.gy, self.llayer) == "lava" or hero:get_state() == "treasure" then end_by_collision() end

	-- check if the item has changed
	if self.game:get_value("_item_slot_2") == "boomerang" then 
      self.slot = "item_2" 
	  self.opposite_slot = "item_1"
      self.opposite_slot_to_number = 1
    else
      self.slot = "item_1" 
	  self.opposite_slot = "item_2"
      self.opposite_slot_to_number = 2
    end
	
	self.current_tunic = self.game:get_ability("tunic")
	self.hero_free_tunic = "hero/item/boomerang/boomerang_moving_free_tunic"..self.current_tunic
    self.hero_armed_tunic = "hero/item/boomerang/boomerang_moving_armed_tunic"..self.current_tunic
	
	if not self.game:is_suspended() then
	  if self.game:get_value("_item_slot_1") ~= "boomerang" and self.game:get_value("_item_slot_2") ~= "boomerang" then 
	    if self.current_boomerang ~= nil then
	      has_canceled_while_boomerang_active = true
	    end
	    if hero:get_animation() == "boomerang_catch" or hero:get_animation() == "stopped" or hero:get_animation() == "stopped_with_shield" then
	      self.game:set_value("item_boomerang_state", 3)
	      hero:unfreeze()
		  has_canceled_while_boomerang_active = true
		  hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
	    end
	    self:stop_boomerang()
      end
	  if self.game.has_changed_tunic and self.game:is_command_pressed(self.slot) and hero:get_animation() ~= "boomerang_intro" and (self.game:get_value("item_boomerang_state") == 1 or self.game:get_value("item_boomerang_state") == 2) then self.game.has_changed_tunic = false hero:set_tunic_sprite_id(self.hero_armed_tunic) end
	  if self.game.has_changed_tunic and not self.game:is_command_pressed(self.slot) then self.game.has_changed_tunic = false hero:set_tunic_sprite_id(self.hero_free_tunic) end
	  if not self.game:is_command_pressed(self.slot) and self.game:get_value("item_boomerang_state") == 2 and not is_shot then self.game:simulate_command_released(self.slot) end
	end
	
  return true
  end)
end

function boomerang_controller:create_boomerang()
  local map = self.game:get_map()
  local hero = self.game:get_hero()
  local x, y, layer = hero:get_position()
  local going_back = false
  local direction = hero:get_direction()
  local hooked = false
  local entities_caught = {}
  local go
  local go_back
  local stop
  local orig_correct, hook_x, hook_y, entities_finaly = 0, 0, 0, 0
  local correct_trajectory = 5
  local collision
  local collision_sprite
  local boomerang_sprite
  local boomerang
  
  if hero:get_direction() == 0 then hook_x = 10; hook_y = -5;
  elseif hero:get_direction() == 1 then hook_x = 0; hook_y = -10; orig_correct = 1; entities_finaly = 8; correct_trajectory = 6
  elseif hero:get_direction() == 2 then hook_x = -10; hook_y = -5
  else hook_x = 0; hook_y = 0; correct_trajectory = 0
  end

  local function set_can_traverse_rules(entity)
    entity:set_can_traverse("crystal", true)
    entity:set_can_traverse("crystal_block", true)
    entity:set_can_traverse("jumper", true)
    entity:set_can_traverse("stairs", false)
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
  
    sol.timer.start(250, function()
      sol.audio.play_sound("items/boomerang/firing_loop")
    return is_shot
    end)
    sol.audio.play_sound("items/boomerang/firing_start")
	
	sol.timer.start(50, function()
	  local lx, ly, llayer = boomerang:get_position()
	  local trail = map:create_custom_entity({
			x = lx,
			y = ly,
			layer = llayer,
			direction = 0,
			sprite = boomerang_controller.boomerang_sprite,
		    })
		trail:get_sprite():fade_out(6, function() trail:remove() end)
	  return is_shot
	end)
  
    local go_movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    go_movement:set_speed(boomerang_controller.distance)
    go_movement:set_angle(angle)
    go_movement:set_smooth(false)
    go_movement:set_max_distance(boomerang_controller.distance)
    go_movement:start(boomerang)

    function go_movement:on_obstacle_reached()
	
	local boomerang_sprite_x, boomerang_sprite_y = boomerang:get_position()
	  collision = map:create_custom_entity({ x = boomerang_sprite_x + hook_x, y = (boomerang_sprite_y + 8) + hook_y, layer = layer, direction = 0})
	  collision_sprite = collision:create_sprite(boomerang_controller.collision_sprite)
      function collision_sprite:on_animation_finished()
	    collision:remove()
	  end
      sol.audio.play_sound("items/item_metal_collision_wall")
      go_back()
    end

    function go_movement:on_finished()
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
    local angle = (direction + 2) * math.pi / 2
    movement:set_speed(boomerang_controller.distance)
    movement:set_target(hero)
    movement:set_ignore_obstacles(true)
    movement:start(boomerang)
	
    going_back = true

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(boomerang:get_position())
      end
    end

    function movement:on_finished()
	  stop()
    end
  end

  -- Destroys the boomerang and restores control to the player, the hero isn't tracted.
  function stop()
	is_shot = false
	has_received_boomerang = true
	local hx, hy, hz = boomerang:get_position()
	for _, entity in ipairs(entities_caught) do
      entity:set_position(hx, hy + entities_finaly, hz)
    end
	self.game:set_value("item_boomerang_state", 3)
    if boomerang ~= nil then
      boomerang:remove()
	  boomerang_controller.current_boomerang = nil
    end
	
    if hero:get_state() ~= "swimming" 
	  and hero:get_state() ~= "hurt" 
	  and hero:get_state() ~= "jumping" 
	  and hero:get_state() ~= "falling" 
	  and hero:get_state() ~= "treasure" 
	  and hero:get_state() ~= "stairs" 
	  and hero:get_state() ~= "back to solid ground"
	  and not self.game:is_current_scene_cutscene() 
	  and not self.game:is_using_item() then 
	  hero:freeze()
	  avoid_return = true
	  hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
	  sol.timer.start(1, function()
	    hero:set_animation("boomerang_catch")
	  end)
	  sol.audio.play_sound("characters/link/voice/catch_boomerang")
	end
	
  sol.timer.start(121, function()
	if not has_canceled_while_boomerang_active then 
		hero:set_walking_speed(50)
		self.game:set_value("item_boomerang_state", 1)
		hero:unfreeze()
		hero:set_tunic_sprite_id(self.hero_free_tunic)
		if self.game:is_command_pressed(self.slot) then
		  self.game:simulate_command_pressed(self.slot)
		end
	else
		self.game:set_value("item_boomerang_state", 0)
	    if hero:get_state() ~= "swimming" 
		  and hero:get_state() ~= "hurt" 
		  and hero:get_state() ~= "jumping"
		  and hero:get_state() ~= "falling"
		  and hero:get_state() ~= "treasure"
		  and hero:get_state() ~= "stairs" 
		  and hero:get_state() ~= "back to solid ground"
		  and not self.game:is_current_scene_cutscene() 
		  and not self.game:is_using_item() 
		  and hero:get_tunic_sprite_id() == "hero/tunic"..self.current_tunic then
		  self:stop_boomerang()
		  hero:unfreeze()
		end
    end
  sol.audio.play_sound("common/item_show")
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
  
  self.current_boomerang = boomerang
  
  boomerang:set_origin(4, 6) --5
  boomerang:set_drawn_in_y_order(true)
  boomerang_controller.current_boomerang = boomerang

  -- Set up boomerang sprites.
  boomerang_sprite = boomerang:create_sprite(boomerang_controller.boomerang_sprite)
  boomerang_sprite:set_direction(0)

  -- Set what can be traversed by the boomerang.
  set_can_traverse_rules(boomerang)

  -- Set up collisions.
  boomerang:add_collision_test("overlapping", function(boomerang, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the boomerang.
      if going_back then
        stop()
      end
    elseif entity_type == "crystal" then
      -- Activate crystals.
      if not hooked and not going_back then
        sol.audio.play_sound("switch")
        map:change_crystal_state()
        go_back()
      end
    elseif entity_type == "switch" then
      -- Activate solid switches.
      local switch = entity
      local sprite = switch:get_sprite()
      if not hooked and
          not going_back and
          sprite ~= nil and
          sprite:get_animation_set() == "entities/solid_switch" then
        if switch:is_activated() then
          sol.audio.play_sound("sword_tapping")
        else
          sol.audio.play_sound("switch")
          switch:set_activated(true)
        end
        go_back()
      end
    elseif entity.is_boomerang_catchable ~= nil and entity:is_boomerang_catchable() then
      -- Catch the entity with the boomerang.
      if not hooked and not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(boomerang:get_position())
        boomerang:set_modified_ground("traversable")  -- Don't let the caught entity fall in holes.
        go_back()
      end
	elseif entity:get_type() == "enemy" then
      if hooked then
        return
      end
      local reaction = entity:get_attack_boomerang(enemy_sprite)
      entity:receive_attack_consequence("boomerang", reaction)
      go_back()
    end
  end)

  -- Start the movement.
  go()
end

function boomerang_controller:on_command_pressed(command)
  local hero = self.game:get_hero()
  
  if command == self.slot and not is_shot and not self.game:is_suspended() then
    avoid_return = true
	sol.audio.play_sound("common/item_show")
	hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
	hero:set_animation("boomerang_intro")
	sol.timer.start(self, 100, function()
	  hero:unfreeze()
	  hero:set_tunic_sprite_id(self.hero_armed_tunic)
      hero:set_walking_speed(40)
	  self.game:set_value("item_boomerang_state", 2)
	  avoid_return = false
	  if not self.game:is_command_pressed(self.slot) then self.game:simulate_command_released(self.slot) end
	end)
  elseif command == self.opposite_slot and not self.game:is_suspended() then
    if (self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "hookshot" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "bow" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "dominion_rod") and not avoid_return then
	  self.game.is_going_to_another_item = true
	  is_halted_by_anything_else = true
	  self.game:set_item_on_use(true)
	  self:stop_boomerang()
	  self.game:get_hero():freeze()
	  self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	  sol.timer.start(10, function()
	    self.game:set_custom_command_effect("action", nil)
	    self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
	  end)
	  if self.current_boomerang ~= nil then has_canceled_while_boomerang_active = true else has_canceled_while_boomerang_active = false end
	  if is_shot and self.current_boomerang == nil then is_shot = false avoid_return = true end	
	end
  elseif command == "attack" and not avoid_return and not self.game.is_going_to_another_item and not self.game:is_suspended() then
    self:stop_boomerang()
	if not self.game:is_current_scene_cutscene() then self.game:show_cutscene_bars(false) end
	has_pressed_cancel = true
	if self.current_boomerang ~= nil then
	  has_canceled_while_boomerang_active = true
	end
  elseif command == "pause" then
    return false
  end
  return true
end

function boomerang_controller:on_command_released(command)
local hero = self.game:get_hero()
  if command == self.slot and self.game:get_value("item_boomerang_state") == 2 and not is_shot and not self.game:is_suspended() then
    avoid_return = true
	is_shot = true
    hero:freeze()
    hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
	hero:set_animation("boomerang_shoot")
	sol.timer.start(self, 100, function()
	  self:create_boomerang()
	  sol.audio.play_sound("items/boomerang/firing_start0")
	  sol.audio.play_sound("characters/link/voice/throw0")
	  hero:set_walking_speed(50)
	  hero:unfreeze()
	  hero:set_tunic_sprite_id(self.hero_free_tunic)
	  avoid_return = false
	end)
  end
end

function boomerang_controller:stop_boomerang()  
  self.game:get_hero():set_walking_speed(88)
  self.game:set_custom_command_effect("attack", nil)
  self.game:set_custom_command_effect("action", nil)
  self.game:set_value("item_boomerang_state", 0)
  self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.current_tunic)
  avoid_return = false
  
  if (not self.game:is_current_scene_cutscene() and self.game:is_cutscene_bars_enabled() and not ended_by_pickable and not self.game.is_going_to_another_item and has_received_boomerang) then self.game:show_cutscene_bars(false) has_received_boomerang = false end
  
  if not is_halted_by_anything_else then
    if not from_teleporter then sol.audio.play_sound("common/item_show") end
	from_teleporter = false
	self.game:get_hero():freeze()
	self.game:get_hero():set_animation("boomerang_outro")
	sol.timer.start(100, function()
	  self.game:set_ability("shield", self.game:get_value("current_shield"))
	  self.game:get_hero():unfreeze()
	  if self.game.is_using_lantern then
	    self.game:get_hero():set_tunic_sprite_id("hero/item/lantern.tunic"..self.game:get_ability("tunic"))
	  else
	    self.game:get_hero():set_shield_sprite_id("hero/shield"..self.game:get_ability("shield"))
	  end
	  sol.menu.stop(self)
	  self.game:get_item("boomerang"):set_finished()
	end)
  else 
    is_halted_by_anything_else = false
	if not self.game.is_going_to_another_item then
	  if self.game:get_hero():get_state() == "falling" then
	    sol.timer.start(800, function()
	      self.game:set_ability("shield", self.game:get_value("current_shield"))
	      self.game:get_hero():set_shield_sprite_id("hero/shield"..self.game:get_ability("shield"))
		end)
	  else
	    self.game:set_ability("shield", self.game:get_value("current_shield"))
	    self.game:get_hero():set_shield_sprite_id("hero/shield"..self.game:get_ability("shield"))
	  end
	end
	self.game:get_item("boomerang"):set_finished()
	sol.menu.stop(self)
  end
  ended_by_pickable = false
  has_pressed_cancel = false
  sol.timer.stop_all(self)
end

return boomerang_controller