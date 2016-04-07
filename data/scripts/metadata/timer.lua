local timer_meta = sol.main.get_metatable("timer")
local timer, timer2, timer3, timer4
  
function timer_meta:set_with_sound_effect(boolean)  
  local game = sol.main.game
  if boolean then
  
    if timer ~= nil then timer:stop() end 
	if timer2 ~= nil then timer2:stop() end
	if timer3 ~= nil then timer3:stop() end
	if timer4 ~= nil then timer4:stop() end
		
	sol.audio.play_sound("timer")
	timer = sol.timer.start(self, 1525, function()
	  if self:get_remaining_time()  > 6100 and not game:is_paused() then
	    sol.audio.play_sound("timer")
	  end
	return true
	end)
		
	timer2 = sol.timer.start(self, 755, function()
	  if self:get_remaining_time() <= 6100 and self:get_remaining_time() >= 3465 and not game:is_paused() then
	    timer:stop()
	    sol.audio.play_sound("timer_hurry")
	  end
	return true
	end)
		
	timer3 = sol.timer.start(self, 380, function()
	  if self:get_remaining_time() <= 3080 and not game:is_paused() then
	    timer2:stop()
	    sol.audio.play_sound("timer_almost_end")
	  end
	return true
	end)
		
	timer4 = sol.timer.start(self, 30, function()
	  if self:get_remaining_time() <= 6100 and self:get_remaining_time() >= 3465 then timer:stop() end
	  if self:get_remaining_time() <= 3080 then timer2:stop() end
	  if self:get_remaining_time() == 0 and not game:is_paused() then
	    timer3:stop()
		if sol.audio.get_music_volume() ~= game:get_value("old_volume") then sol.audio.set_music_volume(game:get_value("old_volume")) end
	    if timer ~= nil then timer:stop() end
		if timer2 ~= nil then timer2:stop() end
	    if timer3 ~= nil then timer3:stop() end
		if timer4 ~= nil then timer4:stop(); return false end
	  end
	return true
	end)
		
	timer:set_suspended_with_map(true)
	timer2:set_suspended_with_map(true)
	timer3:set_suspended_with_map(true)
	timer4:set_suspended_with_map(true)
  end
end
	
function timer_meta:display_timer(context)
  local menu = require("scripts/gameplay/screen/timer")
  menu:get_info(context, self, self:is_suspended_with_map() or false)
  sol.menu.start(context, menu)
end