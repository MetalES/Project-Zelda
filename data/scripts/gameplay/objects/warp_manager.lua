local warp_manager = {}

function warp_manager:on_started()
  self.game = sol.main.game
  self.map = self.game:get_map()
  self.hero = self.game:get_hero()
  
  local camera_x, camera_y = self.map:get_camera_position()
  local hero_x, hero_y = self.hero:get_position()
  self.x = hero_x - camera_x
  self.y = hero_y - camera_y
  
  sol.audio.play_sound("objects/warp/boss_warp")
  
  self.warp_crystal = sol.sprite.create("entities/misc/teleportation_crystal")
  self.hero_dummy = sol.sprite.create("hero/tunic"..self.game:get_ability("tunic"))
  self.hero_dummy:set_direction(self.hero:get_direction())
  self.timer_start = 600
  
  self.can_draw_hero_dummy = false
  self.can_draw_surface_black = false
  self.can_draw_surface_white = false
  self.can_draw_crystal = false
  
  self.surface_black = sol.surface.create(320, 240)
  self.surface_black:fill_color({0, 0, 0})
  
  self.surface_white = sol.surface.create(320, 240)
  self.surface_white:fill_color({255, 255, 255})

  self.can_draw_surface_black = true
  self.can_draw_hero_dummy = true
  
  self.surface_black:fade_in(200)
  
  sol.timer.start(900, function()
    self.can_draw_crystal = true
    self.warp_crystal:fade_in(200)
	self:update_direction()
  end)
  
  sol.timer.start(2400, function()
    sol.timer.start(100, function()
	  self.warp_crystal:set_frame_delay(self.warp_crystal:get_frame_delay() - 1)
	return self.warp_crystal:get_frame_delay() ~= 50
	end)
	sol.timer.start(6000, function()
	  self.can_draw_surface_white = true
	  self.surface_white:fade_in(40, function()
	    self.can_draw_crystal = false
		self.can_draw_hero_dummy = false
		self.can_draw_surface_black = false
		sol.audio.play_music(nil)
	    sol.timer.start(500, function()
		  self:warp()
		  self.game:fade_audio(self.game:get_value("old_volume"), 10)
		end)
	  end)
	end)
  end)
end

function warp_manager:set_dungeon_finished(number)
  self.dungeon_nbr = number
end

function warp_manager:get_finished_dungeon()
  return self.dungeon_nbr
end

function warp_manager:warp()
  local n = self:get_finished_dungeon()

  if not self.game:is_dungeon_finished(n) then
    self.hero:teleport("cutscene/scene_SageSanctuary/SageSanctuary", "from_dungeon", "fade") --warp to sage room
  else
    self.hero:teleport(self.map.teleport_destination, "from_dungeon_warp", "fade") --warp to the entrance of the dungeon.
  end
end

function warp_manager:update_direction()
  self.timer_start = self.timer_start - 20
  if self.timer_start <= 10 then
    self.timer_start = 10
  end
  sol.timer.start(self, self.timer_start, function()
    if self.hero_dummy:get_direction() == 0 then 
	  self.hero_dummy:set_direction(3)
	else
	  self.hero_dummy:set_direction(self.hero_dummy:get_direction() - 1)
	end
	if self.can_draw_hero_dummy then
	  self:update_direction()
	end
  end)
end

function warp_manager:fade_surface(times)
  self.surface_white:fade_out(times, function()
    sol.menu.stop(self)
	sol.timer.stop_all(self)
  end)
end

function warp_manager:on_draw(dst_surface)
  
  if self.can_draw_surface_black then
    self.surface_black:draw(dst_surface, 0, 0)
  end
  
  if self.can_draw_hero_dummy then
    self.hero_dummy:draw(dst_surface, self.x, self.y)
  end
  
  if self.can_draw_crystal then
    self.warp_crystal:draw(dst_surface, self.x, self.y - 24)
  end
  
  if self.can_draw_surface_white then
    self.surface_white:draw(dst_surface, 0, 0)
  end
end

return warp_manager