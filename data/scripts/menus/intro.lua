local game = ...
local intro = {}  -- The credits menu.
local text_width, text_height = 0
local progression = 0
local draw_fresco = false

function game:start_intro()
  sol.menu.start(game:get_map(), intro)
end

function intro:on_started()
  sol.audio.play_music("cutscene/intro", false)
  local map = game:get_map()
  local hero = game:get_hero()
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

  function end_credits()
    -- Credits over. Now what?
    game:start_dialog("_credits", function(answer)
      if answer == 1 then
        -- Save and continue.
        game:save()
        game:start()
      else
        -- Quit (don't save).
        sol.main.reset()
      end
    end)
  end

  sol.timer.start(map,1, function()
    show_group(1)
	progression = 1
    sol.timer.start(map, 10000, function()
	  draw_fresco = true
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
                  sol.timer.start(map, 6000, function() end_credits() end)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

function intro:on_finished()
  self.game:get_hero():teleport("test")
end

function intro:on_draw(dst_surface)
  local camera_x, camera_y, camera_width, camera_height = game:get_map():get_camera_position()
  local intro_background = sol.surface.create(320, 240)
  local fresco_background = sol.surface.create("scene/intro/background")
  
  if draw_fresco ~= true then
	intro_background:fill_color({0,0,0})
	intro_background:draw(dst_surface)
  else
	fresco_background:draw(dst_surface)
  end
  if self.group ~= nil then
    self.group:draw(dst_surface, (camera_width/2)-150, (camera_height/2)-80)
  end
end