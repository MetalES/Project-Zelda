local fish_rod_controller = {
  slot = "item_1",
  state = 0
}

local forced_stop, avoid_return, is_shot, ended_by_pickable, is_dowsing, has_finished_movement, need_trail_update = false
local directions = {[1] = "right";[2] = "up"; [3] = "left"; [4] = "down"}
local state = {"falling", "hurt"}

local fishing_rod_sprite
local fishing_rod
local check_ground_timer
local bait_trail 
local timer
local shadow
local water_effect

function fish_rod_controller:start_fishing_rod(game)
  self.game = game
  self.hero = game:get_hero()
  self.map = game:get_map()
  self.camera = self.map:get_camera()
  
  game:set_item_on_use(true)
  
  self.dowsed_distance = 50
  self.charging_time = 0
  
  sol.menu.start(self.map, self)
  
  game:simulate_command_pressed(self.slot)
  
  self:check() 
end

function fish_rod_controller:check()
  local hero = self.hero
  
  local function end_by_collision() 
    local state = hero:get_state()
    force_stop = true
    if state == "treasure" then ended_by_pickable = true end
	sol.menu.stop(fish_rod_controller)
  end
  
  sol.timer.start(self, 50, function()
    local item_name = self.game:get_item_assigned(2) or nil
    local item_opposite = item_name ~= nil and item_name:get_name() or nil
    local item = item_opposite == "fishing_rod" or nil
	
	for _, state in ipairs(state) do
	  if hero:get_state() == state then
		end_by_collision() 
		return
	  end
	end
	
	-- Check if the item has changed
	self.slot = item and "item_2" or "item_1"
	
	if not self.game:is_suspended() then
	  local assigned_1 = self.game:get_item_assigned(1) ~= nil and self.game:get_item_assigned(1):get_name() or nil 
	  local assigned_2 = self.game:get_item_assigned(2) ~= nil and self.game:get_item_assigned(2):get_name() or nil
	  
	  if fishing_rod == nil then
	    if (assigned_1 == nil or assigned_1 ~= "fishing_rod") and (assigned_2 == nil or assigned_2 ~= "fishing_rod") then  
	      sol.menu.stop(self)
	      return
	    end
	  end
	  
	  if not self.game:is_command_pressed(self.slot) and not is_shot then 
	    self.game:simulate_command_released(self.slot) 
	  end
	end
    
  return true
  end)
end

function fish_rod_controller:create_fishing_rod()
  local script = self
  local map = self.map
  local hero = self.hero
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()  
  local go, stop

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

  -- Starts the fishing_rod movement from the hero.
  function go()
    sol.audio.play_sound("items/fishing_rod/start_swing")
    sol.audio.play_sound("items/fishing_rod/throwing")
  
    script:shift_fish_rod_sprite()
    local m = sol.movement.create("straight")
    m:set_speed(100)
	m:set_angle(direction * math.pi / 2)
    m:set_max_distance(script.dowsed_distance)
    m:start(fishing_rod)

    function m:on_obstacle_reached()
	  local _, fy = fishing_rod:get_sprite():get_xy()
	  if fy == 0 and not has_finished_movement then
		if shadow ~= nil then fishing_rod:remove_sprite(shadow) shadow = nil end
		sol.timer.stop_all(self)
	    script:check_ground()
		script.item_landed = true
		script.can_control = true
		hero:set_animation("fishing_rod_calm")
		if script.map:get_ground(fishing_rod:get_position()) ~= "deep_water" then sol.audio.play_sound("items/fishing_rod/land_on_solid_ground") end
		has_finished_movement = true
	  end
    end

    function m:on_finished()
	  script.item_landed = true
	  script.can_control = true
	  if shadow ~= nil then fishing_rod:remove_sprite(shadow) shadow = nil end
	  script:check_ground()
	  hero:set_animation("fishing_rod_calm")
	  if script.map:get_ground(fishing_rod:get_position()) ~= "deep_water" then sol.audio.play_sound("items/fishing_rod/land_on_solid_ground") end
    end
  end
  
  function stop()
    avoid_return = false
	is_shot = false
	
	check_ground_timer:stop()
	hero:unfreeze()
	
    if fishing_rod ~= nil then
      fishing_rod:remove()
    end

	sol.menu.stop(script)
  end

  -- Create the fishing rod.
  fishing_rod = map:create_custom_entity({
    direction = 0,
    layer = layer,
    x = x,
    y = y,
    width = 16,
    height = 16,
	sprite = "entities/fishing_rod"
  })
  fishing_rod:set_origin(8, 12)
  fishing_rod:set_drawn_in_y_order(true)
  fishing_rod:set_direction(direction)
  shadow = fishing_rod:create_sprite("entities/shadow")
  
  -- Set up collisions.
  fishing_rod:add_collision_test("overlapping", function(hookshot, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop fishing.
      if script.item_landed then
	    self.camera:start_tracking(hero)
		sol.timer.start(1, function()
		  if self:is_bait_trail_active() then self:stop_trail() end
		end)
		script.item_landed = false
        stop()
      end
    elseif entity.is_fishable ~= nil and entity:is_fishable() then
      -- Catch the entity with the hookshot.
      if not hooked and not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(fishing_rod:get_position())
        go_back()
      end
    end
  end)

  -- Set what can be traversed by the fishing_rod.
  set_can_traverse_rules(fishing_rod)

  -- Start the movement.
  go()
end

function fish_rod_controller:start_trail_on_bait()
  bait_trail = sol.timer.start(self, 50, function()
    local lx, ly, llayer = fishing_rod:get_position()
    local trail = self.map:create_custom_entity({
	  x = lx,
	  y = ly,
	  layer = llayer,
	  width = 8,
	  height = 16,
  	  direction = (self.game:get_hero():get_direction() + 2) % 4,
	  sprite = "effects/hero/swimming_trails",
    })
    trail:get_sprite():fade_out(12, function() trail:remove() end)
    return self.map:get_ground(fishing_rod:get_position()) == "deep_water"
  end)
  bait_trail:set_suspended_with_map(true)
end

function fish_rod_controller:is_bait_trail_active()
  return bait_trail ~= nil and bait_trail:get_remaining_time() ~= 0
end

function fish_rod_controller:stop_trail()
  bait_trail:stop()
  bait_trail = nil
end

function fish_rod_controller:check_ground()
  local need_update = true
 
  check_ground_timer = sol.timer.start(self, 20, function()
    local x, y, z  = fishing_rod:get_position()
	
	if self.game:is_command_pressed("action") and self.can_control then
   	  if not need_trail_update then
  	    if self.map:get_ground(fishing_rod:get_position()) == "deep_water" then
	      if not self:is_bait_trail_active() then self:start_trail_on_bait() end
	      need_trail_update = true
		end
		self:on_command_pressed("action")
		need_trail_update = true
	  end
    end
	  
    if self.map:get_ground(fishing_rod:get_position()) == "deep_water" and need_update then
	  need_update = false
      local water_splash = self.map:create_custom_entity({x = x, y = y, layer = z, width = 16, height = 16, direction = 0})    
      local sprite = water_splash:create_sprite("entities/carried_ground_effect")
      sprite:set_animation("deep_water")

	  function water_splash:on_animation_finished() water_splash:remove() end
	  if not self:is_bait_trail_active() and self.game:is_command_pressed("action") then self:start_trail_on_bait() end
	  
	  fishing_rod:get_sprite():set_animation("in_water")
	  sol.audio.play_sound("items/fishing_rod/splash_in_water"..math.random(0, 1))
	  water_effect = fishing_rod:create_sprite("entities/misc/item/fishing_rod/water_effect")
	else
	  if self.map:get_ground(fishing_rod:get_position()) ~= "deep_water" then
		if water_effect ~= nil then fishing_rod:remove_sprite(water_effect) water_effect = nil end
	    fishing_rod:get_sprite():set_animation("plug_thrown")
		if self:is_bait_trail_active() then self:stop_trail() end
		need_update = true
	  end
	end
	return true
  end)
  check_ground_timer:set_suspended_with_map(true)
end

function fish_rod_controller:dowse()
  local game = self.game
  self.dowsed_distance = self.dowsed_distance + 2
  
  sol.timer.start(self, 1, function()
	if game:is_command_pressed(self.slot) and not game:is_suspended() and is_dowsing then self:dowse() end
  end)
end

function fish_rod_controller:shift_fish_rod_sprite()
  local duration = self.dowsed_distance -- relative speed of the rod when casting it. 
  local max_height = math.floor(-self.dowsed_distance / 5)
  
  local function f(t)
    return math.floor(4 * max_height * (t / duration - (t / duration) ^ 2))
  end
  
  local t = 0
  sol.timer.start(self, 10, function()
    fishing_rod:get_sprite():set_xy(0, f(t))
    t = t + 1
    if t > duration then return false 
      else return true 
    end
  end)
end

function fish_rod_controller:on_command_released(command)

  if command == "action" and not self.game:is_suspended() and self.item_landed and self.can_control then
    sol.timer.start(50, function()
      if self:is_bait_trail_active() then self:stop_trail() end
	end)
	need_trail_update = false
  end

end

function fish_rod_controller:on_command_pressed(command)
  local game = self.game
  local suspended = game:is_suspended()
  local hero = game:get_hero()
  local x, y = hero:get_position()
  local direction = hero:get_direction()
  
  local final_bx, final_by
  
  local function align_bait_to_hero()
    local bx, by = fishing_rod:get_position()
	if direction == 0 or direction == 2 then -- Left or Right
	  final_bx = direction == 0 and bx - 1 or bx + 1
	  
	  if by ~= y then
	    final_by = by > y and by - 1 or by + 1
	  else
	    final_by = by
	  end
	  
	elseif direction == 1 or direction == 3 then -- Up or Down
	  final_by = direction == 1 and by + 1 or by - 1
	  
	  if bx ~= x then
	    final_bx = bx > x and bx - 1 or bx + 1
	  else
	    final_bx = bx
	  end
	
	end
  return final_bx, final_by	  
  end
  
  local function shift_bait_by_direction_input()
	local bx, by = fishing_rod:get_position()
	
	local rand0 = math.random(5, 11)
	local rand1 = math.random(8, 24)
	local rand2 = math.random(-5, 5)
	
	if direction == 0 or direction == 2 then
	  final_bx = direction == 0 and bx - rand0 or bx + rand0
	  
	  if by ~= y then
	    final_by = by > y and by - rand1 or by + rand1
	  else
	    final_by = by + rand2
	  end

	elseif direction == 1 or direction == 3 then
	  final_by = direction == 1 and by + rand0 or by - rand0
	  
	  if bx ~= x then
	    final_bx = bx > x and bx - rand1 or bx + rand1
	  else
	    final_bx = bx + rand2
	  end
	end
	
  return final_bx, final_by
  end
  
  if command == "pause" then
    return false
  end
  
  if not suspended then
    if command == self.slot and not is_shot and not is_dowsing then
      self.dowsed_distance = 50
      avoid_return, is_dowsing = true, true
	  water_effect = nil
	  need_trail_update, has_finished_movement = false, false
	
	  self:dowse()
	
      hero:freeze()
	  
	  hero:set_animation("fishing_rod_casting_0", function()
	    hero:get_sprite():set_frame(1)
	    sol.timer.start(self, 200, function()
	      hero:set_animation("fishing_rod_casting_1", function()
		    is_dowsing = false
		    self:create_fishing_rod() 
		    self.camera:start_tracking(fishing_rod)
		    is_shot = true
	        hero:set_animation("fishing_rod_casting_2")
	      end)
	    end)
	  end)
	  avoid_return = false
	
    elseif command == "action" and self.item_landed and self.can_control then
      local speed = game:is_command_pressed(directions[(1 - direction - 1) % 3]) and 60 or 40
	  fishing_rod:set_direction((2 + direction) % 3)
	  
	  local t = sol.movement.create("target")
	  t:set_target(align_bait_to_hero())
	  t:set_speed(speed)
	  t:set_ignore_obstacles(true)
	  t:start(fishing_rod, function()
	    if game:is_command_pressed("action") and self.item_landed then game:simulate_command_pressed("action") end
	  end)
	
	  sol.audio.play_sound("items/fishing_rod/reel" .. speed)
    end
  
  
    for int, dir in ipairs(directions) do
	
	  if command == dir and self.item_landed then
	    local fix_dir = (direction == 0 or direction == 2) and direction or 1
	    
		print((int - 2) % 4)
		-- directions[(direction - 1) % 4] The opposite direction
		
	    if (int == direction or int == fix_dir) and self.can_control then  -- a side direction has been pressed
		  print("test")
		end
	  end
	  
	end
	
	-- if command == dir and self.item_landed then 
	  -- local fix_dir = 10
	  
	  -- if direction == 0 or direction == 2 then -- Left or right
	    -- fix_dir = direction % 4
	  -- end
	  
	  -- if (int == fix_dir % 4 or int == fix_dir) and self.can_control then
	    -- if self:is_bait_trail_active() then self:stop_trail() end
		-- sol.timer.start(50, function() self:start_trail_on_bait() end)
		-- self.can_control = false
		
		-- local t = sol.movement.create("target")
	    -- t:set_target(shift_bait_by_direction_input())
		-- t:set_speed(math.random(60, 70))
		-- t:start(fishing_rod, function()
		  -- sol.timer.start(50, function()
		    -- self.can_control = true
			-- if self:is_bait_trail_active() then self:stop_trail() end
		  -- end)
		-- end)
		
		-- if self.map:get_ground(fishing_rod:get_position()) == "deep_water" then
		  -- sol.audio.play_sound("items/fishing_rod/move_bait_on_water")
		-- end
		
		-- function t:on_obstacle_reached()
		  -- fish_rod_controller.can_control = true
		  -- if self:is_bait_trail_active() then self:stop_trail() end
		-- end
		
	  -- end
	-- end
	
    -- print(int, dir)
    -- if command == dir and self.item_landed then
	  -- local fix_dir 
	  
	  -- if hero:get_direction() == 1 then
	    -- fix_dir = 1
	  -- elseif hero:get_direction() == 3 then
	    -- fix_dir = 1
	  -- else
	    -- fix_dir = (hero:get_direction() + 1) % 4
	  -- end
	  
	  -- if (int == (hero:get_direction()) % 4 or int == fix_dir) and self.can_control then  -- a side direction has been pressed

	end
	  
	  ----------------------------------------------
	  
	  
	    -- if self:is_bait_trail_active() then self:stop_trail() end
	    -- sol.timer.start(50, function() self:start_trail_on_bait() end)
		-- self.can_control = false
		
		-- local t = sol.movement.create("target")
	    -- t:set_target(shift_bait_by_direction_input())
		-- t:set_speed(math.random(60, 70))
		-- t:start(fishing_rod, function()
		  -- sol.timer.start(50, function()
		    -- self.can_control = true
			-- if self:is_bait_trail_active() then self:stop_trail() end
		  -- end)
		-- end)
		
		-- if self.map:get_ground(fishing_rod:get_position()) == "deep_water" then
		  -- sol.audio.play_sound("items/fishing_rod/move_bait_on_water")
		-- end
		
		-- function t:on_obstacle_reached()
		  -- fish_rod_controller.can_control = true
		  -- if self:is_bait_trail_active() then self:stop_trail() end
		-- end
	  -- end
	-- end
  -- end
  
  -- if command == self.slot and not is_shot and not is_dowsing and not self.game:is_suspended() then
    -- self.dowsed_distance = 50
    -- avoid_return = true
    -- is_dowsing = true
	-- water_effect = nil
	-- need_trail_update = false
	-- has_finished_movement = false
	
	-- self:dowse()
	
    -- hero:freeze()
    -- hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	-- hero:set_animation("fishing_rod_casting_0", function()
	  -- hero:get_sprite():set_frame(1)
	  -- sol.timer.start(self, 200, function()
	    -- hero:set_animation("fishing_rod_casting_1", function()
		  -- is_dowsing = false
		  -- self:create_fishing_rod() 
		  -- self.camera:start_tracking(fishing_rod)
		  -- is_shot = true
	      -- hero:set_animation("fishing_rod_casting_2")
	    -- end)
	  -- end)
	-- end)
	-- self.game:set_value("item_fishing_rod_state", 2)
	-- avoid_return = false
	
  -- elseif command == "pause" then
    -- return false

  -- elseif command == "action" and self.item_landed and self.can_control then
    -- local speed = 40
    -- if self.game:is_command_pressed(directions[1 + ((hero:get_direction() + 2) % 4)]) then speed = 60 end -- todo
	-- fishing_rod:set_direction((self.game:get_hero():get_direction() + 2) % 4)
	
	-- local t = sol.movement.create("target")
	-- t:set_target(align_bait_to_hero())
	-- t:set_speed(speed)
	-- t:set_ignore_obstacles(true)
	-- t:start(fishing_rod, function()
	  -- if self.game:is_command_pressed("action") and self.item_landed then self.game:simulate_command_pressed("action") end
	-- end)
	
	-- sol.audio.play_sound("items/fishing_rod/reel"..speed)
  -- end
  return true
end

function fish_rod_controller:on_finished()
  local game = self.game
  local hero = self.hero

  game:set_custom_command_effect("action", nil)
  game:set_item_on_use(false)
  
  avoid_return = false
  is_shot = false
  
  sol.audio.play_sound("common/item_show")
  ended_by_pickable = false
  
  game:get_item("fishing_rod"):set_finished()
  sol.timer.stop_all(self)
end

return fish_rod_controller