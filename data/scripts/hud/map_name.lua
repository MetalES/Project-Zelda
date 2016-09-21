local map_name = {}

function map_name:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self
  
  self:initialize(game)

  return object
end

function map_name:initialize(game)
  -- Map Name control
  function game:show_map_name(name, display_extra)
    sol.menu.start(self, map_name, false)
    map_name:show_name(name, display_extra or nil)
  end

  function game:clear_map_name()
    sol.menu.stop(map_name)
    map_name:clear()
  end
end

function map_name:show_name(name, extra)
  local horizontal_alignment = "center"
  local vertical_alignment = "middle"
  local font = "map_name"
  self.name = name

  -- dummy surface, will be resized later depending on the lengh of the text.
  self.map_name_surface = sol.surface.create(1,1) 
  
  self.dst_x = 0
  self.dst_y = 0
  
  self.map_name = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
	vertical_alignment = vertical_alignment,
	font = font, 
  }		
		  
  self.boss_presentation_text = sol.text_surface.create{
	horizontal_alignment = horizontal_alignment,
	vertical_alignment = vertical_alignment,
	font = font, 
  }	
  
  if self.timer ~= nil then self.timer:stop() end
  if self.timer0 ~= nil then self.timer0:stop() end
  
  if (type(extra) == "string" and extra ~= "boss_name") or type(extra) == "nil" then
   	self.map_name:set_text_key("map.gameplay.map_name." .. self.name)
	self.mx, self.my = self.map_name:get_size()
    self.map_name_surface = sol.surface.create(self.mx * 2, self.my)
	self.map_name_surface:set_opacity(0)
    self.map_name:draw(self.map_name_surface, self.mx, self.my * 0.5)	  
	self.display_boss_name = false			
  else
    self.display_boss_name = true		
	local i = 0
	local text_group = sol.language.get_string("map.gameplay.boss_name."..self.game.map_name_string)
	for text_lines in string.gmatch(text_group, "[^$]+") do
	  i = i + 1
	  if i == 1 then
		self.map_name:set_text(text_lines)
		self.mx, self.my = self.map_name:get_size()
		self.map_name_surface = sol.surface.create(self.mx * 2 , self.my * 4)
		self.map_name_surface:set_opacity(0) 
		self.map_name:draw(self.map_name_surface, self.mx, self.my * 0.5)
	  else
		self.boss_presentation_text:set_text(text_lines)
		local tw, th = self.boss_presentation_text:get_size()
		self.boss_presentation_text:draw(self.map_name_surface, self.mx - 7 , (self.my * 0.5) + (i*7))
		if tw > self.mx then self.mx = tw end
		if th > self.my then self.my = th end
	  end
	end
  end		
		
  self.timer = sol.timer.start(self, 500, function()
	self.map_name_surface:fade_in(40)
  end) 
  self.timer:set_suspended_with_map(false)
  
  self.timer0 = sol.timer.start(self, 3500, function()
	self.map_name_surface:fade_out(40, function()
	  self.map_name_surface:clear()
	  self.name = nil
	end)
  end)
  self.timer0:set_suspended_with_map(false)
end

function map_name:on_paused()
  if self.name ~= nil then
    self:clear()
  end
end

function map_name:clear()
  if self.name ~= nil then
    self.map_name:set_text("")
    self.map_name_surface:clear()
    self.name = nil
  end
end

function map_name:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function map_name:on_draw(dst_surface)
  local scr_x, scr_y = dst_surface:get_size()
  if self.name ~= nil then
	local map_name_width, map_name_height = self.map_name:get_size()
	if self.display_boss_name then
	  self.map_name_surface:draw(dst_surface, (scr_x / 2) - (map_name_width) + 3, (scr_y / 2) + (map_name_height * 4.8))
	elseif not self.display_boss_name then
	  self.map_name_surface:draw(dst_surface, (scr_x / 2) - (map_name_width), (scr_y / 2) - (map_name_height * 3))
	end
  end
end

return map_name