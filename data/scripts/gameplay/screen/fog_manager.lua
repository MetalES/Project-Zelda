return function(game)
  local fog_menu = {}
  local movement

  function game:display_fog(fog, speed, angle, opacity)
    local fog = fog or nil
    local speed = speed or 1
    local angle = angle or 0
    local opacity = opacity or 16

    self:clear_fog()
	
    fog_menu.fog = fog
    fog_menu.fog_speed = speed
    fog_menu.fog_angle = angle
    fog_menu.fog_opacity = opacity

    sol.menu.start(self:get_map(), fog_menu, false)
  end

  function game:clear_fog()
    if fog_menu.fog_sfc ~= nil then fog_menu.fog_sfc:clear() end
  
    fog_menu.fog = nil
    fog_menu.fog_speed = nil
    fog_menu.fog_angle = nil
    fog_menu.fog_opacity = nil
    if fog_menu.movement ~= nil then fog_menu.movement:stop() end
    fog_menu.fog_sfc = nil
  end

  function fog_menu:on_started()
    self:display_fog()	
  end

  function fog_menu:on_finished()
    game:clear_fog()
  end

  function fog_menu:display_fog()	
    if type(self.fog) == "string" then
      self.fog_sfc = sol.surface.create("fogs/".. self.fog ..".png")
      self.fog_sfc:set_opacity(self.fog_opacity)
	  self.fog_size_x, self.fog_size_y = self.fog_sfc:get_size()
    
	  function restart_overlay_movement()
	    self.movement = sol.movement.create("straight")
	    self.movement:set_speed(self.fog_speed) 
	    self.movement:set_max_distance(((self.fog_size_x + self.fog_size_y) / 1.4) - 4)
	    self.movement:set_angle(self.fog_angle * math.pi / 4)
	    self.movement:start(self.fog_sfc, function()
		  self.fog_sfc:set_xy(self.fog_size_x, self.fog_size_y)
		  restart_overlay_movement()
	    end)
      end
	  restart_overlay_movement()
    end
  end

  function fog_menu:on_draw(dst_surface)
    local scr_x, scr_y = dst_surface:get_size()
	
	
    if self.fog ~= nil then
	  local camera_x, camera_y = game:get_map():get_camera_position()
	  local overlay_width, overlay_height = self.fog_sfc:get_size()
	  local x, y = camera_x, camera_y
	  x, y = -math.floor(x), -math.floor(y)
	  x = x % overlay_width - 2 * overlay_width
	  y = y % overlay_height - 2 * overlay_height
	  
	  local dst_y = y
	  while dst_y < scr_y + overlay_height do
	    local dst_x = x
	    while dst_x < scr_x + overlay_width do
	      self.fog_sfc:draw(dst_surface, dst_x, dst_y)
		  dst_x = dst_x + overlay_width
	    end
	    dst_y = dst_y + overlay_height
	  end
    end
  end
end