local rod_controller = {
  slot = "item_1",
  shift = {[0] = 0, [1] = -1, [2] = -2, [3] = 0, [4] = -1, [5] = -2},
  state = 0
}

-- Set which build-in hero state can interrupt this item
local state = {"swimming", "jumping", "falling", "stairs" , "hurt", "plunging", "treasure"}

local rod, timer, starting_timer, timer0
local is_halted_by_anything_else = false
local tick = 0

function rod_controller:start_rod(game, rod_type)
  self.game = game
  self.rod_type = rod_type
  self.hero = game:get_hero()
  game:set_item_on_use(true)

  self.slot = "item_1"
  if game:get_value("_item_slot_2") == rod_type .. "_rod_case" then 
    self.slot = "item_2"
  end  
  
  --shield

  local x, y, layer = self.hero:get_position()
  local direction = self.hero:get_direction()
 
  rod = self.game:get_map():create_custom_entity({
    x = x,
    y = y,
    layer = layer,
	width = 16,
	height = 16,
    direction = direction,
    sprite = "entities/item_".. rod_type .."_rod",
  })
  
  -- check if the input is pressed, if not, abort.
  starting_timer = sol.timer.start(self, 300, function()
    if self.game:is_command_pressed(self.slot) then 
	  self:start_ground_check()
	  self.state = 1
	  game:simulate_command_pressed(self.slot)
	  
	  self.hero:set_fixed_animations("rod_stopped", "rod_walking")
	  self.hero:set_fixed_direction(self.hero:get_direction())
	  
      self.hero:unfreeze()
	  self.hero:set_walking_speed(55)	
	else 
	  self.game:simulate_command_released(self.slot)
	end
  end)
  starting_timer:set_suspended_with_map(true)
  
  self.hero.on_custom_position_changed = function()
    local x, y, layer = self.hero:get_position()
    rod:set_position(x, y - rod_controller.shift[self.hero:get_sprite("tunic"):get_frame()], layer) 
  end
  
  sol.menu.start(self.game:get_map(), self)
end

function rod_controller:start_ground_check()
  local hero = self.hero
  
  local function end_by_collision() 
    local state = hero:get_state()
    is_halted_by_anything_else = true
    if state == "treasure" then ended_by_pickable = true end
	if state == "stairs" then hero:set_animation("walking") end
	rod_controller:stop_rod() 
  end

  timer0 = sol.timer.start(self, 10, function()
    for _, state in ipairs(state) do
	  if hero:get_state() == state then
		hero:cancel_direction_fix()
	    end_by_collision() 
	  end
	end
	
	self.slot = "item_1"
	if self.game:get_value("_item_slot_2") == self.rod_type.."_rod" then 
      self.slot = "item_2" 
    end
	
	local slot_number = self.slot:sub(6)

	if self.game:get_value("_item_slot_" .. self.slot:sub(6)) ~= self.rod_type.."_rod" then self.game:simulate_command_released(self.slot) end 
	if not self.game:is_command_pressed(self.slot) and self.game:get_value("item_"..self.rod_type.."_rod_state") == 1 then self.game:simulate_command_released(self.slot) end
    return true
  end)
  timer0:set_suspended_with_map(true)
end

function rod_controller:on_command_pressed(command)

  if command == self.slot and not self.game:is_suspended() then
	rod:get_sprite():set_animation("walking")
	timer = sol.timer.start(self, 100, function()
	  if self.game:get_magic() > 0 then self:shoot_type(self.rod_type) end
	  tick = tick + 1
	  if tick == 2 then
	    tick = 0
	    self.game:set_magic(self.game:get_magic() - 1)
	  end
	  return true
	end)
	timer:set_suspended_with_map(true)
  elseif command == "pause" then
    return false
  end
  return true
end

function rod_controller:shoot_type()
  local direction = self.hero:get_direction()
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
    model = self.rod_type.."_beam",
    x = x + dx,
    y = y + dy,
    layer = layer,
	width = 16,
	height = 16,
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
  if command == self.slot and not self.game:is_suspended() then
	self:stop_rod()
	sol.audio.play_sound("common/item_show") 
  end
  return true
end

function rod_controller:stop_rod() 
  local game = self.game
  local hero = self.hero
  
  hero.on_custom_position_changed = nil
  
  tick = 0
  rod:remove()
  game:set_ability("shield", game:get_value("current_shield"))
  hero:set_shield_sprite_id("hero/shield" .. game:get_value("current_shield"))
  hero:set_walking_speed(88)
  game:set_value("item_"..self.rod_type.."rod_state", 0)
  game:set_item_on_use(false)
  
  hero:cancel_direction_fix()
  
  if not is_halted_by_anything_else then
    hero:unfreeze()
    hero:set_animation("stopped" .. (game:get_ability("shield") > 0 and "_with_shield") or "")
  end
  
  hero:set_shield_sprite_id("hero/shield" .. game:get_value("current_shield"))
  is_halted_by_anything_else = false
  
  game:get_item(self.rod_type.."_rod"):set_finished()
 
  sol.menu.stop(self)  
  sol.timer.stop_all(self)
end

return rod_controller