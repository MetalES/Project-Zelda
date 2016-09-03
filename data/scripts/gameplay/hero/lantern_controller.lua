local lantern_controller = {
  slot = "item_1",
  state = "inactive"
}

local allowed_state = {"initialize", "active", "using_item", "ending", "inactive"}
local can_cancel = false
local ended_by_pickable = false
local is_halted_by_anything_else = false
local timer, timer0, oil_timer

local function set_state(state)
  self.state = state
end

local function get_state()
  return self.state
end

--todo do not store / disable item bindings, just disable pause.
-- todo swing animation that check if something can be lit.
function lantern_controller:start_lantern(game)
  self.game = game
  self.map = game:get_map()
  self.hero = self.game:get_hero()
  game:set_ability("shield", 0)
  
  self.game:set_value("item_lamp_state", 1)
  game.is_using_lantern = true
  
  self.state = "initialize"
  
  sol.audio.play_sound("/items/lamp/on")
  self.hero:set_fixed_animations("lantern_stopped", "lantern_walking")
  self.hero:unfreeze()
  
  local ex = 2
  local ey = -5
  local x, y, layer = self.hero:get_position()
  local direction = self.hero:get_direction()
  
  if direction == 1 then 
    ey = - 12
  elseif direction == 2 then 
    ex = - 11
  elseif direction == 3 then
    ey = - 3
	ex = - 9 
  end

  local fire_burst = self.map:create_custom_entity({
	x = x + ex,
	y = y + ey,
	layer = layer,
	width = 8,
	height = 8,
	direction = 0
  }) 
  
  fire_burst:set_drawn_in_y_order(true)
  fire_burst:create_sprite("entities/fire_burst", "fire")
  local fire = fire_burst:get_sprite("fire")
  
  function fire:on_animation_finished()
    fire_burst:remove_sprite(self)
	fire_burst:remove()
	print("done")
  end	

  -- particle_timer = sol.timer.start(self, 100, function()
	-- local hx,hy = self.hero:get_position()
	-- local px, py
	
	-- if (self.hero:get_animation() == "stopped" or self.hero:get_animation() == "walking") and self.game:get_magic() > 0 and self.hero:get_tunic_sprite_id() == "hero/item/lantern.tunic"..self.game:get_ability("tunic") then
	  -- sprite = "effects/item/lantern_effect"
	-- else
	  -- sprite = nil
	-- end
	
	-- if self.hero:get_direction() == 0 then px = 6;   py = - 2
	-- elseif self.hero:get_direction() == 1 then py = - 5;  px = 5
	-- elseif self.hero:get_direction() == 2 then px = - 6;  py = - 2 
	-- else py = - 3; px = - 4 end

	-- local particle = self.game:get_map():create_custom_entity({
	  -- x = hx + px,
	  -- y = hy + py,
	  -- layer = layer,
	  -- direction = 0,
	  -- sprite = sprite,
	-- }) 
	
	-- if self.hero:get_direction() ~= 1 then
	  -- particle:set_drawn_in_y_order(true)
	  -- particle:bring_to_front()
	-- else 
	  -- particle:set_drawn_in_y_order(false)
	  -- particle:bring_to_front()
	-- end
			
	-- sol.timer.start(200, function()
  	  -- particle:remove() 
	-- end)
	
  -- return sol.menu.is_started(self)
  -- end)
  
  self.game:remove_magic(1)
  oil_timer = sol.timer.start(self, 2000, function()
    game:remove_magic(1)
    return sol.menu.is_started(self)
  end)
  oil_timer:set_suspended_with_map(true)
    
  sol.menu.start(self.map, self)
  self:start_ground_check() 
end

function lantern_controller:start_ground_check()
  local ticks = 0
  local function end_by_collision() 
    if self.hero:get_state() == "treasure" then ended_by_pickable = true end
    self.hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
    is_halted_by_anything_else = true
	lantern_controller:stop_lantern() 
  end

  timer = sol.timer.start(self, 50, function()
	self.lx, self.ly, self.llayer = self.hero:get_position()
	
	-- Todo : when hero:on_direction_changed() will be available, delete this, and replace the whole thing by input checking and values instead of direction checking
	
	if self.hero:get_direction() == 0 then self.new_x = -1; self.new_y = 0; self.gx = 1; self.gy = 0
	elseif self.hero:get_direction() == 1 then self.new_x = 0; self.new_y = 1 ; self.gy = -1;  self.gx = 0
	elseif self.hero:get_direction() == 2 then self.new_x = 1; self.new_y = 0 ; self.gy = 0;  self.gx = -1
	elseif self.hero:get_direction() == 3 then self.new_x = 0; self.new_y = -1; self.gy = 1;  self.gx = 0
	end

	if self.hero:get_state() == "swimming" then self.hero:set_position(self.lx + self.new_x, self.ly + self.new_y); end_by_collision() end
	if self.hero:get_animation() == "swimming_stopped" then end_by_collision() end
	
	if self.game:get_value("_item_slot_2") == "lamp" then 
      self.slot = "item_2" 
	  self.opposite_slot = "item_1"
	elseif self.game:get_value("_item_slot_1") == "lamp" then 
      self.slot = "item_1" 
	  self.opposite_slot = "item_2"
	else
	  self.slot = "" 
	  self.opposite_slot = "item_1"
	  self.opposite_slot_0 = "item_2"
    end
	
	if self.game:is_command_pressed("item_1") then
	  self.opposite_slot_to_number = 1
	elseif self.game:is_command_pressed("item_2") then
	  self.opposite_slot_to_number = 2
	end
	
	if self.hero:get_animation() == "stopped" and not self.game:is_using_item() and self.game:get_value("item_boomerang_state") == 0 then
	  ticks = ticks + 1
	  if ticks == 10 then
	    ticks = 10
		self.game:set_custom_command_effect("action", "return")
		can_cancel = true
	  end
	else
	  ticks = 0
	  self.game:set_custom_command_effect("action", nil)
	  can_cancel = false
	end
  return sol.menu.is_started(self)
  end) 
  timer:set_suspended_with_map(true) 
end

function lantern_controller:on_command_pressed(command)
  local suspended = self.game:is_suspended()
  local game = self.game
  local hero = self.hero
  
  if command == "pause" or command == "attack" then
    return false
  end
  
  if not suspended then
    if command == self.slot then
	  hero:freeze()
      hero:set_animation("lantern_swing", function()
	    hero:unfreeze()
	  end)
	elseif command == "action" and can_cancel then
	  self:stop_lantern()
	else
	  return false
	end
  end
  
  -- if command == "action" and can_cancel  then
   

  -- elseif command == (self.opposite_slot or (self.opposite_slot_0 or nil))  then
	-- self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()

  -- end
  return true
end

function lantern_controller:stop_lantern()
  sol.timer.stop_all(self)
  sol.menu.stop(self)
  sol.audio.play_sound("/items/lamp/off")
  sol.audio.play_sound("common/item_show")
  can_cancel = false
  self.game.is_using_lantern = false
  
  self.game:set_custom_command_effect("action", nil)
  self.game:set_value("item_lamp_state", 0)
  
  self.game:set_ability("shield", self.game:get_value("current_shield"))
  self.game:get_hero():set_shield_sprite_id("hero/shield"..self.game:get_ability("shield"))
  
  self.hero:cancel_direction_fix()
end

return lantern_controller