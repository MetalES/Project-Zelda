--[[
/script\Bow Controller Script.
/author\Made by MetalZelda - 21.02.2016

/desc\Controller script for the bow.
]]

local bow_controller = {}

bow_controller.slot = "item_1"
bow_controller.opposite_slot = "item_2"
bow_controller.opposite_slot_to_number = 2
bow_controller.sound_arming = "items/bow/arming"
bow_controller.sound_shoot_arrow = "items/bow/shoot"
bow_controller.sound_shoot_empty = "items/bow/no_arrows_shoot"
bow_controller.bow_ammo_check = ""
bow_controller.hero_armed_tunic = ""
bow_controller.hero_free_tunic = "" 
bow_controller.hero_shoot_animation = "bow_shoot"
bow_controller.lx = 0
bow_controller.ly = 0
bow_controller.llayer = 0
bow_controller.new_x = 0
bow_controller.new_y = 0
bow_controller.gx = 0
bow_controller.gy = 0

local is_halted_by_anything_else = false
local avoid_return = false
local from_teleporter = false
local is_shot = false


function bow_controller:start_bow(game)
  self.game = game
  
  self.hero_armed_tunic = "hero/item/bow/bow_moving_" .. self.bow_ammo_check .. "arrow_tunic" .. self.game:get_ability("tunic")
  self.hero_free_tunic = "hero/item/bow/bow_moving_free_tunic" .. self.game:get_ability("tunic")
  
  is_shot = true
      
  self.game:get_hero():set_animation(self.hero_shoot_animation, function()
    self.game:get_hero():set_walking_speed(40)
    self.game:get_hero():unfreeze()
	self.game:get_hero():set_tunic_sprite_id(self.hero_free_tunic)
	self.game:set_custom_command_effect("attack", "return") 
	sol.menu.start(self.game:get_map(), self)
	self.game.is_going_to_another_item = false 
	if self.game:get_value("item_bow_max_arrow_type") > 0 then
	  self.game:set_custom_command_effect("action", "change")
	end
	is_shot = false
  end)
    
  for teleporter in self.game:get_map():get_entities("teleporter") do
	teleporter.on_activated = function()
	  avoid_return = true
	  from_teleporter = true
	  ended_by_pickable = false
	  is_halted_by_anything_else = true
	  self.game:set_value("item_bow_state", 0)
	  self:stop_bow()
	  -- self.game:get_hero():freeze()
	end
  end
  
  sol.audio.play_sound("common/item_show")
  
  if self.game:get_value("_item_slot_2") == "bow" then 
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
	self.game:get_item("bow"):store_equipment("bow")
  end
  
  self:start_ground_check() 
end

function bow_controller:start_ground_check()
  local hero = self.game:get_hero()
  
  local function end_by_collision() 
    if hero:get_state() == "treasure" then ended_by_pickable = true end
    hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
    is_halted_by_anything_else = true
	bow_controller:stop_bow() 
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

function bow_controller:create_arrow()
  local hero = self.game:get_hero()
  local x, y = hero:get_center_position()
  local _, _, layer = hero:get_position()
  local ax, ay
	  
  if hero:get_direction() == 0 then ax = 0; ay = - 1
  elseif hero:get_direction() == 1 then ax = - 3; ay = 0 
  elseif hero:get_direction() == 2 then ax = 0; ay = - 1
  else ax = 0; ay = 0 end
	  
  local arrow = self.game:get_map():create_custom_entity({
    x = x + ax,
    y = y + ay,
    layer = layer,
    direction = hero:get_direction(),
    model = "arrow",
  })
  arrow:set_force(self.game:get_item("bow"):get_force())
  arrow:set_sprite_id(self.game:get_item("bow"):get_arrow_sprite_id())
  arrow:go()
end

function bow_controller:on_command_pressed(command)
  local hero = self.game:get_hero()
  
  if command == self.slot and not self.game.is_building_new_arrow and not is_shot then
    if self.game:get_item("bow"):get_amount() == 0 then
      self.bow_ammo_check = ""
	else
	  self.bow_ammo_check = "with_"
	end
	
	self.hero_armed_tunic = "hero/item/bow/bow_moving_" .. self.bow_ammo_check .. "arrow_tunic" .. self.game:get_ability("tunic")
    self.hero_free_tunic = "hero/item/bow/bow_moving_free_tunic" .. self.game:get_ability("tunic")
	
    avoid_return = true
	hero:freeze()
	sol.audio.play_sound(self.sound_arming)
	hero:set_animation("bow_arming_"..self.bow_ammo_check.."arrow")
	sol.timer.start(self, 50, function()
	  self.game:set_value("item_bow_state", 2)
	  hero:set_animation("stopped")
	  hero:set_tunic_sprite_id(self.hero_armed_tunic)
	  hero:unfreeze()
	  avoid_return = false
	  hero:set_walking_speed(28)
	  if not self.game:is_command_pressed(self.slot) then self.game:simulate_command_released(self.slot) end
	end)
  end
end  
 

function bow_controller:on_key_pressed(key)
  if key == (self.game:get_value("keyboard_action") or self.game:get_value("joypad_action")) and not self.game.is_building_new_arrow and not is_shot then
    self.game.next_arrow = true
	self.game.is_building_new_arrow = true
	avoid_return = false
	self.game:get_hero():unfreeze()
	self.game:set_value("item_bow_state", 1)
	sol.timer.start(self, 50, function()
	  self.game:get_hero():set_tunic_sprite_id(self.hero_free_tunic)
	  self.game:simulate_command_released(self.slot)
	end)
  elseif key == (self.game:get_value("keyboard_attack") or self.game:get_value("joypad_attack")) and not avoid_return and not self.game.is_going_to_another_item then
    self:stop_bow()
  -- if the opposite slot is the boomerang / hookshot / dominion rod, finish the bow and start the other item.
  elseif key == (self.game:get_value("keyboard_item_"..self.opposite_slot_to_number) or self.game:get_value("joypad_item_"..self.opposite_slot_to_number)) and (self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "boomerang" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "hookshot" or self.game:get_value("_item_slot_"..self.opposite_slot_to_number) == "dominion_rod") then
    self.game.is_going_to_another_item = true
	is_shot = true
	is_halted_by_anything_else = true
	self.game:get_hero():freeze()
	self:stop_bow()
	self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	sol.timer.start(10, function()
	  self.game:set_command_keyboard_binding("item_"..self.opposite_slot_to_number, self.game:get_value("keyboard_item_"..self.opposite_slot_to_number))
      self.game:set_command_joypad_binding("item_"..self.opposite_slot_to_number, self.game:get_value("joypad_item_"..self.opposite_slot_to_number))
	  self.game:get_item(self.game:get_value("_item_slot_"..self.opposite_slot_to_number)):on_using()
	  self.game:set_custom_command_effect("action", nil)
	end)
  end
end

function bow_controller:on_command_released(command)
local hero = self.game:get_hero()
  if command == self.slot and self.game:get_value("item_bow_state") == 2 then
	avoid_return = true
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..self.game:get_ability("tunic"))
	  if self.game:get_item("bow"):get_amount() > 0 then       
		sol.audio.play_sound(self.sound_shoot_arrow)
		self.game:get_item("bow"):remove_amount(1)
		self:create_arrow()
	  else
	    sol.audio.play_sound(self.sound_shoot_empty)
	  end
	hero:freeze()
	self.game:set_value("item_bow_state", 1)
	sol.timer.start(self, 60, function()
      hero:set_tunic_sprite_id(self.hero_free_tunic)
	  hero:unfreeze()
	  hero:set_walking_speed(40)
	  avoid_return = false
    end)
  end
end

function bow_controller:stop_bow()  
  self.game:set_value("item_bow_state", 0)
  self.game:get_hero():set_walking_speed(88)
  self.game:set_custom_command_effect("attack", nil)
  
  if (not self.game:is_current_scene_cutscene() and not ended_by_pickable and not self.game.is_going_to_another_item) then self.game:show_cutscene_bars(false) end
  if not self.game.is_going_to_another_item then self.game:get_item("bow"):restore_equipment() end
  
  if not is_halted_by_anything_else then
    if not from_teleporter then sol.audio.play_sound("common/item_show") end
	from_teleporter = false
	self.game:get_hero():freeze()
	self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	self.game:get_hero():set_animation(self.hero_shoot_animation)
	sol.timer.start(120, function()
	  if not self.game:is_current_scene_cutscene() then self.game:set_pause_allowed(true) self.game:get_hero():unfreeze() end
	  self.game:get_item("bow"):set_finished()
	end)
  else
    is_halted_by_anything_else = false
    self.game:get_item("bow"):set_finished()
  end   
  
  avoid_return = false
  ended_by_pickable = false
  is_shot = false
  
  sol.menu.stop(self)
  sol.timer.stop_all(self)
end

return bow_controller