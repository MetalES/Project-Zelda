local map = ...
local text_width, text_height = 0
local progression = 0
local draw_fresco = false

function map:on_started()
  sol.audio.play_music("cutscene/intro", false)
  self.intro_surface = sol.surface.create(320,240)
  self.fresco_background = sol.surface.create("scene/intro/background.png")
  self.heading = sol.text_surface.create{
    font = "lttp",
    font_size = "14",
    horizontal_alignment = "center",
    vertical_alignment = "top"
  }
  self.line = sol.text_surface.create{
    font = "lttp",
    font_size = "14",
    horizontal_alignment = "center",
    vertical_alignment = "top"
  }

  map:get_hero():set_position(-100, -100)
  map:get_hero():freeze()
  map:get_game():set_hud_enabled(false)
  map:get_game():set_pause_allowed(false)
  map:get_game():disable_all_input()

  function show_group(index)
    local i = 0
	local new_y = 65
    self.group = sol.surface.create(320,240)
    local text_group = sol.language.get_string("intro."..index - 1)
    for text_lines in string.gmatch(text_group, "[^$]+") do
      i = i + 1
	  
	  if progression ~= 0 then new_y = 165 end
	  
      if i == 1 then
        self.heading:set_text(text_lines)
        self.heading:draw(self.group, 150, new_y) -- y = 65 1st time
        text_width, text_height = self.heading:get_size()
      else
        self.line:set_text(text_lines)
        self.line:draw(self.group, 150, new_y + (i*7))
        tw, th = self.line:get_size()
        if tw > text_width then text_width = tw end
        if th > text_height then text_height = th end
      end
    end

    self.group:fade_in(50, function()
      sol.timer.start(map, 15000, function()
        self.group:fade_out(50, function()
          return true
        end)
      end)
    end)
  end

  sol.timer.start(map,1, function()
    show_group(1)
	progression = 1
    sol.timer.start(map, 10000, function()
	  draw_fresco = true
	  local fresco_background_mvt = sol.movement.create("straight")
	  fresco_background_mvt:set_speed(16) 
      fresco_background_mvt:set_angle(2*math.pi/2)
      fresco_background_mvt:start(self.fresco_background)
   	  self.fresco_background:fade_in(50)
      show_group(2)
      sol.timer.start(map, 10000, function()
        show_group(3)
        sol.timer.start(map, 10000, function()
          show_group(4)
          sol.timer.start(map, 10000, function()
            show_group(5)
            sol.timer.start(map, 10000, function()
              show_group(6)
              sol.timer.start(map, 10000, function()
                show_group(7)
                sol.timer.start(map, 10000, function()
                  show_group(8)
                  sol.timer.start(map, 6000, function() end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

function map:on_draw(dst_surface)
  local camera_x, camera_y, camera_width, camera_height = self:get_camera_position()
  local overlay_width, overlay_height = self.fresco_background:get_size()
  local screen_width, screen_height = dst_surface:get_size()
  local x, y = camera_x, camera_y
  x, y = -math.floor(x), -math.floor(y)
  x = x % overlay_width - 6 * overlay_width
  y = y % overlay_height - 6 * overlay_height
  
  local dst_y = y
  while dst_y < screen_height + overlay_height do
    local dst_x = x
    while dst_x < screen_width + overlay_width do
      -- Repeat the overlay's pattern.
      self.fresco_background:draw(dst_surface, dst_x + 1920 , dst_y)
      dst_x = dst_x + overlay_width
    end
    dst_y = dst_y + overlay_height
  end
  
  if draw_fresco ~= true then
	self.intro_surface:fill_color({0,0,0})
	self.intro_surface:draw(dst_surface)
  end
  
  if self.group ~= nil then
    self.group:draw(dst_surface, (camera_width/2)-150, (camera_height/2)-80)
  end
end