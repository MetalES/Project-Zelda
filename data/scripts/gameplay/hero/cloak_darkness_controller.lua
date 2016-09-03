local cloak_darkness_controller = {
  slot = "item_1";
  opposite_slot = "item_2";
  state = 0,
}


function cloak_darkness_controller:start_cloak(game)
  self.game = game
  self.hero = game:get_hero()
  self.map = game:get_map()
  
  self.hero:unfreeze()
  
  sol.audio.play_sound("items/cloak_darkness/on")
  sol.audio.play_sound("items/cloak_darkness/is_ghost")
  
  self.hero:get_sprite():fade_out(300)

  -- self.hero:set_tunic_sprite_id("hero/item/cloak_darkness/tunic"..self.game:get_ability("tunic"))
		
  for entity in game:get_map():get_entities("invisible") do
	entity:set_enabled(false)
  end
  
  self:remove_magic()
  self:create_trail()
  self:create_dummy()
  
  sol.menu.start(self.map, self, false)
  self:check()
end

function cloak_darkness_controller:create_dummy()
  local x, y, layer = self.hero:get_position()
  self.hero_dead_sprite = self.map:create_custom_entity({
	x = x,
	y = y,
	layer = layer,
	direction = 0,
	width = 16,
	height = 16,
	sprite = "hero/item/cloak_darkness/dead_sprite.tunic" .. self.game:get_ability("tunic"),
  }) 
  self.hero_dead_sprite.x, self.hero_dead_sprite.y, self.hero_dead_sprite.layer = self.hero_dead_sprite:get_position()
  self.hero_dead_sprite:set_drawn_in_y_order(true)	
end

function cloak_darkness_controller:create_trail()
  local timer = sol.timer.start(self, 60, function()
	local lx, ly, llayer = self.hero:get_position()
	-- local trail = self.map:create_custom_entity({
		-- x = lx,
		-- y = ly,
		-- layer = llayer,
		-- width = 16,
		-- height = 16,
		-- direction = self.hero:get_direction(),
		-- sprite = "hero/item/cloak_darkness/tunic"..self.game:get_ability("tunic"),
	-- })
	-- trail:get_sprite():fade_out(10, function() trail:remove() end)
  return sol.menu.is_started(self)
  end)
  timer:set_suspended_with_map(true)
end

function cloak_darkness_controller:remove_magic()
  local timer = sol.timer.start(self, 1200, function() 
    if self.game:get_magic() > 0 then 
	  self.game:remove_magic(1)
	else
	  self.game:remove_life(1)
	end
    return sol.menu.is_started(self)
  end)
  timer:set_suspended_with_map(true)
end


function cloak_darkness_controller:check()
  local hero = self.hero
  local function end_by_collision() 

  end

  timer = sol.timer.start(self, 10, function()
    sol.audio.set_music_volume(math.floor(self.game:get_value("old_volume") / 2))
	print(sol.audio.get_music_volume())
	
	
	return sol.menu.is_started(self)
  end)
  timer:set_suspended_with_map(true)
end

function cloak_darkness_controller:on_suspended(suspended)
  if not suspended then
    sol.audio.set_music_volume(self.game:get_value("old_volume"))
  end
end

function cloak_darkness_controller:on_command_pressed(command)
  local suspended = self.game:is_suspended()
  
  if command == "pause" or command == "attack" or command == "action" then
    return false
  end  
  
  if not suspended then 
  
    if command == self.slot then
	  self:stop_cloak("normal")
	end
  
  end

  -- elseif (command == "item_1" and self.game:get_value("_item_slot_1") ~= "cloak_darkness") or (command == "item_2" and self.game:get_value("_item_slot_2") ~= "cloak_darkness") and not self.game:is_suspended() then
  	-- sol.audio.play_sound("wrong")
  -- end
  return true
end

function cloak_darkness_controller:stop_cloak(type_of_stop)
  local type_of_stop = type_of_stop or "normal"
  
  sol.audio.play_sound("items/cloak_darkness/ending")
  self.state = 0
  -- self.hero:set_tunic_sprite_id("hero/tunic" .. self.game:get_ability("tunic"))
  
  if type_of_stop == "normal" or type_of_stop == "hurt" then
    self.hero:set_visible(false)
	self.hero:set_position(self.hero_dead_sprite.x, self.hero_dead_sprite.y, self.hero_dead_sprite.layer)
	
	self.map:move_camera(self.hero_dead_sprite.x, self.hero_dead_sprite.y, 200, function() 
      self.hero_dead_sprite:remove()
	  self.hero:set_visible(true) 
      sol.audio.set_music_volume(sol.audio.get_music_volume() * 2)
    end, 10, 1)
	
  else
    self.hero_dead_sprite:remove()
  end
  
  self.game:get_item("cloak_darkness"):set_finished()
  sol.timer.stop_all(self)
  sol.menu.stop(self)
end

return cloak_darkness_controller