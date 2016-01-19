local game = ...
local fog_menu = {}

function game:display_fog(fog, speed, angle, opacity)
--The fog are map related so it is logical that object pointer are map related.

    local fog = fog or nil
	local speed = speed or 1
	local angle = angle or 0
	local opacity = opacity or 16
	-- self:get_map().fog_opacity_variation = opacity_variation or nil
	-- self:get_map().fog_opacity_min = opacity_min or nil
	-- self:get_map().fog_opacity_max = opacity_max or nil
	-- self:get_map().fog_time_between_transition = time_between_transition or nil
	self:clear_fog()
	
	self:set_value("current_fog", fog)
	self:set_value("current_fog_speed", speed)
	self:set_value("current_fog_angle", angle)
	self:set_value("current_fog_opacity", opacity)
	
	sol.menu.start(self:get_map(), fog_menu, true) -- the menu is displayed above the map.
end

-- this event is called in quest_manager in on_started, call it from anyhere if you need to clean the fog
function game:clear_fog()
self.clear_all_fog = true
self:set_value("fog_is_drawn", false)
self:set_value("current_fog", nil)
self:set_value("current_fog_speed", 0)
self:set_value("current_fog_angle", 0)
self:set_value("current_fog_opacity", 0)
end

function fog_menu:on_started()
  self:check()
end

function fog_menu:on_finished()
  self.game:clear_fog()
end

-- Checks whether the view displays the correct fog
-- and updates it if necessary.
function fog_menu:check()
  if not game:get_value("fog_is_drawn") and game:get_value("current_fog") ~= nil then 
    self:display_fog()
    game:set_value("fog_is_drawn", true)
  elseif not game:get_value("fog_is_drawn") and game:get_value("current_fog") == nil then
    sol.timer.start(self, 50, function()
      self:check()
    end)
  end  
end

function fog_menu:display_fog()	
	if type(game:get_value("current_fog")) == "string" then
	  self.fog = sol.surface.create("fogs/"..game:get_value("current_fog")..".png")
      self.fog:set_opacity(game:get_value("current_fog_opacity"))
	  self.fog_size_x, self.fog_size_y = self.fog:get_size()
      self.fog_m = sol.movement.create("straight")
	  
	  function restart_overlay_movement()
		self.fog_m:set_speed(game:get_value("current_fog_speed")) 
		self.fog_m:set_max_distance(self.fog_size_x)
		self.fog_m:set_angle(game:get_value("current_fog_angle") * math.pi / 4)
		self.fog_m:start(self.fog, function()
			restart_overlay_movement()
			self.fog:set_xy(self.fog_size_x, self.fog_size_y)
		end)
      end
	  restart_overlay_movement()
    end
end

function fog_menu:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function fog_menu:on_draw(dst_surface)
local scr_x, scr_y = dst_surface:get_size()
	if game:get_value("current_fog") ~= nil then
	  local camera_x, camera_y = game:get_map():get_camera_position()
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
	elseif game.clear_all_fog then 
	  self.fog:clear()
	end
end

return fog_menu

