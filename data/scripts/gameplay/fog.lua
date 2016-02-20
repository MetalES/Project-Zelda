local game = ...
local fog_menu = {}
local movement

function game:display_fog(fog, speed, angle, opacity)
    local fog = fog or nil
	local speed = speed or 1
	local angle = angle or 0
	local opacity = opacity or 16

	self:clear_fog()
	
	self:get_map().fog = fog
	self:get_map().fog_speed = speed
	self:get_map().fog_angle = angle
	self:get_map().fog_opacity = opacity
	self:get_map().fog_has_been_drawn = false
	
	sol.menu.start(self:get_map(), fog_menu, true)
end

function game:clear_fog()
  self.clear_all_fog = true
  self:get_map().fog = nil
  self:get_map().fog_speed = 1
  self:get_map().fog_angle = 0
  self:get_map().fog_opacity = 0
  self:get_map().fog_has_been_drawn = false
  if movement ~= nil then movement:stop() end
end

function fog_menu:on_started()
  self.game = game
  self:check()
end

function fog_menu:on_finished()
  movement:stop()
end

function fog_menu:check()
  if not self.game:get_map().fog_has_been_drawn and self.game:get_map().fog ~= nil then 
    self:display_fog()
    self.game:get_map().fog_has_been_drawn = true
  elseif not self.game:get_map().fog_has_been_drawn and self.game:get_map().fog == nil then
    sol.timer.start(self, 50, function()
      self:check()
    end)
  end  
end

function fog_menu:display_fog()	
	if type(self.game:get_map().fog) == "string" then
	  self.fog = sol.surface.create("fogs/"..self.game:get_map().fog..".png")
      self.fog:set_opacity(self.game:get_map().fog_opacity)
	  self.fog_size_x, self.fog_size_y = self.fog:get_size()
      movement = sol.movement.create("straight")
	  
	  function restart_overlay_movement()
		movement:set_speed(self.game:get_map().fog_speed) 
		movement:set_max_distance(((self.fog_size_x + self.fog_size_y) / 1.4) - 4)
		movement:set_angle(self.game:get_map().fog_angle * math.pi / 4)
		movement:start(self.fog, function()
			self.fog:set_xy(self.fog_size_x, self.fog_size_y)
			restart_overlay_movement()
		end)
      end
	  restart_overlay_movement()
    end
end


function fog_menu:on_draw(dst_surface)
local scr_x, scr_y = dst_surface:get_size()
	if self.game:get_map().fog ~= nil then
	  local camera_x, camera_y = self.game:get_map():get_camera_position()
	  local overlay_width, overlay_height = self.fog:get_size()
	  local x, y = camera_x, camera_y
	  x, y = -math.floor(x), -math.floor(y)
	  x = x % overlay_width - 2 * overlay_width --2
	  y = y % overlay_height - 2 * overlay_height
	  local dst_y = y
	  while dst_y < scr_y + overlay_height do
		local dst_x = x
		while dst_x < scr_x + overlay_width do
		  self.fog:draw(dst_surface, dst_x, dst_y)
		  dst_x = dst_x + overlay_width
		end
		dst_y = dst_y + overlay_height
	  end
	elseif self.game.clear_all_fog then 
	  self.fog:clear()
	end
end

return fog_menu