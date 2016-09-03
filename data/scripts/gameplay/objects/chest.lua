local chest_system = {}
local initial_position = 0

function chest_system:on_started()
  self.game = sol.main.game
  self.map = self.game:get_map()
  self.hero = self.game:get_hero()
end

function chest_system:disable_hud_element()
  self.game:set_suspended(true)
  self.game:show_cutscene_bars(true)
  self.game:set_clock_enabled(false)
  self.game:set_pause_allowed(false)
  self.game:set_hud_enabled(false)
end

function chest_system:start_movement(dir, max_distance, x, y)
  
  sol.timer.start(self, 50, function()
    if dir == 1 then
	  initial_position = initial_position + 1
	  if initial_position == max_distance then
	    return false
	  end
	else
	  initial_position = initial_position - 1
	  if initial_position == -8 then
	    return false
	  end
	end
 	
	self.hero:set_position(x, y - initial_position)
    return true
  end)
end

function chest_system:start_open_chest(type_of_chest, entity)
  local savegame = entity:get_savegame_variable()
  local x, y, l = entity:get_position()
  local treasure = entity:get_name():match("^(.*)_[0-9]+$") or entity:get_name()
  local item_variant = 1
  
  local hero = self.hero
  local hero_dir = hero:get_direction()
  
  local game = self.game
  local game_svg = game:get_value(savegame) or false
  
  if entity.get_variant ~= nil then
    item_variant = entity:get_variant()
  end
  
  initial_position = 0
  
  if type_of_chest == 0 then -- Big Chest
  
    if hero_dir == 1 and not game_svg then
	  self:disable_hud_element()
	  hero:set_position(x, y + 5)
	  sol.audio.set_music_volume(0)
      sol.audio.play_sound("/common/chest_opening")
      sol.audio.play_sound("/common/chest_open")
	  hero:get_sprite():set_ignore_suspend(true)
	  hero:set_animation("drop")
	  entity:get_sprite():set_animation("opening")
	  entity:set_direction(1)
	  entity:set_drawn_in_y_order(false)
	  
	  sol.timer.start(self, 1500, function()
	    sol.audio.play_sound("/common/chest_creak")
        self.hero:set_animation("jumping")
        entity:set_direction(2)
	  end)
	  
	  sol.timer.start(self, 1530, function()
	    hero:set_animation("stopped")
	  end)
	  
	  sol.timer.start(self, 1600, function()
	    entity:set_direction(3)
	  end)
	  
	  sol.timer.start(self, 1800, function()
	    hero:set_animation("walking")
        self:start_movement(1, 1, x, y)
	  end)
	  
	  sol.timer.start(self, 2000, function()
	    hero:set_animation("hurt")
	  end)
	  
	  sol.timer.start(self, 2100, function()
	    hero:set_direction(0)
        self:start_movement(1, 5, x, y)
		hero:set_animation("chest_sequence")
		sol.audio.play_sound("/characters/link/voice/jump1")
	  end)
	  
	  sol.timer.start(self, 2600, function()
	    hero:set_direction(1)
	  end)
	  
	  sol.timer.start(self, 3300, function()
	    hero:set_direction(2)
	  end)
	  
	  sol.timer.start(self, 4700, function()
	    hero:set_direction(1)
	  end)
	  
	  sol.timer.start(self, 5500, function()
	    hero:set_animation("chest_sequence")
		hero:set_direction(0) 
		self:start_movement(3, 15, x, y)
	  end)
	  
	  sol.timer.start(self, 5900, function()
	    hero:set_direction(1)
		entity:set_drawn_in_y_order(true)
		hero:set_animation("walking")
	  end)
	  
	  sol.timer.start(self, 6400, function()
	    hero:set_animation("stopped")
	  end)
	  
	  sol.timer.start(self, 6900, function()
	    game:set_hud_enabled(true)
		game:set_clock_enabled(true)
		hero:set_direction(2)
	  end)
	  
	  sol.timer.start(self, 7000, function()
	    hero:set_direction(3)
		hero:set_animation("chest_holding_before_brandish")
	  end)
						  
	  sol.timer.start(self, 8100, function()
	    game:set_dialog_position("bottom")
		hero:start_treasure(treasure, item_variant)
		game:set_pause_allowed(true)
		game:set_suspended(false)
		hero:get_sprite():set_ignore_suspend(false)
		game:set_value(savegame, true)
		self:reload_minimap()
		sol.menu.stop(self)
	  end)

	elseif hero_dir ~= 1 and not game_svg then
	  self:wrong_direction()
	end
	
  elseif type_of_chest == 1 then
    local direction = entity:get_direction()
    if hero_dir == direction and not game_svg then
	
	  game:set_suspended(true)
	  
	  if direction == 0 then 
        hero:set_position(x - 16, y)
      elseif direction == 1 then
        hero:set_position(x, y + 16)
      elseif direction == 2 then
        hero:set_position(x + 16, y)
      else
        hero:set_position(x, y - 16)
      end
	  
	  sol.timer.start(self, 1, function()
        hero:set_animation("drop")
	  end)
	  
	  sol.timer.start(self, 200, function()
        if hero_dir == 3 or hero_dir == 1 then
		  hero:set_animation("stopped")
		else
		  hero:set_animation("grabbing")
		end
	  end)
	  
	  sol.timer.start(self, 300, function()
        if hero_dir == 0 or hero_dir == 2 then
		  hero:set_animation("stopped")
		end
		entity:get_sprite():set_animation("open")
		entity:get_sprite():set_direction(0)
		sol.audio.play_sound("/common/chest_open")
	  end)
	  
	  sol.timer.start(self, 600, function()
	    hero:set_animation("stopped")
		if hero_dir == direction then
		  if direction == 0 or direction == 2 then
			hero:set_direction(3)
		  elseif direction == 1 then
		    hero:set_direction(2)
		  end
		end
	  end)
	  
	  sol.timer.start(self, 750, function()
	    hero:set_animation("chest_holding_before_brandish")
	  end)
	  
	  sol.timer.start(self, 1500, function()
	    game:show_cutscene_bars(true)
		hero:unfreeze()
		hero:set_direction(direction)
		hero:start_treasure(treasure, item_variant)
		hero:set_animation("brandish_alternate")
		-- entity:set_drawn_in_y_order(false)
		game:set_suspended(false)
		game:set_pause_allowed(true)
		game:set_value(savegame, true)
		self:reload_minimap()
		sol.menu.stop(self)
	  end)
	  
    elseif hero:get_direction() ~= direction and not game_svg then
	  self:wrong_direction()
    end
  end
end

function chest_system:reload_minimap()
  for _, menu in ipairs(self.game.hud) do
    if menu.load_map ~= nil then
	  menu:load_map()
	end
  end
end

function chest_system:wrong_direction()
  sol.audio.play_sound("common/bars_dungeon")
  self.game:show_cutscene_bars(true)
  self.game:start_dialog("gameplay.logic._cant_open_chest_wrong_dir", function()
    self.game:show_cutscene_bars(false)
  end)
end

return chest_system