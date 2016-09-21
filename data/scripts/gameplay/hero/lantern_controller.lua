local lantern_controller = {
  slot = "item_1",
  state = "inactive"
}

local allowed_state = {"initialize", "active", "using_item", "ending", "inactive"}
local can_cancel = false
local ended_by_pickable = false
local force_stop = false
local oil_timer

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
  self.hero = game:get_hero()
  self.item = game:get_item("lamp")
  
  game:set_ability("shield", 0)
  game.is_using_lantern = true
  
  self.state = "initialize"
  
  if game:get_magic() > 0 then
	self.item:set_light_animation("active") 
  end
  
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
	
	lantern_controller.state = "active"
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
  self:check() 
end

function lantern_controller:check()
  local hero = self.hero
  local game = self.game
  local ticks = 0
  
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    self.hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
    force_stop = true
	lantern_controller:stop_lantern() 
  end

  self.timer = sol.timer.start(self, 50, function()
    local item_name = self.game:get_item_assigned(2) or nil
    local item_opposite = item_name ~= nil and item_name:get_name() or nil
    local item = item_opposite == "lamp" or nil
  
    -- Check if the item has changed
	self.slot = item and "item_2" or "item_1"
  
	if hero:get_animation() == "stopped" and not game:is_using_item() and game:get_item("boomerang"):get_state() == 0 then
	  ticks = ticks + 1
	  if ticks == 10 then
	    ticks = 10
		game:set_custom_command_effect("action", "return")
		can_cancel = true
	  end
	else
	  ticks = 0
	  game:set_custom_command_effect("action", nil)
	  can_cancel = false
	end
	
    return sol.menu.is_started(self)
  end) 
  self.timer:set_suspended_with_map(true) 
end

function lantern_controller:on_command_pressed(command)
  local suspended = self.game:is_suspended()
  local game = self.game
  local hero = self.hero
  
  local opposite = self.slot == "item_1" and 1 or 2
  local item_name = game:get_item_assigned(opposite) or nil
  local item_opposite = item_name ~= nil and item_name:get_name() or nil
  
  if command == "pause" or command == "attack" then
    return false
  end
  
  if not suspended then
    if command == self.slot then
	  hero:freeze()
      hero:set_animation("lantern_swing", function()
	    hero:unfreeze()
	  end)
	  
	  sol.timer.start(self, 400, function()
	    local entity = hero:get_facing_entity()
	    if entity.on_lantern_interaction ~= nil and game:get_magic() > 0 then
		  entity:on_lantern_interaction()
		end
	  end)
	  
	elseif command == "item_" .. opposite then
	  game:get_item(game:get_value("_item_slot_" .. opposite)):on_using()
	  
	elseif command == "action" and can_cancel then
	  self:stop_lantern()
	  
	else
	  return false
	end
  end
  return true
end

function lantern_controller:stop_lantern()
  local game = self.game
  local hero = self.hero

  game:set_ability("shield", hero.shield)
  hero.shield = nil
  
  self.state = "inactive"
  game:set_light_animation(self.state)
  
  sol.audio.play_sound("/items/lamp/off")
  sol.audio.play_sound("common/item_show")
  
  can_cancel = false
  game.is_using_lantern = false
  
  game:set_custom_command_effect("action", nil)

  self.hero:cancel_direction_fix()
  
  sol.timer.stop_all(self)
  sol.menu.stop(self)
end

return lantern_controller