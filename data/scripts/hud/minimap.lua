local minimap = {}

function minimap:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function minimap:initialize(game)
  self.game = game
  
  -- dummy surface, will be resized later depending on the lengh of the text.
  self.surface = sol.surface.create("hud/minimap/border.png")
  
  self.dst_x = 0
  self.dst_y = 0
end

function minimap:on_started()
  self:check()
end

-- Checks if there is any minimap
-- and updates it if necessary.
function minimap:check()
  
  if not self.game:get_value("minimap_displaying") and self.game:get_value("previous_minimap_displayed") ~= nil then 
  self:display_minimap()
  self.game:set_value("minimap_displaying", true)
  end  
  
  -- Schedule the next check.
  sol.timer.start(self, 50, function()
    self:check()
  end)
end

function minimap:display_minimap()
local remaining_time = 500

 if type(self.game.minimap_string) == "string" then
  if (type(self.game.display_extra) == "string" and self.game.display_extra ~= "boss_name") or type(self.game.display_extra) == "nil" then
   	self.minimap:set_text_key("map.gameplay.minimap."..self.game.minimap_string)
	self.mx, self.my = self.minimap:get_size()
    self.minimap_surface = sol.surface.create(self.mx * 2, self.my)
	self.minimap_surface:set_opacity(0)
    self.minimap:draw(self.minimap_surface, self.mx, self.my * 0.5)	  
	self.display_boss_name = false			
  else
    self.display_boss_name = true		
	local i = 0
	local text_group = sol.language.get_string("map.gameplay.boss_name."..self.game.minimap_string)
	for text_lines in string.gmatch(text_group, "[^$]+") do
	  i = i + 1
	   if i == 1 then
		   self.minimap:set_text(text_lines)
		   self.mx, self.my = self.minimap:get_size()
		   self.minimap_surface = sol.surface.create(self.mx * 2 , self.my * 4)
		   self.minimap_surface:set_opacity(0) 
		   self.minimap:draw(self.minimap_surface, self.mx, self.my * 0.5)
	   else
		   self.boss_presentation_text:set_text(text_lines)
		   local tw, th = self.boss_presentation_text:get_size()
		   self.boss_presentation_text:draw(self.minimap_surface, self.mx - 7 , (self.my * 0.5) + (i*7))
		   if tw > self.mx then self.mx = tw end
		   if th > self.my then self.my = th end
	   end
	end
  end		
		
		self.game:get_map().minimap_timer = sol.timer.start(self.game:get_map(), 500, function()
			self.minimap_surface:fade_in(40)
			self.game:get_map().minimap_timer:stop()
		end)
		
		self.game:get_map().minimap_timer2 = sol.timer.start(self.game:get_map(), 4000, function()
			self.minimap_surface:fade_out(40, function()
			  self.minimap_surface:clear()
			  self.game:set_value("minimap_displaying", false)
			  self.game:set_value("previous_minimap_displayed", nil)
			end)
			self.game:get_map().minimap_timer2:stop()
		end)
      end
end

function minimap:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function minimap:on_draw(dst_surface)
self.surface:draw(dst_surface, self.dst_x, self.dst_y)
end

return minimap

