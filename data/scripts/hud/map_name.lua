local map_name = {}

function map_name:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function map_name:initialize(game)
local horizontal_alignment = "center"
local vertical_alignment = "middle"
local font = "map_name"

  self.game = game
  
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
end

function map_name:on_started()
  self:check()
end

-- Checks if there is any map_name
-- and updates it if necessary.
function map_name:check()
  
  if not self.game:get_value("map_name_displaying") and self.game:get_value("previous_map_name_displayed") ~= nil then 
  self:display_map_name()
  self.game:set_value("map_name_displaying", true)
  end  
  
  -- Schedule the next check.
  sol.timer.start(self, 50, function()
    self:check()
  end)
end

function map_name:display_map_name()
local remaining_time = 500

 if type(self.game.map_name_string) == "string" then
  if (type(self.game.display_extra) == "string" and self.game.display_extra ~= "boss_name") or type(self.game.display_extra) == "nil" then
   	self.map_name:set_text_key("map.gameplay.map_name."..self.game.map_name_string)
	self.mx, self.my = self.map_name:get_size()
    self.map_name_surface = sol.surface.create(self.mx * 2, self.my)
    self.map_name:draw(self.map_name_surface, self.mx, self.my * 0.5)	  
    self.map_name_surface:set_opacity(0) 
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
		   self.map_name:draw(self.map_name_surface, self.mx, self.my * 0.5)
		   self.map_name_surface:set_opacity(0) 
	   else
		   self.boss_presentation_text:set_text(text_lines)
		   local tw, th = self.boss_presentation_text:get_size()
		   self.boss_presentation_text:draw(self.map_name_surface, self.mx - 7 , (self.my * 0.5) + (i*7))
		   if tw > self.mx then self.mx = tw end
		   if th > self.my then self.my = th end
	   end
	end
  end		
		
		self.game:get_map().map_name_timer = sol.timer.start(self.game:get_map(), 500, function()
			self.map_name_surface:fade_in(40)
			self.game:get_map().map_name_timer2 = sol.timer.start(self.game:get_map(), 3500, function()
				self.map_name_surface:fade_out(40, function()
				  self.map_name_surface:clear()
				  self.game:set_value("map_name_displaying", false)
				  self.game:set_value("previous_map_name_displayed", nil)
				end)
			end)
		end)
      end
end

function map_name:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function map_name:on_draw(dst_surface)
local scr_x, scr_y = dst_surface:get_size()
	if self.game:get_value("previous_map_name_displayed") ~= nil then
	  local map_name_width, map_name_height = self.map_name:get_size()
	  if self.display_boss_name then
	     self.map_name_surface:draw(dst_surface, (scr_x / 2) - (map_name_width) + 3, (scr_y / 2) + (map_name_height * 4.8))
	  elseif not display_boss_name then
	     self.map_name_surface:draw(dst_surface, (scr_x / 2) - (map_name_width), (scr_y / 2) - (map_name_height * 3))
	  elseif self.game.clear_all_map_name then
	     self.map_name_surface:set_opacity(0)
	     self.map_name_surface:clear()
	     self.game.clear_all_map_name = false
	  end
	end

end

return map_name

