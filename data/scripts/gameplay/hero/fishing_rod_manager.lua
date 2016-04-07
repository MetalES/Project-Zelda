local fish_rod_controller = {}
-- Initialize item related thing, these values are loaded when the game creates the item.
-- Sound is already preloaded so it is useless to store these here.
fish_rod_controller.slot  = "item_1"; -- Identifier that get the Item Slot
fish_rod_controller.opposite_slot  = "item_2"; -- Identifier that get the opposite slot
fish_rod_controller.opposite_slot_to_number  = 2; -- Integer that get the opposite slot
fish_rod_controller.wire_sprite = "entities/fishing_rod"; -- Item : The Rod's wire
fish_rod_controller.plug_sprite = "entities/fishing_rod"; -- Item : fishing_rod's bait
fish_rod_controller.hero_free_tunic = "";  -- used to store the hero sprite id when he is free, useful if he change tunic
fish_rod_controller.hero_armed_tunic = "";  -- used to store the hero sprite id when he pressed an input, useful if he change tunic
fish_rod_controller.new_x = 0; -- X Warp position in real time when the ground is not solid depending on Hero's Direction
fish_rod_controller.new_y = 0; -- Y Warp position in real time when the ground is not solid depending on Hero's Direction
fish_rod_controller.gx = 0; -- Ground X, the ground surrouding the hero
fish_rod_controller.gy = 0; -- Ground Y, the ground surrouding the hero
fish_rod_controller.lx = 0; -- Link X : Player X Position in the World in real time
fish_rod_controller.ly = 0; -- Link Y : Player Y Position in the World in real time
fish_rod_controller.llayer = 0; -- Link Layer : Player Z (Layer) Position in the World in real time
fish_rod_controller.current_plug = nil   -- The current leader entity

local is_halted_by_anything_else = false
local avoid_return = false
local from_teleporter = false
local is_shot = false
local ended_by_pickable = false
local is_dowsing = false
local has_finished_movement = false
local need_trail_update = false

local direction = {[1] = "right";[2] = "up"; [3] = "left"; [4] = "down"}

local fishing_rod_sprite
local link_sprite
local fishing_rod
local check_ground_timer
local bait_trail 
local timer
local shadow
local water_effect

function fish_rod_controller:start_fishing_rod(game)
  self.game = game
  self.map = game:get_map()
  self.camera = self.map:get_camera()
  self.game:set_item_on_use(true)
  
  self.dowsed_distance = 50
  self.charging_time = 0
  
  if not self.game.is_going_to_another_item then 
    self.game:set_value("current_shield", self.game:get_ability("shield"))
    self.game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
	self.game:set_ability("shield", 0)
	self.game:get_hero():set_shield_sprite_id("hero/shield_item")
  end
   
   
  -- self.game:get_hero():set_animation("fishing_rod_intro", function()
    -- self.game:set_value("item_fishing_rod_state", 1)
    -- self.game:get_hero():unfreeze()
    -- self.game:get_hero():set_tunic_sprite_id(self.hero_free_tunic)
	-- self.game.is_going_to_another_item = false 
	self.game:set_custom_command_effect("attack", "return")
	sol.menu.start(self.game:get_map(), self)	
  -- end)

  for teleporter in self.game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  avoid_return = true
	  from_teleporter = true
	  self.game:set_value("item_fishing_rod_state", 0)
	  self.game:get_hero():freeze()
	  self:stop_fishing_rod()
	end
  end
  sol.audio.play_sound("common/item_show")
  
  self:start_ground_check() 
end

function fish_rod_controller:start_ground_check()
  local hero = self.game:get_hero()
  
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
    is_halted_by_anything_else = true
	if hero:get_state() == "hurt" then hero:set_invincible(true, 1000) hero:set_blinking(true, 1000) end
	fish_rod_controller:stop_fishing_rod()
  end
  
  timer = sol.timer.start(self, 50, function()
	self.lx, self.ly, self.llayer = self.game:get_hero():get_position()
	
	-- todo hero:on_direction changed will change all of this. It would be not timer dependant.
	if hero:get_direction() == 0 then self.new_x = -1; self.new_y = 0; self.gx = 1; self.gy = 0
	elseif hero:get_direction() == 1 then self.new_x = 0; self.new_y = 1 ; self.gy = -1;  self.gx = 0
	elseif hero:get_direction() == 2 then self.new_x = 1; self.new_y = 0 ; self.gy = 0;  self.gx = -1
	elseif hero:get_direction() == 3 then self.new_x = 0; self.new_y = -1; self.gy = 1;  self.gx = 0
	end

	if hero:get_state() == "swimming" or (hero:get_state() == "jumping" and not is_shot) then hero:set_position(self.lx + self.new_x, self.ly + self.new_y); end_by_collision() end
	if hero:get_state() == "falling" or hero:get_state() == "stairs" or hero:get_animation() == "swimming_stopped" or hero:get_state() == "hurt" or self.game:get_map():get_ground(self.lx + self.gx, self.ly + self.gy, self.llayer) == "lava" or hero:get_state() == "treasure" then end_by_collision() end

	
	if self.game:get_value("_item_slot_1") ~= "fishing_rod" and self.game:get_value("_item_slot_2") ~= "fishing_rod" then 
	  if self.current_fishing_rod == nil then
	    self:stop_fishing_rod()
	  end
    end
	
	-- check if the item has changed
	if self.game:get_value("_item_slot_2") == "fishing_rod" then 
      self.slot = "item_2" 
	  self.opposite_slot = "item_1"
      self.opposite_slot_to_number = 1
    else
      self.slot = "item_1" 
	  self.opposite_slot = "item_2"
      self.opposite_slot_to_number = 2
    end

    -- self.hero_free_tunic = "hero/item/fishing_rod/fishing_rod_moving_free_tunic"..self.game:get_ability("tunic")
    -- self.hero_armed_tunic = "hero/item/fishing_rod/fishing_rod_moving_concentrate_tunic"..self.game:get_ability("tunic")
	
    -- if self.game.has_changed_tunic and self.game:is_command_pressed(self.slot) and  self.game:get_value("item_fishing_rod_state") == 2 then hero:set_tunic_sprite_id(self.hero_armed_tunic) self.game.has_changed_tunic = false end
	-- if self.game.has_changed_tunic and not self.game:is_command_pressed(self.slot) then self.game.has_changed_tunic = false hero:set_tunic_sprite_id(self.hero_free_tunic) end
	-- if not self.game:is_command_pressed(self.slot) and self.game:get_value("item_fishing_rod_state") == 2 and not is_shot then self.game:simulate_command_released(self.slot) end
	
  return true
  end)
  timer:set_suspended_with_map(true)
end

function fish_rod_controller:create_fishing_rod()
  local map = self.map
  local hero = self.game:get_hero()
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  local go
  local stop

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
  
    fish_rod_controller:shift_fish_rod_sprite()
    local m = sol.movement.create("straight")
    m:set_speed(100)
	m:set_angle(direction * math.pi / 2)
    m:set_max_distance(fish_rod_controller.dowsed_distance)
    m:start(fishing_rod)

    function m:on_obstacle_reached()
	  local _, fy = fishing_rod:get_sprite():get_xy()
	  if fy == 0 and not has_finished_movement then
		if shadow ~= nil then fishing_rod:remove_sprite(shadow) shadow = nil end
		sol.timer.stop_all(self)
	    fish_rod_controller:check_ground()
		fish_rod_controller.item_landed = true
		fish_rod_controller.can_control = true
		hero:set_animation("fishing_rod_calm")
		if fish_rod_controller.map:get_ground(fishing_rod:get_position()) ~= "deep_water" then sol.audio.play_sound("items/fishing_rod/land_on_solid_ground") end
		has_finished_movement = true
	  end
    end

    function m:on_finished()
	  fish_rod_controller.item_landed = true
	  fish_rod_controller.can_control = true
	  if shadow ~= nil then fishing_rod:remove_sprite(shadow) shadow = nil end
	  fish_rod_controller:check_ground()
	  hero:set_animation("fishing_rod_calm")
	  if fish_rod_controller.map:get_ground(fishing_rod:get_position()) ~= "deep_water" then sol.audio.play_sound("items/fishing_rod/land_on_solid_ground") end
    end
  end
  
  function stop()
    avoid_return = false
	is_shot = false
	local hx, hy, hz = fishing_rod:get_position()
	check_ground_timer:stop()
	hero:unfreeze()
    if fishing_rod ~= nil then
      fishing_rod:remove()
    end
    if link_sprite ~= nil then
      link_sprite:remove()
    end
	self.game:set_value("item_fishing_rod_state", 1)
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
      if fish_rod_controller.item_landed then
	    self.camera:start_tracking(hero)
		sol.timer.start(1, function()
		  if self:is_bait_trail_active() then self:stop_trail() end
		end)
		fish_rod_controller.item_landed = false
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
      local water_splash = self.map:create_custom_entity({x = x, y = y, layer = z, direction = 0})    
      local sprite = water_splash:create_sprite("entities/carried_ground_effect")
      sprite:set_animation("water")

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
	if self.game:is_command_pressed(self.slot) and not self.game:is_suspended() and is_dowsing then self:dowse() end
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
  local hero = self.game:get_hero()
  local x, y = hero:get_position()
  local final_bx, final_by
  
  local function align_bait_to_hero()
    local bx, by = fishing_rod:get_position()
	local direction = hero:get_direction()
	if direction == 0 then
	  final_bx = bx - 1
	  if by > y then
	    final_by = by - 1
	  elseif by < y then
	    final_by = by + 1
	  else
		final_by = by
	  end
	elseif direction == 1 then
	  final_by = by + 1
	  if bx > x then
		final_bx = bx - 1
	  elseif bx < x then
		final_bx = bx + 1
	  else
		final_bx = bx
	  end
	elseif direction == 2 then
	  final_bx = bx + 1
	  if by > y then
		final_by = by - 1
	  elseif by < y then
		final_by = by + 1
	  else
	    final_by = by
	  end
	else
	  final_by = by - 1
	  if bx > x then
		final_bx = bx - 1
	  elseif bx < x then
	    final_bx = bx + 1
	  else
		final_bx = bx
	  end
	end
  return final_bx, final_by	  
  end
  
  local function shift_bait_by_direction_input()
    local direction = hero:get_direction()
	local bx, by = fishing_rod:get_position()
	
	if direction == 0 then -- >
	  final_bx = bx - math.random(5, 11)
	  if by > y then
	    final_by = by - math.random(8, 24)
	  elseif by < y then
	    final_by = by + math.random(8, 24)
	  else
		final_by = by + math.random(-5, 5)
	  end
	elseif direction == 1 then -- ^
	  final_by = by + math.random(5, 11)
	  if bx > x then
		final_bx = bx - math.random(8, 24)
	  elseif bx < x then
		final_bx = bx + math.random(8, 24)
	  else
		final_bx = bx + math.random(-5, 5)
	  end
	elseif direction == 2 then
	  final_bx = bx + math.random(5, 11)
	  if by > y then
		final_by = by - math.random(8, 24)
	  elseif by < y then
		final_by = by + math.random(8, 24)
	  else
	    final_by = by + math.random(-5, 5)
	  end
	else
	  final_by = by - math.random(5, 11)
	  if bx > x then
		final_bx = bx - math.random(8, 24)
	  elseif bx < x then
	    final_bx = bx + math.random(8, 24)
	  else
		final_bx = bx + math.random(-5, 5)
	  end
	end
  return final_bx, final_by
  end
  
  for int, dir in ipairs(direction) do
    print(int, dir)
    if command == dir and self.item_landed then
	  local fix_dir 
	  
	  if hero:get_direction() == 1 then
	    fix_dir = 1
	  elseif hero:get_direction() == 3 then
	    fix_dir = 1
	  else
	    fix_dir = (hero:get_direction() + 1) % 4
	  end
	  
	  if (int == (hero:get_direction()) % 4 or int == fix_dir) and self.can_control then  -- a side direction has been pressed

	    if self:is_bait_trail_active() then self:stop_trail() end
	    sol.timer.start(50, function() self:start_trail_on_bait() end)
		self.can_control = false
		
		local t = sol.movement.create("target")
	    t:set_target(shift_bait_by_direction_input())
		t:set_speed(math.random(60, 70))
		t:start(fishing_rod, function()
		  sol.timer.start(50, function()
		    self.can_control = true
			if self:is_bait_trail_active() then self:stop_trail() end
		  end)
		end)
		
		if self.map:get_ground(fishing_rod:get_position()) == "deep_water" then
		  sol.audio.play_sound("items/fishing_rod/move_bait_on_water")
		end
		
		function t:on_obstacle_reached()
		  fish_rod_controller.can_control = true
		  if self:is_bait_trail_active() then self:stop_trail() end
		end
	  end
	end
  end
  
  if command == self.slot and not is_shot and not is_dowsing and not self.game:is_suspended() then
    self.dowsed_distance = 50
    avoid_return = true
    is_dowsing = true
	water_effect = nil
	need_trail_update = false
	has_finished_movement = false
	
	self:dowse()
	
    hero:freeze()
    hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
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
	self.game:set_value("item_fishing_rod_state", 2)
	avoid_return = false
	
  elseif command == "pause" then
    return false
  
  elseif command == self.opposite_slot and not self.game:is_suspended() then
    if (self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "boomerang" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "bow" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "dominion_rod") and not is_shot then
      is_halted_by_anything_else = true
	  is_shot = false
	  self.game.is_going_to_another_item = true
	  self:stop_fishing_rod()
	  hero:freeze()
	  hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	  sol.timer.start(10, function()
	    self.game:set_custom_command_effect("action", nil)
	    self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
	  end)
    end
	
  elseif command == "attack" and not avoid_return and not is_shot and not self.game.is_going_to_another_item and not self.game:is_suspended() then
    self.game:get_hero():freeze()
    self:stop_fishing_rod()
	
  elseif command == "action" and self.item_landed and self.can_control then
    local speed = 40
    if self.game:is_command_pressed(direction[1 + ((hero:get_direction() + 2) % 4)]) then speed = 60 end -- todo
	fishing_rod:set_direction((self.game:get_hero():get_direction() + 2) % 4)
	
	local t = sol.movement.create("target")
	t:set_target(align_bait_to_hero())
	t:set_speed(speed)
	t:set_ignore_obstacles(true)
	t:start(fishing_rod, function()
	  if self.game:is_command_pressed("action") and self.item_landed then self.game:simulate_command_pressed("action") end
	end)
	
	sol.audio.play_sound("items/fishing_rod/reel"..speed)
  end
  return true
end

function fish_rod_controller:stop_fishing_rod()
  self.game:set_custom_command_effect("attack", nil)
  self.game:set_custom_command_effect("action", nil)
  self.game:set_value("item_fishing_rod_state", 0)
  self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
  avoid_return = false
  is_shot = false
  
  if (not self.game:is_current_scene_cutscene() and not ended_by_pickable and not self.game.is_going_to_another_item) then self.game:show_cutscene_bars(false) end
  
  if not is_halted_by_anything_else then
    if not from_teleporter then sol.audio.play_sound("common/item_show") end
	from_teleporter = false
	self.game:get_hero():freeze()
	self.game:get_hero():set_animation("fishing_rod_intro", function()
	  self.game:set_ability("shield", self.game:get_value("current_shield"))
	  self.game:get_hero():unfreeze()
	  self.game:set_item_on_use(false)
	  self.game:get_hero():set_shield_sprite_id("hero/shield"..self.game:get_value("current_shield"))
	  self.game:get_item("fishing_rod"):set_finished()
	end) 
  else
    is_halted_by_anything_else = false
	self.game:set_item_on_use(false)
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
	self.game:get_item("fishing_rod"):set_finished()
  end
  ended_by_pickable = false
  sol.menu.stop(self)
  sol.timer.stop_all(self)
end

return fish_rod_controller