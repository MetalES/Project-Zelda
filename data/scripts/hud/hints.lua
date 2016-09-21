local hints = {
  show_hints = false,
  was_displaying_hint = false
}

function hints:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self
  
  self.game = game
  
  -- Display a hints
  function game:show_hint(key, seconds)
    sol.menu.start(self, hints, false)
    hints:display_hint(key, seconds)
  end
  
  return object
end

function hints:display_hint(hint, seconds)
  self.surface = sol.surface.create(110, 90)
  self.surface:fill_color({0, 0, 0, 230})
  self.surface:set_xy(110, 0)
  
  sol.audio.play_sound("common/hint_notification")
  
  local text = sol.language.get_string("hints." .. hint)
  local i = 0
  local language = sol.language.get_language()
  local font = language == "jp" and "wqy-zenhei" or "minecraftia"
  local size = language == "jp" and 12 or 8
 
  self.text = sol.text_surface.create({
    vertical_alignement = "middle",
    horizontal_alignement = "left",
    font = font,
    font_size = size,
  })
  
  -- format the text
  for line in text:gmatch("[^$]+") do
    i = i + 1
	if i > 1 then
	  self.text:set_font_size(6)
	end
    self.text:set_text(line)
    self.text:draw(self.surface, 4, 7 + ((i - 1) * 8))
  end
  
  self.show_hints = true
  self.surface:fade_in(5)
  local movement = sol.movement.create("straight")
  movement:set_angle(2 * math.pi / 2)
  movement:set_speed(500)
  movement:set_max_distance(110)
  movement:start(self.surface, function()
    sol.timer.start(seconds, function()
      self.surface:fade_out(5, function() 
	    -- self.surface:clear()
	    self.text:set_text(nil) 
		self.show_hints = false 
	  end)
    end)
  end)
end

-- function hints:on_paused()
  -- if self.text ~= nil then
    -- if self.text:get_text() ~= nil then
      -- self.was_displaying_hint = self.show_hints
      -- self.show_hints = false 
	-- end
  -- end
-- end

-- function hints:on_unpaused()
  -- if self.was_displaying_hint then
    -- self.was_displaying_hint = false
    -- self.show_hints = true
  -- end
-- end

function hints:on_draw(dst)
  if not self.game:is_paused() then
    self.surface:draw(dst, 210, 75)
  end
end

return hints