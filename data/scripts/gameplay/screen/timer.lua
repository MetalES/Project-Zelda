local time_display = {}

-- Display a timer in the HUD, similar to the one in OOT.
-- Time is formated with os.date so the time displayed = hh:mm:ss instead of milliseconds.
-- So timer at 60 000 milliseconds will display 00:01:00

function time_display:on_started()

  self.timer_bitmap = sol.surface.create("hud/timer.png") -- image of the timer.
  self.folder = "timer/countdown_hud/" -- folder where the sounds are stored

  -- Create the text surface. Apply the os.date formatting here first
  self.time_remaining_text = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    font = "lttp",
	font_size = "16",
	text = os.date("!%X",self.timer:get_remaining_time() / 1000 - 1) -- use -1 to display 00:00:00 when the timer end.
  }
  
  self.timer2_inc = 0 -- used to play the sound
  self.timer3_inc = 0 -- used to play the sound

  self:update_time() -- start the sound
end

function time_display:get_info(context, timer, suspend_with_map)
  self.context = context -- Get the context of the timer (game, map or sol.main)
  
  if context == sol.main.game:get_map() then -- Check if this timer is affiled with a map, if true, the script is stopped if the current map is finished.
	context.on_finished = function()
	  sol.menu.stop(self)
	end
  end
  
  self.timer = timer -- The timer
  self.timer_is_suspended_with_map = suspend_with_map -- Is the timer suspended if the map is paused ?
end

function time_display:update_time()
 -- Starts a timer
  local t = sol.timer.start(self, 1000, function()
    self.time_remaining_text:set_text(os.date("!%X", self.timer:get_remaining_time() / 1000 - 1)) -- Refresh the timer
	
	if self.timer:get_remaining_time() <= 11000 and self.timer:get_remaining_time() > 0 then
	  sol.audio.play_sound(self.folder .. "2")
	  self.time_remaining_text:set_color({255, 0, 0})
	  self.timer2_inc = 0
	  
	elseif self.timer:get_remaining_time() <= 31000 and self.timer:get_remaining_time() > 10000 then
	  self.time_remaining_text:set_color({255, 255, 0})
	  self.timer2_inc = self.timer2_inc + 1
	  self.timer3_inc = 0
	  
      if self.timer2_inc == 2 then
	    sol.audio.play_sound(self.folder .. "1")
	    self.timer2_inc = 0
	  end
	  
	elseif self.timer:get_remaining_time() > 31000 then
	  self.timer3_inc = self.timer3_inc + 1
	  self.time_remaining_text:set_color({255, 255, 255})
	  
	  if self.timer3_inc == 10 then
		sol.audio.play_sound(self.folder .. "0")
	    self.timer3_inc = 0
	  end
	end
	
  if self.timer:get_remaining_time() == 0 then  
    sol.menu.stop(self)
  end
	
  return self.timer:get_remaining_time() > 1
  end)
  t:set_suspended_with_map(self.timer_is_suspended_with_map)
end


function time_display:on_finished()
  sol.timer.stop_all(self)
end

function time_display:on_draw(dst_surface)
  if not sol.main.game:is_paused() and not sol.main.game:is_suspended() then
    self.timer_bitmap:draw(dst_surface, 15, 49)
    self.time_remaining_text:draw(dst_surface, 35, 57)
  end
end

return time_display