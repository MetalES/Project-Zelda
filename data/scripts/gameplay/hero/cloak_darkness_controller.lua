local cloak_darkness_controller = {}

cloak_darkness_controller.slot = "item_1";
cloak_darkness_controller.opposite_slot = "item_2";
cloak_darkness_controller.opposite_slot_to_number = 2;
cloak_darkness_controller.new_x = 0;
cloak_darkness_controller.new_y = 0;
cloak_darkness_controller.gx = 0;
cloak_darkness_controller.gy = 0;
cloak_darkness_controller.lx = 0;
cloak_darkness_controller.ly = 0;
cloak_darkness_controller.llayer = 0;

local timer

function cloak_darkness_controller:start_cloak(game)
  self.game = game
  self.hero = game:get_hero()
  self.map = game:get_map()
  sol.audio.set_music_volume(sol.audio.get_music_volume() / 2)
  self.hero:unfreeze()
  
  sol.audio.play_sound("items/cloak_darkness/on")
  sol.audio.play_sound("items/cloak_darkness/is_ghost")
  
  self.game:set_value("item_cloak_darkness_state", 1)
  
  local x, y, layer = self.hero:get_position()
  self.hero_dead_sprite = self.map:create_custom_entity({
	x = x,
	y = y,
	layer = layer,
	direction = 0,
	sprite = "hero/item/cloak_darkness/dead_sprite.tunic"..self.game:get_ability("tunic"),
  }) 
  self.hero_dead_sprite.x, self.hero_dead_sprite.y, self.hero_dead_sprite.layer = self.hero_dead_sprite:get_position()
  self.hero_dead_sprite:set_drawn_in_y_order(true)	
  
  self.hero:set_tunic_sprite_id("hero/item/cloak_darkness/tunic"..self.game:get_ability("tunic"))
		
  for entity in game:get_map():get_entities("invisible") do
	entity:set_enabled(true)
  end
  
  sol.timer.start(self, 1200, function() 
    if self.game:get_magic() > 0 then 
	  self.game:remove_magic(1)
	else
	  self.game:remove_life(1)
	end
  return sol.menu.is_started(self)
  end)
  
  sol.timer.start(self, 60, function()
	local lx, ly, llayer = self.hero:get_position()
	local trail = game:get_map():create_custom_entity({
		x = lx,
		y = ly,
		layer = llayer,
		direction = self.hero:get_direction(),
		sprite = "hero/item/cloak_darkness/tunic"..self.game:get_ability("tunic"),
	})
	trail:get_sprite():fade_out(10, function() trail:remove() end)
  return sol.menu.is_started(self)
  end)
  
  sol.menu.start(self.map, self, false)
  self:start_ground_check()
end


function cloak_darkness_controller:start_ground_check()
  local hero = self.hero
  local function end_by_collision() 
    if hero:get_state() == "treasure" then 
	ended_by_pickable = true end
    hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
	is_halted_by_anything_else = true
	if hero:get_state() == "falling" then cloak_darkness_controller:stop_cloak("falling") end 
	if hero:get_state() == "hurt" then hero:set_invincible(true, 1000) hero:set_blinking(true, 1000) cloak_darkness_controller:stop_cloak("hurt") 
	else cloak_darkness_controller:stop_cloak("collision with object") end
  end

  timer = sol.timer.start(self, 50, function()
	self.lx, self.ly, self.llayer = self.game:get_hero():get_position()
	
	-- Todo : when hero:on_direction_changed() will be available, delete this, and replace the whole thing by input checking and values instead of direction checking
	
	if hero:get_direction() == 0 then self.new_x = -1; self.new_y = 0; self.gx = 1; self.gy = 0
	elseif hero:get_direction() == 1 then self.new_x = 0; self.new_y = 1 ; self.gy = -1;  self.gx = 0
	elseif hero:get_direction() == 2 then self.new_x = 1; self.new_y = 0 ; self.gy = 0;  self.gx = -1
	elseif hero:get_direction() == 3 then self.new_x = 0; self.new_y = -1; self.gy = 1;  self.gx = 0
	end

	if hero:get_state() == "swimming" or (hero:get_state() == "jumping" and not is_shot) then hero:set_position(self.lx + self.new_x, self.ly + self.new_y); end_by_collision() end
	if hero:get_state() == "falling" or hero:get_state() == "stairs" or hero:get_animation() == "swimming_stopped" or hero:get_state() == "hurt" or self.game:get_map():get_ground(self.lx + self.gx, self.ly + self.gy, self.llayer) == "lava" or hero:get_state() == "treasure" then end_by_collision() end
	
	-- check if the item has changed
	if self.game:get_value("_item_slot_2") == "cloak_darkness" then 
      self.slot = "item_2" 
    elseif self.game:get_value("_item_slot_1") == "cloak_darkness" then 
      self.slot = "item_1" 
	else
	  self.slot = ""
    end
	
	if self.game.has_changed_tunic then self.game.has_changed_tunic = false hero:set_tunic_sprite_id("hero/item/cloak_darkness/tunic"..self.game:get_ability("tunic")) end
	
  return true
  end)
  timer:set_suspended_with_map(true)
end

function cloak_darkness_controller:on_command_pressed(command)
  if (command == "item_1" and self.game:get_value("_item_slot_1") == "cloak_darkness") or (command == "item_2" and self.game:get_value("_item_slot_2") == "cloak_darkness") and not self.game:is_suspended() then
    self:stop_cloak("normal")
  elseif (command == "item_1" and self.game:get_value("_item_slot_1") ~= "cloak_darkness") or (command == "item_2" and self.game:get_value("_item_slot_2") ~= "cloak_darkness") and not self.game:is_suspended() then
  	sol.audio.play_sound("wrong")
  elseif command == "pause" or command == "attack" or command == "action" then
    return false
  end
  return true
end

function cloak_darkness_controller:stop_cloak(type_of_stop)
  local type_of_stop = type_of_stop or "normal"
  sol.audio.play_sound("items/cloak_darkness/ending")
  self.game:set_value("item_cloak_darkness_state", 0)
  self.hero:set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
  
  if type_of_stop == "normal" or type_of_stop == "hurt" then
    self.hero:set_visible(false)
	self.map:move_camera(self.hero_dead_sprite.x, self.hero_dead_sprite.y, 200, function() 
	  self.hero:set_position(self.hero_dead_sprite.x, self.hero_dead_sprite.y, self.hero_dead_sprite.layer)
      self.hero_dead_sprite:remove()
	  self.hero:set_visible(true) 
      sol.audio.set_music_volume(sol.audio.get_music_volume() * 2)
	  sol.audio.play_sound("stairs_indicator")
    end, 10, 0)
  elseif type_of_stop == "falling" then
    self.hero_dead_sprite:remove()
  end
  
  self.game:get_item("cloak_darkness"):set_finished()
  sol.timer.stop_all(self)
  sol.menu.stop(self)
end



return cloak_darkness_controller