local game = ...
local credits_menu = {
  time_between_groups = {
    {10000, 1000},
	{10000, 200},
	{10000, 200}
  },
  texts = {}

}  -- The credits menu.

--Todo parse the final credits from a lua file
function game:a()--start_end_credit()
  sol.menu.start(self, credits_menu)
  game:show_cutscene_bars(true)
end

function credits_menu:on_finished()
  sol.timer.stop_all(self)
end

function credits_menu:on_started()
  sol.audio.play_music("credits")
  
  local map = game:get_map()
  local hero = game:get_hero()

  self.title = sol.text_surface.create{
    font = "lttp",
    font_size = "14",
    horizontal_alignment = "center",
    vertical_alignment = "top"
  }
  
  self.line = {}

  game:set_hud_enabled(false)
  game:set_pause_allowed(false)
  game:set_clock_enabled(false)
  
  self.displayed_group = 1
  self:start_credits_phase_1(self.displayed_group)
  
end

function credits_menu:start_credits_phase_1(index)
  local i = 0
  self.group = sol.surface.create(320,240)
  self.group:fade_in(50)
  
  if index == 4 then
  
    self.group:fill_color({0, 0, 0, 255})
  
    game:start_dialog("_credits", function(answer)
      if answer == 1 then
        game:save()
        game:start()
      else
        sol.main.reset()
      end
    end)
	return
  end
  
  local text_group = sol.language.get_string("credits." .. index)
  for text_lines in text_group:gmatch("[^$]+") do
	i = i + 1
	self.texts[i] = sol.text_surface.create({
	  font = "lttp",
      font_size = "14",
      horizontal_alignment = "center",
      vertical_alignment = "top",
	  text = text_lines
	})
	
	local function do_movement(target)
	  local movement = sol.movement.create("straight")
	  movement:set_angle(math.pi / 2)
      movement:set_speed(8)
	  movement:set_max_distance(8)
	  
	  if i == 1 then
	    target[i]:fade_in(50)
	    movement:start(target[1])
	  else
	    sol.timer.start(200, function()
		  target[i]:fade_in(50)
	      movement:start(target[i])
		end)
	  end
	end
	
	-- do_movement(self.texts)
	-- self.line:draw(self.group, 160, 0 + (i * 15))
  end
  
  sol.timer.start(self, self.time_between_groups[index][1], function()
    self.group:fade_out(50, function()
	  sol.timer.start(self, self.time_between_groups[index][2], function()
	    if self.displayed_group ~= 1 then
	      self.displayed_group = self.displayed_group + 1
		  self:start_credits_phase_1(self.displayed_group)
		else
		  self.group = nil
		  
		  self:second_phase()
		end
	  end)
	end)
  end)
end


function credits_menu:second_phase()
  local file = require("scripts/gameplay/screen/final_credit_text")
  local matched = 0
  self.group = sol.surface.create(320,2800)
  self.group:fill_color({0, 0, 0, 255})
  sol.audio.play_music("cutscene/credits")
  
  self:draw_mozaics()
  
  for i = 1, #file do
    local text = file[i]
    if text:match("£") then
	  matched = 2
	  self.line:set_color({255, 50, 50})
	  text:gsub("£", "") 
	else
	  matched = 0
	  self.line:set_color({255, 255, 255})
	end
	self.line:set_text(text)
	self.line:draw(self.group, 160 - matched, 222 + (i * 15))
  end
  
  -- The Text has been parsed, we no longer need it.
  file = nil
  
  local movement = sol.movement.create("straight")
  movement:set_angle(math.pi / 2)
  movement:set_speed(16)
  movement:start(self.group)
  
  function movement:on_position_changed()
    print(movement:get_xy())
  end
end

--todo
function credits_menu:draw_mozaics()
  self.mozaics = sol.sprite.create("menus/end_credits/surface")
  self.draw_mozaics = true
  
  local x = {20, 140}
  
  local function manage()
  
  
  end
end

function credits_menu:on_draw(dst_surface)
  if self.group ~= nil then
    self.group:draw(dst_surface)
  end
  
  for i = 1, #self.texts do
    if self.texts[i] ~= nil then
	  self.texts[i]:draw(dst_surface, 160, 40 + (i * 15))
	end
  end
  
end