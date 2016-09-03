-- Title screen of the game.
-- Modification : Title screen is now on map.

local title_screen = {}

function title_screen:on_started()

  -- black screen during 0.3 seconds
  self.surface = sol.surface.create(320, 240)
  sol.timer.start(self, 300, function()
    self:phase_zs_presents()
  end)
  
end

function title_screen:phase_zs_presents()
  local zs_presents_img = sol.surface.create("title_screen_initialization.png", true)

  local width, height = zs_presents_img:get_size()
  local x, y = 160 - width / 2, 120 - height / 2
  zs_presents_img:draw(self.surface, x, y)
  sol.audio.play_sound("scene/title/presented_by")

  sol.timer.start(self, 2000, function()
    self.surface:fade_out(10)
    sol.timer.start(self, 700, function()
	  sol.menu.stop(self)
    end)
  end)
end

function title_screen:on_draw(dst_surface)
  local width, height = dst_surface:get_size()
  self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

return title_screen