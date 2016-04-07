local lantern_controller = {}

--[[Lantern Controller -- 02-03-2016 - MetalZelda, Credit would be nice, project is educationnal-only.]]
lantern_controller.slot = "item_1"
lantern_controller.new_x = 0
lantern_controller.new_y = 0
lantern_controller.gx = 0
lantern_controller.gy = 0

local can_cancel = false
local ended_by_pickable = false
local is_halted_by_anything_else = false
local timer, timer0,oil_timer


--todo do not store / disable item bindings, just disable pause.
-- todo swing animation that check if something can be lit.
function lantern_controller:start_lantern(game)
  self.game = game
  self.hero = self.game:get_hero()
  self.game:set_ability("shield", 0)
  
  self.game:set_value("item_lamp_state", 1)
  self.game.is_using_lantern = true
  
  sol.audio.play_sound("/items/lamp/on")
  self.hero:set_tunic_sprite_id("hero/item/lantern.tunic"..self.game:get_ability("tunic"))
  self.hero:unfreeze()
  
  local ex = 0
  local ey = 0
  local x, y, layer = self.hero:get_position()
  
  if self.hero:get_direction() == 0 then ex = 2; ey = - 5
  elseif self.hero:get_direction() == 1 then ey = - 12; ex = 2
  elseif self.hero:get_direction() == 2 then ex = - 11; ey = - 5
  else ey = - 3; ex = - 9 end

  local fire_burst = self.game:get_map():create_custom_entity({
	x = x + ex,
	y = y + ey,
	layer = layer,
	direction = 0,
	sprite = "entities/fire_burst",
  }) 
			
  if self.hero:get_direction() ~= 1 then
    fire_burst:set_drawn_in_y_order(true)
	fire_burst:bring_to_front()
  end		
			
  sol.timer.start(300, function()
    fire_burst:remove()
  end)

  particle_timer = sol.timer.start(self, 100, function()
	local hx,hy = self.hero:get_position()
	local px, py
	
	if (self.hero:get_animation() == "stopped" or self.hero:get_animation() == "walking") and self.game:get_magic() > 0 and self.hero:get_tunic_sprite_id() == "hero/item/lantern.tunic"..self.game:get_ability("tunic") then
	  sprite = "effects/item/lantern_effect"
	else
	  sprite = nil
	end
	
	if self.hero:get_direction() == 0 then px = 6;   py = - 2
	elseif self.hero:get_direction() == 1 then py = - 5;  px = 5
	elseif self.hero:get_direction() == 2 then px = - 6;  py = - 2 
	else py = - 3; px = - 4 end

	local particle = self.game:get_map():create_custom_entity({
	  x = hx + px,
	  y = hy + py,
	  layer = layer,
	  direction = 0,
	  sprite = sprite,
	}) 
	
	if self.hero:get_direction() ~= 1 then
	  particle:set_drawn_in_y_order(true)
	  particle:bring_to_front()
	else 
	  particle:set_drawn_in_y_order(false)
	  particle:bring_to_front()
	end
			
	sol.timer.start(200, function()
  	  particle:remove() 
	end)
	
  return sol.menu.is_started(self)
  end)
  
  self.game:remove_magic(1)
  oil_timer = sol.timer.start(self, 2000, function()
    self.game:remove_magic(1)
  return sol.menu.is_started(self)
  end)
  oil_timer:set_suspended_with_map(true)
    
  sol.menu.start(self.game, self)
  -- self.game:set_pause_allowed(false)
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
  if command == "action" and can_cancel and not self.game:is_suspended() then
    self:stop_lantern()
  elseif command == self.slot and not self.game:is_suspended() then
    self.hero:freeze()
    self.hero:set_animation("lantern_swing", function()
	  self.hero:unfreeze()
	end)
  elseif command == (self.opposite_slot or (self.opposite_slot_0 or nil)) and not self.game:is_suspended() then
    self.hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
	return false
  else
    return false
  end
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
  
  self.hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
  self.hero:unfreeze()
end

return lantern_controller