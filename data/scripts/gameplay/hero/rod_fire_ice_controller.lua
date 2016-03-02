--[[
/script\Rod Controller Script.
/author\Made by MetalZelda - 22.02.2016

/desc\Controller script for both Fire and Ice Rod.

/copyright\Credits if you plan to use the script would be nice. Not for resale. Script and project are part of educationnal project.
]]

local rod_controller = {}

local slot = "item_1"
local new_x, new_y, gx, gy, rod
local is_halted_by_anything_else = false
local tick = 0

function rod_controller:start_rod(game, rod_type)
  self.game = game
  self.rod_type = rod_type
  self.hero = self.game:get_hero()
  self.current_tunic = self.game:get_value("item_saved_tunic")

  local x, y, layer = self.hero:get_position()
  local direction = self.hero:get_direction()
 
  slot = "item_1"
  if self.game:get_value("_item_slot_2") == self.rod_type.."_rod" then slot = "item_2" end 
  self.game:get_item(self.rod_type.."_rod"):store_equipment(self.rod_type.."_rod")
 
  rod = self.game:get_map():create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    direction = direction,
    sprite = "hero/item/"..self.rod_type.."_rod/rod",
  })
  self.game:set_value("item_"..self.rod_type.."_rod_state", int)
  
  -- check if the input is pressed, if not, abort.
  sol.timer.start(self, 300, function()
    if self.game:is_command_pressed(slot) then 
	  self.game:simulate_command_pressed(slot)
      self.hero:unfreeze()
	  self.hero:set_tunic_sprite_id("hero/item/fire_rod/rod_moving_tunic_"..self.current_tunic)
	  self.hero:set_walking_speed(55)	
	else 
	  self.game:simulate_command_released(slot)
	end
  end)
  
  for teleporter in self.game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  self.hero:freeze()
	end
  end
  sol.menu.start(self.game:get_map(), self)
  self:start_ground_check() 
end

function rod_controller:start_ground_check()

  local function end_by_collision() is_halted_by_anything_else = true; self:stop_rod() end
  local function end_by_pickable() is_halted_by_anything_else = true; self:stop_rod() end

  sol.timer.start(self, 50, function()
	local lx, ly, llayer = self.hero:get_position()
	-- systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
	-- Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
	-- this is just a placeholder until the function will be back
	if self.hero:get_direction() == 0 then new_x = -1; new_y = 0; gx = 1; gy = 0
	elseif self.hero:get_direction() == 1 then new_x = 0; new_y = 1 ; gy = -1;  gx = 0
	elseif self.hero:get_direction() == 2 then new_x = 1; new_y = 0 ; gy = 0;  gx = -1
	elseif self.hero:get_direction() == 3 then new_x = 0; new_y = -1; gy = 1;  gx = 0
	end
	  
	if self.hero:get_state() == "swimming" or self.hero:get_state() == "jumping" then self.hero:set_position(x + new_x, ly + new_y); end_by_collision() end
	if self.hero:get_state() == "falling" or self.hero:get_state() == "stairs" or self.hero:get_animation() == "swimming_stopped" or self.hero:get_state() == "hurt" or self.game:get_map():get_ground(lx + gx, ly + gy, llayer) == "lava" or self.hero:get_state() == "treasure" then end_by_collision() end
	
  return true
  end)
end

function rod_controller:on_command_pressed(command)

  if command == slot then
	rod:get_sprite():set_animation("walking")
	sol.timer.start(self, 100, function()
	  if self.game:get_magic() > 0 then self:shoot_type(self.rod_type) end
	  tick = tick + 1
	  if tick == 2 then
	    tick = 0
	    self.game:set_magic(self.game:get_magic() - 1)
	  end
	  return true
	end)
  end
end

function rod_controller:on_update()
  rod:set_position(self.hero:get_position()) 
  rod:set_direction(self.hero:get_direction())
end

function rod_controller:shoot_type(typeof)
  local direction = self.game:get_hero():get_direction()
  local dx, dy
  if direction == 0 then
    dx, dy = 14, -16
  elseif direction == 1 then
    dx, dy = -8, -35
  elseif direction == 2 then
    dx, dy = -20, -16
  else
    dx, dy = 2, -4
  end

  local x, y, layer = self.hero:get_position()
  local entity = self.game:get_map():create_custom_entity({
    model = rod_controller.rod_type.."_beam",
    x = x + dx,
    y = y + dy,
    layer = layer,
    direction = direction,
  })
  
 sol.audio.play_sound("items/"..self.rod_type.."_rod/shoot")

local entity_mvt = sol.movement.create("straight")
entity_mvt:set_angle(direction * math.pi / 2)
entity_mvt:set_speed(200)
entity_mvt:set_max_distance(32)
entity_mvt:set_smooth(false)
entity_mvt:start(entity)
end

function rod_controller:on_command_released(command)
  if command == slot then
	self:stop_rod()
	sol.audio.play_sound("common/item_show") 
  end
end

function rod_controller:stop_rod()  
  tick = 0
  rod:remove()
  self.game:get_item(self.rod_type.."_rod"):restore_equipment()
  self.hero:set_walking_speed(88)
  self.game:set_value("item_"..self.rod_type.."rod_state", 0)
  
  if not is_halted_by_anything_else then
	self.hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
    self.game:get_item(self.rod_type.."_rod"):set_finished()
  else
    self.hero:set_tunic_sprite_id("hero/tunic"..self.current_tunic)
    is_halted_by_anything_else = false
    self.game:get_item(self.rod_type.."_rod"):set_finished()
  end  
  sol.menu.stop(self)  
  sol.timer.stop_all(self)
end

return rod_controller