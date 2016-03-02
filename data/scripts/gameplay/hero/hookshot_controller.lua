--[[
/script\Hookshot Controller Script.
/author\Made by MetalZelda - 22.02.2016

/desc\Controller script for the hookshot.

/copyright\Credits if you plan to use the script would be nice. Not for resale. Script and project are part of educationnal project.
]]

local hookshot_controller = {}

-- Preload everything, these values are loaded when the game creates the item. So the game don't need to load them when called
hookshot_controller.slot  = "item_1";
hookshot_controller.opposite_slot  = "item_2";
hookshot_controller.opposite_slot_to_number  = 2;
hookshot_controller.current_tunic  = "";
hookshot_controller.distance = 204;
hookshot_controller.collision_sprite  = "entities/item.collision";
hookshot_controller.hookshot_sprite  = "entities/hookshot";
hookshot_controller.links_sprite  = "entities/hookshot";
hookshot_controller.sound_hit_valid  = "items/hookshot/hit_valid_target";
hookshot_controller.sound_tracting_hero  = "items/hookshot/link_tracted";
hookshot_controller.sound_collision_wall  = "items/item_metal_collision_wall";
hookshot_controller.sound_firing_loop  = "items/hookshot/firing_loop";
hookshot_controller.sound_firing_start  = "items/hookshot/firing_start";
hookshot_controller.sound_arming  = "items/hookshot/arming";
hookshot_controller.hook_x = 0;
hookshot_controller.hook_y = 0;
hookshot_controller.hero_free_tunic = "";
hookshot_controller.hero_armed_tunic = "";
hookshot_controller.hero_intro_animation  = "hookshot_intro";
hookshot_controller.new_x = 0;
hookshot_controller.new_y = 0;
hookshot_controller.gx = 0;
hookshot_controller.gy = 0;
hookshot_controller.lx = 0;
hookshot_controller.ly = 0;
hookshot_controller.llayer = 0;
hookshot_controller.link_hook_x = 0;
hookshot_controller.link_hook_y = 0;
hookshot_controller.current_hookshot = nil -- the current hookshot entity
hookshot_controller.current_leader = nil   -- the current leader entity
 
local is_halted_by_anything_else = false
local avoid_return = false
local from_teleporter = false
local is_shot = false
local ended_by_pickable = false
local retrieve_hookshot_position = false

function hookshot_controller:start_hookshot(game)
  self.game = game
  
  self.current_tunic = self.game:get_ability("tunic")
  self.hero_free_tunic = "hero/item/hookshot/hookshot_moving_free_tunic"..self.current_tunic
  self.hero_armed_tunic = "hero/item/hookshot/hookshot_moving_concentrate_tunic"..self.current_tunic
  
  if self.game:get_value("_item_slot_2") == "hookshot" then 
    self.slot = "item_2" 
	self.opposite_slot = "item_1"
    self.opposite_slot_to_number = 1
  else
    self.slot = "item_1" 
	self.opposite_slot = "item_2"
    self.opposite_slot_to_number = 2
  end
  
  if not self.game.is_going_to_another_item then 
    self.game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
	self.game:get_item("hookshot"):store_equipment("hookshot")
  end
   
  self.game:get_hero():set_animation(self.hero_intro_animation, function()
    self.game:set_value("item_hookshot_state", 1)
    self.game:get_hero():set_walking_speed(40)
    self.game:get_hero():unfreeze()
    self.game:get_hero():set_tunic_sprite_id(self.hero_free_tunic)
	self.game.is_going_to_another_item = false 
	self.game:set_custom_command_effect("attack", "return")
	sol.menu.start(self.game:get_map(), self)	
  end)

  for teleporter in self.game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  avoid_return = true
	  from_teleporter = true
	  self.game:set_value("item_hookshot_state", 0)
	  self.game:get_hero():freeze()
	  self:stop_hookshot()
	end
  end
  
  sol.audio.play_sound("common/item_show")
  
  self:start_ground_check() 
end

function hookshot_controller:start_ground_check()
  local hero = self.game:get_hero()
  
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
    is_halted_by_anything_else = true
	hookshot_controller:stop_hookshot() 
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
	if hero:get_state() == "falling" or hero:get_state() == "stairs" or hero:get_animation() == "swimming_stopped" or hero:get_state() == "hurt" or self.game:get_map():get_ground(self.lx + self.gx, self.ly + self.gy, self.llayer) == "lava" or hero:get_state() == "treasure" then end_by_collision() end

  return true
  end)
end

function hookshot_controller:create_hookshot()
  local map = self.game:get_map()
  local hero = self.game:get_hero()
  local x, y, layer = hero:get_position()
  local going_back = false
  local direction = hero:get_direction()
  local hooked_entity
  local hooked = false
  local entities_caught = {}
  local go
  local go_back
  local hook_to_entity
  local stop
  local orig_correct, hookshot_sprite_x, hookshot_sprite_y, entities_finaly = 0, 0, 0, 0
  local correct_trajectory = 5
  local collision
  local collision_sprite
  local hookshot_sprite
  local link_sprite
  local hookshot
  local leader
  
  retrieve_hookshot_position = true
  
  if hero:get_direction() == 0 then self.hook_x = 10; self.hook_y = -1;
  elseif hero:get_direction() == 1 then self.hook_x = 0; self.hook_y = -10; orig_correct = 1; entities_finaly = 8; correct_trajectory = 6 --10 work 8 default -- 6
  elseif hero:get_direction() == 2 then self.hook_x = -10; self.hook_y = -1
  else self.hook_x = 0; self.hook_y = 0; correct_trajectory = 0
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

  -- Returns if the hero would land on an obstacle at the specified coordinates.
  -- This is similar to entity:test_obstacles() but also checks layers below
  -- in case the ground is empty (because the hero will fall there).
  local function test_hero_obstacle_layers(candidate_x, candidate_y, candidate_layer)
    local hero_x, hero_y, hero_layer = hero:get_position()
    candidate_layer = candidate_layer or hero_layer
    if hero:test_obstacles(candidate_x - hero_x, candidate_y - hero_y, candidate_layer) then
      return true       -- Found an obstacle.
    end

    if candidate_layer == 0 then
      return false      -- Cannot go deeper and no obstacle was found.
    end

    -- Test if we are on empty ground.
    local origin_x, origin_y = hero:get_origin()
    local top_left_x, top_left_y = candidate_x - origin_x, candidate_y - origin_y
    local width, height = hero:get_size()
    if map:get_ground(top_left_x, top_left_y, candidate_layer) == "empty" and
        map:get_ground(top_left_x + width - 1, top_left_y, candidate_layer) == "empty" and
        map:get_ground(top_left_x, top_left_y + height - 1, candidate_layer) == "empty" and
        map:get_ground(top_left_x + width - 1, top_left_y + height - 1, candidate_layer) == "empty" then
      -- We are on empty ground: the hero will fall one layer down.
      return test_hero_obstacle_layers(candidate_x, candidate_y, candidate_layer - 1)
    end
  end

  -- Starts the hookshot movement from the hero.
  function go()
  
    sol.timer.start(62, function()
      sol.audio.play_sound(self.sound_firing_loop)
    return is_shot
    end)
    sol.audio.play_sound(self.sound_firing_start)
  
    local go_movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    go_movement:set_speed(hookshot_controller.distance)
    go_movement:set_angle(angle)
    go_movement:set_smooth(false)
    go_movement:set_max_distance(hookshot_controller.distance)
    go_movement:start(hookshot)

    function go_movement:on_obstacle_reached()
	  collision = map:create_custom_entity({ x = hookshot_sprite_x + hookshot_controller.hook_x, y = hookshot_sprite_y + hookshot_controller.hook_y, layer = layer, direction = 0})
	  collision_sprite = collision:create_sprite(hookshot_controller.collision_sprite)
      function collision_sprite:on_animation_finished()
	    collision:remove()
	  end
      sol.audio.play_sound(hookshot_controller.sound_collision_wall)
      go_back()
    end

    function go_movement:on_finished()
      go_back()
    end
  end

  -- Makes the hookshot come back to the hero.
  -- Does nothing if the hookshot is already going back.
  function go_back()
    if going_back then
      return
    end
	 
    local movement = sol.movement.create("straight")
    local angle = (direction + 2) * math.pi / 2
    movement:set_speed(hookshot_controller.distance)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(hookshot:get_distance(hero))
    movement:set_ignore_obstacles(true)
    movement:start(hookshot)
	
    going_back = true
	retrieve_hookshot_position = false

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(hookshot:get_position())
      end
    end

    function movement:on_finished()
	  stop()
    end
  end

  -- Attaches the hookshot to an entity and makes the hero fly there.
  function hook_to_entity(entity)
    if hooked then
      return      -- Already hooked.
    end
	
    hooked = true
    hookshot:stop_movement()

    leader = map:create_custom_entity({
      direction = direction,
      layer = layer,
      x = x,
      y = y,
      width = 16,
      height = 16,
    })
    leader:set_origin(8, 13)
    set_can_traverse_rules(leader)
    leader.apply_cliffs = true
	
	hookshot_controller.current_leader = leader

    local movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    movement:set_speed(hookshot_controller.distance)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(hookshot:get_distance(hero) - correct_trajectory)
    movement:start(leader)

    hero:start_jumping(0, 100, true)
    hero:get_movement():stop()
    hero:set_animation("hookshot_tracting")
    hero:set_direction(direction)
	sol.audio.play_sound(self.sound_hit_valid)
	sol.audio.play_sound(self.sound_tracting_hero)

    local past_positions = {}
    past_positions[1] = { hero:get_position() }

    function movement:on_position_changed()
      hero:set_position(leader:get_position())
      past_positions[#past_positions + 1] = { leader:get_position() }
    end

    function movement:on_finished()
      stop_tracted() 
      if hero:test_obstacles(0, 0) then
        -- The hero ended up in a wall.
        local fixed_position = past_positions[1]  -- Initial position in case none is legal.
        for i = #past_positions, 2, -1 do
          if not test_hero_obstacle_layers(unpack(past_positions[i])) then
            -- Found a legal position.
            fixed_position = past_positions[i]
            break
          end
        end
        hero:set_position(unpack(fixed_position))
        hero:set_invincible(true, 1000)
        hero:set_blinking(true, 1000)
      end
    end
  end

  -- Destroys the hookshot and restores control to the player, the hero isn't tracted.
  function stop()
    avoid_return = false
	is_shot = false
	local hx, hy, hz = hookshot:get_position()
	  for _, entity in ipairs(entities_caught) do
        entity:set_position(hx, hy + entities_finaly, hz)
      end
	hero:unfreeze()
    if hookshot ~= nil then
      hookshot:remove()
	  hookshot_controller.current_hookshot = nil
    end
    if leader ~= nil then
      leader:remove()
	  hookshot_controller.current_leader = nil
    end
	hero:set_tunic_sprite_id(self.hero_free_tunic)
	hero:set_walking_speed(40)
	self.game:set_value("item_hookshot_state", 1)
  end
  
  -- Destroys the hookshot and restores control to the player, the hero isn't tracted.
  function stop_tracted()
	retrieve_hookshot_position = false
	hookshot_controller:stop_hookshot()  
  end

   sol.timer.start(self, 10, function()
	hookshot_sprite_x, hookshot_sprite_y = hookshot:get_position()
	return retrieve_hookshot_position
   end)
  
  -- Create the hookshot.
  hookshot = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x + hookshot_controller.hook_x,
    y = y + hookshot_controller.hook_y,
    width = 16,
    height = 16,
  })
  hookshot:set_origin(8, 12) --5
  hookshot:set_drawn_in_y_order(true)
  
  hookshot_controller.current_hookshot = hookshot

  -- Set up hookshot sprites.
  hookshot_sprite = hookshot:create_sprite(hookshot_controller.hookshot_sprite)
  hookshot_sprite:set_direction(direction)
  link_sprite = sol.sprite.create(hookshot_controller.links_sprite)
  link_sprite:set_animation("link")
  link_sprite:set_direction(direction)

  function hookshot:on_pre_draw()
    -- Draw the links.
    local num_links = 22
    local dxy = {
      {  16,  -6 },
      {   0, -14 },
      { -16,  -6 },
      {   0,   6 }
    }
    local hero_x, hero_y = hero:get_position()
    local x1 = hero_x + dxy[direction + 1][1]
    local y1 = hero_y + dxy[direction + 1][2]
    local x2, y2 = hookshot:get_position()
    y2 = y2 - 5
    for i = 0, num_links - 1 do
      local link_x = x1 + (x2 - x1) * i / num_links
      local link_y = y1 + (y2 - y1) * i / num_links

      -- Skip the first one when going to the North because it overlaps
      -- the hero sprite and can be drawn above it sometimes.
      local skip = direction == 1 and link_x == hero_x and i == 0
      if not skip then
        map:draw_sprite(link_sprite, link_x, link_y)
      end
    end
  end

  -- Set what can be traversed by the hookshot.
  set_can_traverse_rules(hookshot)

  -- Set up collisions.
  hookshot:add_collision_test("overlapping", function(hookshot, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the hookshot.
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
    elseif entity.is_hookshot_catchable ~= nil and entity:is_hookshot_catchable() then
      -- Catch the entity with the hookshot.
      if not hooked and not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(hookshot:get_position())
        hookshot:set_modified_ground("traversable")  -- Don't let the caught entity fall in holes.
        go_back()
      end
    end
  end)

  local hook_point_dxy = {
    {  8,  0 },
    {  0, -9 },
    { -9,  0 },
    {  0,  8 },
  }

  -- Custom collision test for hooks: there is a collision with a hook if
  -- the facing point of the hookshot overlaps the hook's bounding box.
  -- We cannot use the built-in "facing" collision mode because it would
  -- test the facing point of the hook, not the one of of the hookshot.
  -- And we cannot reverse the test because the hook is not necessarily a custom entity.
  local function test_hook_collision(hookshot, entity)
    if hooked or going_back then
      return      -- No need to check coordinates, we are already hooked.
    end

    if entity.is_hookshot_hook == nil or not entity:is_hookshot_hook() then
      return      -- Don't bother check coordinates, we don't care about this entity.
    end

    local facing_x, facing_y = hookshot:get_center_position()
    facing_x = facing_x + hook_point_dxy[direction + 1][1]
    facing_y = facing_y + hook_point_dxy[direction + 1][2]
    return entity:overlaps(facing_x, facing_y)
  end

  hookshot:add_collision_test(test_hook_collision, function(hookshot, entity)
    if hooked or going_back then
      return
    end

    if entity.is_hookshot_hook ~= nil and entity:is_hookshot_hook() then
      hook_to_entity(entity)      -- Hook to this entity.
    end
  end)

  -- Detect enemies.
  hookshot:add_collision_test("sprite", function(hookshot, entity, hookshot_sprite, enemy_sprite)
    if entity:get_type() == "enemy" then
      if hooked then
        return
      end
      local reaction = entity:get_attack_hookshot(enemy_sprite)
      entity:receive_attack_consequence("hookshot", reaction)
      go_back()
    end
  end)
  -- Start the movement.
  go()
end

function hookshot_controller:on_command_pressed(command)
  local hero = self.game:get_hero()
  if command == self.slot and not is_shot then
    avoid_return = true
	sol.audio.play_sound(self.sound_arming)
	hero:set_tunic_sprite_id(self.hero_armed_tunic)
    hero:set_walking_speed(25)
	self.game:set_value("item_hookshot_state", 2)
	avoid_return = false
  end
end

function hookshot_controller:on_key_pressed(key)
  -- if the opposite slot is the boomerang / bow / dominion rod, finish this item and start the other item.
  if key == (self.game:get_value("keyboard_item_"..self.opposite_slot_to_number) or self.game:get_value("joypad_item_"..self.opposite_slot_to_number)) and (self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "boomerang" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "bow" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "dominion_rod") and not is_shot then
	is_halted_by_anything_else = true
	is_shot = false
	self.game.is_going_to_another_item = true
	self:stop_hookshot()
	self.game:get_hero():freeze()
	self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	sol.timer.start(10, function()
	  self.game:set_command_keyboard_binding("item_"..self.opposite_slot_to_number, self.game:get_value("keyboard_item_"..self.opposite_slot_to_number))
      self.game:set_command_joypad_binding("item_"..self.opposite_slot_to_number, self.game:get_value("joypad_item_"..self.opposite_slot_to_number))
	  self.game:set_custom_command_effect("action", nil)
	  self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
	end)
  elseif key == (self.game:get_value("keyboard_attack") or self.game:get_value("joypad_attack")) and not avoid_return and not is_shot and not self.game.is_going_to_another_item then
	self.game:get_hero():freeze()
    self:stop_hookshot()
  end
end

function hookshot_controller:on_command_released(command)
  if command == self.slot and self.game:get_value("item_hookshot_state") == 2 and not is_shot then
    avoid_return = true
	is_shot = true
    self.game:get_hero():freeze()
    self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.current_tunic)
	self.game:get_hero():set_animation("hookshot_shoot")
	self:create_hookshot()
  end
end

function hookshot_controller:stop_hookshot()  
  self.game:get_hero():set_walking_speed(88)
  self.game:set_custom_command_effect("attack", nil)
  self.game:set_custom_command_effect("action", nil)
  self.game:set_value("item_hookshot_state", 0)
  self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.current_tunic)
  avoid_return = false
  is_shot = false
  retrieve_hookshot_position = false
  
  if self.current_hookshot ~= nil then
    self.current_hookshot:remove()
	self.current_hookshot = nil
  end
  if self.current_leader ~= nil then
    self.current_leader:remove()
	self.current_leader = nil
  end
  
  if (not self.game:is_current_scene_cutscene() and not ended_by_pickable and not self.game.is_going_to_another_item) then self.game:show_cutscene_bars(false) end
  if not self.game.is_going_to_another_item then self.game:get_item("hookshot"):restore_equipment() end
  
  if not is_halted_by_anything_else then
    if not from_teleporter then sol.audio.play_sound("common/item_show") end
	from_teleporter = false
	self.game:get_hero():freeze()
	self.game:get_hero():set_animation("hookshot_intro", function()
	  self.game:get_hero():unfreeze()
	  self.game:get_item("hookshot"):set_finished()
	end) 
  else
    is_halted_by_anything_else = false
	self.game:get_item("hookshot"):set_finished()
  end
  ended_by_pickable = false
  sol.menu.stop(self)
  sol.timer.stop_all(self)
end

return hookshot_controller