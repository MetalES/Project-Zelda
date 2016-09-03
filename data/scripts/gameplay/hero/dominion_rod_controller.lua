local dominion_rod_controller = {
  slot = "item_1",
  opposite_slot = "item_2",
  opposite_slot_to_number = 2,
  d_rod = nil,
  distance = 150,
  speed = 164
}

--[[ 
  Name : Dominion Rod Controller
  Creation date : Feb. 2016
  Last modification : April. 8. 2016
  Version : 0.9

  To use with : Item (Dominion Rod)
]]

-- Set which build-in hero state can interrupt this item
local state = {"swimming", "jumping", "falling", "stairs" , "hurt", "plunging", "treasure"}
-- Set which item is compatible for the fast item switching feature
local items = {"hookshot", "bow", "boomerang"}

local function direction_fix(hero)
  hero:set_fixed_direction(hero:get_direction())
  hero:set_fixed_animations("dominion_rod_free_stopped", "dominion_rod_free_walking")
end
 
local is_halted_by_anything_else, avoid_return, from_teleporter, is_shot, ended_by_pickable = false
local timer

function dominion_rod_controller:start_dominion_rod(game)
  self.game = game
  self.hero = game:get_hero()
  
  if game.is_going_to_another_item then 
	game:set_item_on_use(false)
  else 
    game:set_value("current_shield", game:get_ability("shield"))
    self.game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
	game:set_ability("shield", 0)
	self.hero:set_shield_sprite_id("hero/shield_item")
  end
  
  self.hero:set_animation("dominion_rod_outro", function()
    self.game:set_value("item_dominion_rod_state", 1)
	self.hero:set_walking_speed(40)
	self.hero:set_fixed_direction(self.hero:get_direction())
	self.hero:set_fixed_animations("dominion_rod_free_stopped", "dominion_rod_free_walking")
	self.hero:unfreeze()
	
	game:set_custom_command_effect("attack", "return")
	game.is_going_to_another_item = false 
    has_canceled_while_d_rod_active = false
	avoid_return = false
    sol.menu.start(game:get_map(), self)
  end)

  for teleporter in game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  is_halted_by_anything_else = true
      has_canceled_while_d_rod_active = false
	  self.d_rod = nil
	  from_teleporter = true
	  is_shot = false
	  if not game:is_current_scene_cutscene() then game:show_cutscene_bars(false) end
	  self.hero:freeze()
	  self:stop_dominion_rod()
	end
  end
  sol.audio.play_sound("common/item_show")
  self:start_ground_check() 
end

function dominion_rod_controller:start_ground_check()
  local hero = self.hero
  
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    is_halted_by_anything_else = true
	has_canceled_while_dominion_rod_active = true
	if hero:get_state() == "stairs" then hero:set_animation("walking") end
	dominion_rod_controller:stop_dominion_rod() 
  end

  timer = sol.timer.start(self, 50, function()
    for _, state in ipairs(state) do
	  if hero:get_state() == state then
	    self.can_control = false
		hero:cancel_direction_fix()
	    end_by_collision() 
	  end
	end

	-- check if the item has changed
	self.slot = "item_1" 
	self.opposite_slot = "item_2"
    self.opposite_slot_to_number = 2
	if self.game:get_value("_item_slot_2") == "dominion_rod" then 
      self.slot = "item_2" 
	  self.opposite_slot = "item_1"
      self.opposite_slot_to_number = 1
	end
	
	if not self.game:is_suspended() then
	  if self.game:get_value("_item_slot_1") ~= "dominion_rod" and self.game:get_value("_item_slot_2") ~= "dominion_rod" then 
	    if self.d_rod ~= nil then
	      has_canceled_while_d_rod_active = true
	    end
	    self:stop_dominion_rod()
      end
	  
	  if not self.game:is_command_pressed(self.slot) and self.game:get_value("item_d_rod_state") == 2 and not is_shot then self.game:simulate_command_released(self.slot) end
	end
  return true
  end)
  timer:set_suspended_with_map(true)
end

function dominion_rod_controller:create_dominion_rod()
  local game = self.game
  local map = game:get_map()
  local hero = self.hero
  local x, y, layer = hero:get_position()
  local going_back = false
  local direction = hero:get_direction()
  local entities_caught = {}
  local orig_correct, hook_x, hook_y, entities_finaly = 0, 0, 0, 0
  local correct_trajectory = 5
  local d_rod_sprite, d_rod, go, stop, go_back
  
  if hero:get_direction() == 0 then hook_x = 10; hook_y = -5;
  elseif hero:get_direction() == 1 then hook_y = -10; orig_correct = 1; entities_finaly = 8; correct_trajectory = 6
  elseif hero:get_direction() == 2 then hook_x = -10; hook_y = -5
  else correct_trajectory = 0
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

  -- Starts the d_rod movement from the hero.
  function go()
    sol.timer.start(250, function()
      sol.audio.play_sound("items/d_rod/firing_loop")
      return is_shot
    end)
    sol.audio.play_sound("items/d_rod/firing_start")
	
	sol.timer.start(50, function()
	  local lx, ly, llayer = d_rod:get_position()
	  local trail = map:create_custom_entity({
		x = lx,
		y = ly,
		layer = llayer,
		direction = 0,
		sprite = "entities/dominion_rod",
	  })
	  trail:get_sprite():fade_out(6, function() trail:remove() end)
	  return is_shot
	end)
  
    local go_movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    go_movement:set_speed(dominion_rod_controller.speed)
    go_movement:set_angle(angle)
    go_movement:set_smooth(false)
    go_movement:set_max_distance(dominion_rod_controller.distance)
    go_movement:start(d_rod)

    function go_movement:on_obstacle_reached()
      go_back()
    end

    function go_movement:on_finished()
      go_back()
    end
  end

  -- Makes the d_rod come back to the hero.
  -- Does nothing if the d_rod is already going back.
  function go_back()
    if going_back then
      return
    end
	 
    local movement = sol.movement.create("target")
    local angle = (direction + 2) * math.pi / 2
    movement:set_speed(dominion_rod_controller.distance)
    movement:set_target(hero)
    movement:set_ignore_obstacles(true)
    movement:start(d_rod)
	
    going_back = true

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(d_rod:get_position())
      end
    end

    function movement:on_finished()
	  stop()
    end
  end

  -- Destroys the d_rod and restores control to the player, the hero isn't tracted.
  function stop()
	is_shot = false
	has_received_d_rod = true
	
	game:set_value("item_dominion_rod_state", 3)
	
    if d_rod ~= nil then
      d_rod:remove()
	  dominion_rod_controller.d_rod = nil
    end

	if hero:get_state() == "free" and not game:is_current_scene_cutscene() and (not game:is_using_item() or game:get_value("item_dominion_rod_state") > 0) then
	  hero:freeze()
	  avoid_return = true
	  hero:set_animation("dominion_rod_catch", function() sol.audio.play_sound("common/item_show") end)
	  sol.audio.play_sound("characters/link/voice/catch_d_rod")
	end
	
  sol.timer.start(121, function()
	if not has_canceled_while_d_rod_active then 
	  hero:set_walking_speed(50)
	  game:set_value("item_dominion_rod_state", 1)
	  hero:set_fixed_animations("dominion_rod_free_stopped", "dominion_rod_free_walking")
	  if game:is_command_pressed(self.slot) then
		game:simulate_command_pressed(self.slot)
	  end
	  hero:unfreeze()
	else
	  game:set_value("item_dominion_rod_state", 0)
	  
	  if hero:get_state() ~= "swimming" 
		and hero:get_state() ~= "hurt" 
		and hero:get_state() ~= "jumping"
		and hero:get_state() ~= "falling"
		and hero:get_state() ~= "treasure"
		and hero:get_state() ~= "stairs" 
		and hero:get_state() ~= "back to solid ground"
		and not game:is_current_scene_cutscene() 
		and not game:is_using_item() then
		  self:stop_dominion_rod()
		  hero:unfreeze()
		elseif hero:get_state() == "swimming" then
		  game:show_cutscene_bars(false)
		  sol.menu.stop(self)
		end
	  end
  
  avoid_return = false
  end)
end

  -- Create the d_rod.
  d_rod = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x + hook_x,
    y = y + hook_y,
    width = 8,
    height = 8,
  })
  
  d_rod:set_origin(4, 6)
  d_rod:set_drawn_in_y_order(true)
  dominion_rod_controller.d_rod = d_rod

  -- Set up d_rod sprites.
  d_rod_sprite = d_rod:create_sprite("entities/d_rod")
  d_rod_sprite:set_direction(0)

  -- Set what can be traversed by the d_rod.
  set_can_traverse_rules(d_rod)

  -- Set up collisions.
  d_rod:add_collision_test("overlapping", function(d_rod, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the d_rod.
      if going_back then
        stop()
      end
    elseif entity_type == "crystal" then
      -- Activate crystals.
      if not going_back then
        sol.audio.play_sound("switch")
        map:change_crystal_state()
        go_back()
      end
    elseif entity_type == "switch" then
      -- Activate solid switches.
      local switch = entity
      local sprite = switch:get_sprite()
      if not going_back and
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
    elseif entity.is_dominion_rod_compatible ~= nil and entity:is_dominion_rod_compatible() then
      if not going_back and not hero.controlling_entity_dominion_rod then
        hero.controlling_entity_dominion_rod = true
		dominion_rod:start_control_entity(entity)
      end
	elseif entity:get_type() == "enemy" then
      local reaction = entity:get_attack_dominion_rod(enemy_sprite)
      entity:receive_attack_consequence("dominion_rod", reaction)
      go_back()
    end
  end)

  -- Start the movement.
  go()
end

function dominion_rod_controller:on_command_pressed(command)
  local hero = self.hero
  local game = self.game
  local suspended = game:is_suspended()
  
  if command == self.slot and not is_shot and not suspended then
    avoid_return = true
	sol.audio.play_sound("common/item_show")

	hero:set_animation("d_rod_intro")
	sol.timer.start(self, 100, function()
	  hero:set_fixed_animations("d_rod_armed_stopped", "d_rod_armed_walking")
      hero:set_walking_speed(30)
	  game:set_value("item_d_rod_state", 2)
	  avoid_return = false
	  if not game:is_command_pressed(self.slot) then game:simulate_command_released(self.slot) end
	  hero:unfreeze()
	end)
	
  elseif command == "attack" and not avoid_return and not game.is_going_to_another_item and not suspended then
    self:stop_d_rod()
	if not game:is_current_scene_cutscene() then game:show_cutscene_bars(false) end
	has_pressed_cancel = true
	if self.d_rod ~= nil then
	  has_canceled_while_d_rod_active = true
	end
	
  elseif command == "pause" then
    return false
	
  else
    for _, item in ipairs(items) do
	  if command == self.opposite_slot and game:get_value("_item_slot_"..self.opposite_slot_to_number) == item and not avoid_return and not suspended then
		game.is_going_to_another_item = true
	    is_halted_by_anything_else = true
	    self:stop_d_rod()
	    hero:freeze()
		
		if self.d_rod ~= nil then
		  has_canceled_while_d_rod_active = true
		end

		sol.timer.start(10, function()
	      game:set_custom_command_effect("action", nil)
	      game:get_item(game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
		end)
	  end
	end
  end
  return true
end

function dominion_rod_controller:on_command_released(command)
  local hero = self.hero
  if command == self.slot and self.game:get_value("item_d_rod_state") == 2 and not is_shot and not self.game:is_suspended() then
    avoid_return = true
	is_shot = true
    hero:freeze()

	hero:set_animation("d_rod_shoot")
	sol.timer.start(self, 100, function()
	  self:create_d_rod()
	  sol.audio.play_sound("items/d_rod/firing_start0")
	  sol.audio.play_sound("characters/link/voice/throw0")
	  hero:set_walking_speed(50)
	  hero:set_fixed_animations("d_rod_free_stopped", "d_rod_free_walking")
	  hero:unfreeze()
	  avoid_return = false
	end)
  end
end

function dominion_rod_controller:stop_d_rod()
  local game = self.game
  local hero = self.hero  
  
  hero:set_walking_speed(88)
  game:set_custom_command_effect("attack", nil)
  game:set_custom_command_effect("action", nil)
  game:set_value("item_d_rod_state", 0)
  
  local function restore_shield()
    game:set_ability("shield", game:get_value("current_shield"))
	hero:set_shield_sprite_id("hero/shield" .. game:get_ability("shield"))
  end

  avoid_return = false
  
  if (not game:is_current_scene_cutscene() and game:is_cutscene_bars_enabled() and not ended_by_pickable and not game.is_going_to_another_item) then game:show_cutscene_bars(false) end
  
  if not is_halted_by_anything_else then
    if not from_teleporter then sol.audio.play_sound("common/item_show") end
	from_teleporter = false
	hero:freeze()
	hero:set_animation("d_rod_outro")
	sol.timer.start(100, function()
	  game:set_ability("shield", self.game:get_value("current_shield"))
	  hero:unfreeze()
	  if not game.is_using_lantern then
	    hero:set_shield_sprite_id("hero/shield" .. game:get_ability("shield"))
	  end
	  sol.menu.stop(self)
	end)
  else 
    is_halted_by_anything_else = false
	if not game.is_going_to_another_item then
	  if hero:get_state() == "falling" then
	    sol.timer.start(800, function()
	      restore_shield()
		end)
	  else
	    restore_shield()
	  end
	end
	sol.menu.stop(self)
  end
  
  ended_by_pickable = false
  
  game:get_item("d_rod"):set_finished()
  hero:cancel_direction_fix()
  sol.timer.stop_all(self)
end

return dominion_rod_controller