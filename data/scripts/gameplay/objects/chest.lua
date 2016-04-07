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

function chest_system:start_movement(dir, max_distance)
  
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
 	
	self.hero:set_position(self.entity_x, self.entity_y - initial_position)
    return true
  end)
end

function chest_system:start_open_chest(type_of_chest, entity)
  self.world = self.map:get_world()
  self.map_width, self.map_height = self.map:get_size()
  self.entity_x, self.entity_y, self.entity_l = entity:get_position()
  self.treasure = entity:get_name():match("^(.*)_[0-9]+$") or entity:get_name()
  self.big_chest_savegame = "big_chest_" .. self.treasure .. "_" .. self.world .. "_" .. self.map_width .. "_" .. self.map_height .. "_" .. self.entity_x .. "_" .. self.entity_y .. "_" .. self.entity_l
  self.small_chest_savegame = "small_chest_" .. self.treasure .. "_" .. self.world .. "_" .. self.map_width .. "_" .. self.map_height .. "_" .. self.entity_x .. "_" .. self.entity_y .. "_" .. self.entity_l
  initial_position = 0
  
  if type_of_chest == 0 then -- Big Chest
    if self.hero:get_direction() == 1 and not self.game:get_value(self.big_chest_savegame) then
	  self:disable_hud_element()
	  self.hero:set_position(self.entity_x, self.entity_y + 5)
	  sol.audio.set_music_volume(0)
      sol.audio.play_sound("/common/chest_opening")
      sol.audio.play_sound("/common/chest_open")
	  self.hero:get_sprite():set_ignore_suspend(true)
	  self.hero:set_animation("drop")
	  entity:get_sprite():set_animation("opening")
	  entity:set_direction(1)
	  entity:set_drawn_in_y_order(false)
	  sol.timer.start(self, 1500, function()
	    sol.audio.play_sound("/common/chest_creak")
        self.hero:set_animation("jumping")
        entity:set_direction(2)
		sol.timer.start(self, 30, function()
		  self.hero:set_animation("stopped")
		  sol.timer.start(self, 70, function()
		    entity:set_direction(3)
			sol.timer.start(self, 200, function()
			  self.hero:set_animation("walking")
              self:start_movement(1, 1)
			  sol.timer.start(self, 200, function()
			    self.hero:set_animation("hurt")
				sol.timer.start(self, 100, function()
				  self.hero:set_direction(0)
                  self:start_movement(1, 5)
				  self.hero:set_animation("chest_sequence")
				  sol.audio.play_sound("/characters/link/voice/jump1")
				  sol.timer.start(self, 500, function()
				    self.hero:set_direction(1)
				    sol.timer.start(self, 700, function()
					  self.hero:set_direction(2)
					  sol.timer.start(self, 1400, function()
					    self.hero:set_direction(1)
						sol.timer.start(self, 800, function()
						  self.hero:set_animation("chest_sequence")
						  self.hero:set_direction(0) 
						  self:start_movement(3, 15)
						  sol.timer.start(self, 400, function()
						    self.hero:set_direction(1)
							entity:set_drawn_in_y_order(true)
							self.hero:set_animation("walking")
							sol.timer.start(self, 500, function()
							  self.hero:set_animation("stopped")
							  sol.timer.start(self, 500, function()
							    self.game:set_hud_enabled(true)
								self.game:set_clock_enabled(true)
								self.hero:set_direction(2)
								sol.timer.start(self, 100, function()
								  self.hero:set_direction(3)
								  self.hero:set_animation("chest_holding_before_brandish")
								  sol.timer.start(self, 1100, function()
								    self.game:set_dialog_position("bottom")
									self.hero:start_treasure(self.treasure)
									self.game:set_pause_allowed(true)
									self.game:set_suspended(false)
									self.hero:get_sprite():set_ignore_suspend(false)
									self.game:set_value(self.big_chest_savegame, true)
									sol.menu.stop(self)
								  end)
								end)
							  end)
							end)
						  end)
						end)
					  end)
					end)
				  end)
				end)
			  end)
			end)
		  end)
		end)
	  end)
	elseif self.hero:get_direction() ~= 1 and not self.game:get_value(self.big_chest_savegame) then
	  self:wrong_direction()
	end
	
  elseif type_of_chest == 1 then
    if self.hero:get_direction() == entity:get_direction() and not self.game:get_value(self.small_chest_savegame) then
	
	  self.game:set_suspended(true)
	  if entity:get_direction() == 0 then 
        self.hero:set_position(self.entity_x - 16, self.entity_y)
      elseif entity:get_direction() == 1 then
        self.hero:set_position(self.entity_x, self.entity_y + 16)
      elseif entity:get_direction() == 2 then
        self.hero:set_position(self.entity_x + 16, self.entity_y)
      else
        self.hero:set_position(self.entity_x, self.entity_y - 16)
      end
	  
	  sol.timer.start(self, 1, function()
        self.hero:set_animation("drop")
		sol.timer.start(self, 200, function()
          if self.hero:get_direction() == 3 or self.hero:get_direction() == 1 then
			self.hero:set_animation("stopped")
		  else
			self.hero:set_animation("grabbing")
		  end
		  sol.timer.start(self, 100, function()
		    if self.hero:get_direction() == 0 or self.hero:get_direction() == 2 then
			  self.hero:set_animation("stopped")
			end
			entity:get_sprite():set_animation("open")
		    entity:get_sprite():set_direction(0)
		    sol.audio.play_sound("/common/chest_open")
			sol.timer.start(self, 300, function()
			  self.hero:set_animation("stopped")
			  if self.hero:get_direction() == entity:get_direction() then
				if entity:get_direction() == 0 or entity:get_direction() == 2 then
				  self.hero:set_direction(3)
				elseif entity:get_direction() == 1 then
				  self.hero:set_direction(2)
				end
			  end
			  sol.timer.start(self, 150, function()
			    self.hero:set_animation("chest_holding_before_brandish")
				sol.timer.start(self, 750, function()
				  self.game:show_cutscene_bars(true)
				  self.hero:unfreeze()
				  self.hero:start_treasure(self.treasure)
				  self.hero:set_animation("brandish_alternate")
				  entity:set_drawn_in_y_order(false)
				  self.game:set_suspended(false)
				  self.game:set_pause_allowed(true)
				  self.hero:set_direction(entity:get_direction())
				  self.game:set_value(self.small_chest_savegame, true)
				  sol.menu.stop(self)
				end)
			  end)		  
			end)
		  end)
		end)
      end)
    elseif self.hero:get_direction() ~= entity:get_direction() and not self.game:get_value(self.small_chest_savegame) then
	  self:wrong_direction()
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