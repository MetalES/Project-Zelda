local hookshot_controller = {
  slot = "item_1",
  opposite_slot = "item_2",
  state = 0,
  hookshot = nil,
  leader = nil
} 

-- Set which build-in hero state can interrupt this item
local state = {"swimming", "jumping", "falling", "stairs" , "hurt", "plunging", "treasure"}
-- Set which item is compatible for the fast item switching feature
local items = {"boomerang", "bow", "dominion rod"}

local force_stop, avoid_return, is_shot, ended_by_pickable = false, false, false, false

local function set_aminations(hero)
  local prefix = {"hookshot_"}
  hero:set_fixed_animations("hookshot_stopped", "hookshot_walking")
end

function hookshot_controller:start_hookshot(game)
  self.game = game
  self.hero = game:get_hero()
  
  local hero = self.hero
  
  game:set_item_on_use(true)
  
  if hero.shield == nil then
    hero.shield = game:get_ability("shield")
    game:set_ability("shield", 0)
  end
  
  if not game.is_going_to_another_item then 
    game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
  end
   
  self.hero:set_animation("hookshot_intro", function()
    self.state = 1
    hero:set_walking_speed(40)
	hero:set_fixed_direction(hero:get_direction())
	set_aminations(hero)
	hero:unfreeze()
	game.is_going_to_another_item = false 
	game:set_custom_command_effect("attack", "return")
	sol.menu.start(game:get_map(), self)	
  end)

  sol.audio.play_sound("common/item_show")
  self:check() 
end

function hookshot_controller:check()
  local hero = self.hero
  
  local function end_by_collision() 
    local state = hero:get_state()
    force_stop = true
    if state == "treasure" then ended_by_pickable = true end
	if state == "stairs" then
	  hero:restore_state_stairs()
	end
	sol.menu.stop(hookshot_controller)
  end
  
  sol.timer.start(self, 10, function()
    local item_name = self.game:get_item_assigned(2) or nil
    local item_opposite = item_name ~= nil and item_name:get_name() or nil
    local item = item_opposite == "hookshot" or nil
	
	for _, state in ipairs(state) do
	  if hero:get_state() == state and hero:get_animation() ~= "hookshot_tracting" then
		hero:cancel_direction_fix()
		end_by_collision() 
		return
	  end
	end
	
	-- Check if the item has changed
	self.slot = item and "item_2" or "item_1"
	self.opposite_slot = item and "item_1" or "item_2"
	
	if not self.game:is_suspended() then
	  local assigned_1 = self.game:get_item_assigned(1) ~= nil and self.game:get_item_assigned(1):get_name() or nil 
	  local assigned_2 = self.game:get_item_assigned(2) ~= nil and self.game:get_item_assigned(2):get_name() or nil
	  
	  if self.hookshot == nil then
	    if (assigned_1 == nil or assigned_1 ~= "hookshot") and (assigned_2 == nil or assigned_2 ~= "hookshot") then  
	      sol.menu.stop(self)
	      return
	    end
	  end
	  
	  if not self.game:is_command_pressed(self.slot) and self.state == 2 and not is_shot then 
	    self.game:simulate_command_released(self.slot) 
	  end
	end

    return true
  end)
end

function hookshot_controller:create_hookshot()
  local map = self.game:get_map()
  local hero = self.hero
  local x, y, layer = hero:get_position()
  local going_back, hooked = false, false
  local direction = hero:get_direction()
  local entities_caught = {}
  local orig_correct, entities_finaly, hook_x, hook_y = 0, 0, 0, 0
  local correct_trajectory = 5
  local hookshot_sprite, link_sprite, hookshot, leader, hooked_entity, go, stop, go_back
  
  if hero:get_direction() == 0 then hook_x = 10; hook_y = -1;
  elseif hero:get_direction() == 1 then hook_y = -10; orig_correct = 1; entities_finaly = 8; correct_trajectory = 6
  elseif hero:get_direction() == 2 then hook_x = -10; hook_y = -1
  else correct_trajectory = 0
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

  local function test_hero_obstacle_layers(candidate_x, candidate_y, candidate_layer)
    local hero_x, hero_y, hero_layer = hero:get_position()
    candidate_layer = candidate_layer or hero_layer
    if hero:test_obstacles(candidate_x - hero_x, candidate_y - hero_y, candidate_layer) then
      return true
    end

    if candidate_layer == 0 then
      return false
    end

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
      sol.audio.play_sound("items/hookshot/firing_loop")
      return is_shot
    end)
    sol.audio.play_sound("items/hookshot/firing_start")
  
    local go_movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    go_movement:set_speed(204)
    go_movement:set_angle(angle)
    go_movement:set_smooth(false)
    go_movement:set_max_distance(182)
    go_movement:start(hookshot)

    function go_movement:on_obstacle_reached()
	  local hookshot_sprite_x, hookshot_sprite_y = hookshot:get_position()	  
	  map:create_collision(hookshot_sprite_x + hook_x, hookshot_sprite_y + hook_y, layer)
      go_back()
    end

    function go_movement:on_finished()
      go_back()
    end
  end

  -- Makes the hookshot come back to the hero.
  function go_back()
    if going_back then
      return
    end
	 
    local movement = sol.movement.create("straight")
    movement:set_speed(204)
    movement:set_angle((direction + 2) * math.pi / 2)
    movement:set_smooth(false)
    movement:set_max_distance(hookshot:get_distance(hero))
    movement:set_ignore_obstacles(true)
    movement:start(hookshot)
	
    going_back = true

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
	hero:cancel_direction_fix()
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
	
	hookshot_controller.leader = leader

    local movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    movement:set_speed(204)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(hookshot:get_distance(hero) - correct_trajectory)
    movement:start(leader)

    hero:start_jumping(0, 100, true)
    hero:get_movement():stop()
    hero:set_animation("hookshot_tracting")
    hero:set_direction(direction)
	sol.audio.play_sound("items/hookshot/hit_valid_target")
	sol.audio.play_sound("items/hookshot/link_tracted")

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

  -- Restores control to the player, the hero isn't tracted.
  function stop()
    avoid_return = false
	is_shot = false
	
	local hx, hy, hz = hookshot:get_position()
	  for _, entity in ipairs(entities_caught) do
        entity:set_position(hx, hy + entities_finaly, hz)
      end
	  
	hero:set_fixed_direction(hero:get_direction())
	set_aminations(hero)
	
	if hero:get_state() ~= "treasure" then
	  hero:unfreeze()
	end
	
    if hookshot ~= nil then
      hookshot:remove()
	  hookshot_controller.hookshot = nil
    end
	
    if leader ~= nil then
      leader:remove()
	  hookshot_controller.leader = nil
    end
	
	hero:set_walking_speed(40)
	self.state = 1
  end
  
  -- Destroys the hookshot and restores control to the player, the hero is tracted.
  function stop_tracted()
	sol.menu.stop(hookshot_controller)
  end
  
  -- Create the hookshot.
  hookshot = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x + hook_x,
    y = y + hook_y,
    width = 16,
    height = 16,
  })
  hookshot:set_origin(8, 12) --5
  hookshot:set_drawn_in_y_order(true)
  
  hookshot_controller.hookshot = hookshot

  -- Set up hookshot sprites.
  hookshot_sprite = hookshot:create_sprite("entities/item_hookshot")
  hookshot_sprite:set_direction(direction)
  link_sprite = sol.sprite.create("entities/item_hookshot")
  link_sprite:set_animation("link")
  link_sprite:set_direction(direction)

  function hookshot:on_pre_draw()
    -- Draw the links.
    local num_links = 22
    local dxy = {
      {  16,  -6 },
      {   0, -14 },
      { -15,  -6 },
      {   0,   5 }
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
        map:draw_visual(link_sprite, link_x, link_y)
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
      local sprite = entity:get_sprite()
      if not hooked and
          not going_back and
          sprite ~= nil and
          sprite:get_animation_set() == "entities/solid_switch" then
        if entity:is_activated() then
          sol.audio.play_sound("sword_tapping")
        else
          sol.audio.play_sound("switch")
          entity:set_activated(true)
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

  local function test_hook_collision(hookshot, entity)
    if hooked or going_back then
      return -- No need to check coordinates, we are already hooked.
    end

    if entity.is_hookshot_hook == nil or not entity:is_hookshot_hook() then
      return -- Don't bother check coordinates, we don't care about this entity.
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
  local hero = self.hero
  local game = self.game
  
  local suspended = game:is_suspended()
  local another_item = game.is_going_to_another_item
  local opposite = self.opposite_slot:sub(6, 7)
  local item_name = game:get_item_assigned(opposite) or nil
  local state = self.state
  local item_opposite = item_name ~= nil and item_name:get_name() or nil
  
  if command == "pause" then
    return false
  end
  
  if not suspended then
    if command == self.slot and not is_shot then
      avoid_return = true
	  sol.audio.play_sound("items/hookshot/arming")
	  hero:set_walking_speed(25)
	  hero:get_sprite("tunic"):set_frame_delay(150)
	  self.state = 2
	  hero:unfreeze()
	  avoid_return = false
	  
	elseif command == "attack" and not avoid_return and not is_shot and not another_item  then
      sol.menu.stop(self)
	  
	elseif command == "item_" .. opposite and item_opposite ~= nil then
	  for _, item in ipairs(items) do
	    if item_opposite == item and not is_shot then
	      hero:freeze()
	      game.is_going_to_another_item = true
		  force_stop = true
		  sol.menu.stop(self)
		  
		  game:get_item(item_opposite):set_state(0)
	      game:get_item(item_opposite):on_using()
	      game:set_custom_command_effect("action", nil)
	    end
	  end
	
    end
  end

  return true
end

function hookshot_controller:on_command_released(command)
  if command == self.slot and self.state == 2 and not is_shot and not self.game:is_suspended() then
    avoid_return = true
	is_shot = true
    self.hero:freeze()
	self.hero:set_animation("hookshot_shoot")
	self:create_hookshot()  
  end
end

function hookshot_controller:on_finished()
  local game = self.game
  local hero = self.hero  
  
  game:set_ability("shield", hero.shield)
  hero.shield = nil
  
  game:set_item_on_use(false)
  
  hero:set_walking_speed(88)
  game:set_custom_command_effect("attack", nil)
  self.state = 0
  
  if self.hookshot ~= nil then
    self.hookshot:remove()
	self.hookshot = nil
  end
  
  if self.leader ~= nil then
    self.leader:remove()
	self.leader = nil
  end
  
  if (not game:is_current_scene_cutscene() and not ended_by_pickable and not game.is_going_to_another_item) then game:show_cutscene_bars(false) end
  
  if not force_stop then
    sol.audio.play_sound("common/item_show")
	hero:freeze()
	hero:set_animation("hookshot_intro", function()
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
  avoid_return = false
  is_shot = false
  ended_by_pickable = false
  
  hero:cancel_direction_fix()
 
  if game.is_using_lantern then
    hero:set_fixed_animations("lantern_stopped", "lantern_walking")
  end
  
  sol.timer.stop_all(self)
end

return hookshot_controller