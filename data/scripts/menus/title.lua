-- Title screen of the game.
-- Modification : Title screen is now on map.

local title_screen = {}

function title_screen:on_started()

  -- black screen during 0.3 seconds
  self.phase = "black"

  self.surface = sol.surface.create(320, 240)
  sol.timer.start(self, 300, function()
    self:phase_zs_presents()
  end)

  -- use these 0.3 seconds to preload all sound effects and also check if the title screen map exist
  sol.audio.preload_sounds()
end

function title_screen:phase_zs_presents()

  -- "Zelda Solarus presents" displayed for two seconds
  self.phase = "zs_presents"

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

function title_screen:phase_title()
  -- actual title screen
  -- self.phase = "title"
  -- sol.menu.stop(self)
  -- sol.main:start_savegame(self.savegame)

  -- start music
  -- sol.audio.play_music("menu_title_screen")
  

  self.show_press_space = false  

sol.timer.start(self, 6500, function() switch_press_space() self.show_press_space = true end)
  -- show an opening transition
  self.surface:fade_in(30)

  self.allow_skip = false
  sol.timer.start(self, 2000, function()
    self.allow_skip = true
  end)
end

function title_screen:on_draw(dst_surface)

  if self.phase == "title" then
    self:draw_phase_title(dst_surface)
  end

  -- final blit (dst_surface may be larger)
  local width, height = dst_surface:get_size()
  self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

function title_screen:draw_phase_title()

  -- background
  self.surface:fill_color({0, 0, 0})

  -- website name and logo
  self.website_img:draw(self.surface, 160, 220)
  self.logo_img:draw(self.surface, 88, 30) -- 88 40

  if self.show_press_space then
    self.press_space_img:draw(self.surface, 160, 200)
  end

end

function title_screen:on_key_pressed(key)

  local handled = false

  if key == "escape" then
    -- stop the program
    sol.main.exit()
    handled = true

  elseif key == "space" or key == "return" then
    handled = self:try_finish_title()

--  Debug.
  elseif sol.main.is_debug_enabled() then
    if key == "left shift" or key == "right shift" then
      self:finish_title()
      handled = true
    end
  end
end

function title_screen:on_joypad_button_pressed(button)

  return self:try_finish_title()
end

-- Ends the title screen (if possible)
-- and starts the savegame selection screen
function title_screen:try_finish_title()

  local handled = false

  if self.phase == "title"
      and self.allow_skip
      and not self.finished then
    self.finished = true

    self.surface:fade_out(30)
    sol.timer.start(self, 700, function()
      self:finish_title()
    end)

    handled = true
  end

  return handled
end

function title_screen:finish_title()

  sol.audio.stop_music()
  sol.menu.stop(self)
end

return title_screen