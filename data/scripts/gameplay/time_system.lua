local game = ...
local tone_manager = {}
local tone_timer
local cr, cg, cb, ca = nil
local tr, tg, tb, ta = nil
local game_initialized = false

-- Day/Night system - Tone.

function game:start_tone_system()
  sol.menu.start(game:get_map(), tone_manager, false)
end

function game:stop_tone_system()
sol.menu.stop(tone_manager)
end

function game:set_time(hour, minute, day)
  if hour == nil then
    hour = 0
  elseif minute == nil then 
    minute = 0
  elseif day == nil then 
    day = self:get_value("current_day")
  end
  self:set_value("current_hour", hour)
  self:set_value("current_minute", minute)
  self:set_value("current_day", day)
end

function game:set_time_flow(int)
  self.time_flow = int
  for _, timeclock in ipairs(self.clock) do
	if sol.menu.is_started(self.clock) then
	  sol.timer.stop_all(self.clock)
	  sol.menu.stop(self.clock)
	  sol.menu.start(self, self.clock, true)
	end
  end
  game:stop_tone_system()
  game:start_tone_system()
end

--Code from Wrightmat
function game:get_time_of_day()
  if game:get_value("time_of_day") == nil then game:set_value("time_of_day", "day") end
  return game:get_value("time_of_day")
end

function game:set_time_of_day(tod)
    self:set_value("time_of_day", tod)
end

function tone_manager:on_started()
  self.game = game
  
  self.tone_surface = sol.surface.create(320,240)
  
  cr, cg, cb, ca = self.game:get_value("cr") or 0, self.game:get_value("cg") or 0, self.game:get_value("cb") or 0, self.game:get_value("ca") or 0
  tr, tg, tb, ta = self.game:get_value("tr") or 0, self.game:get_value("tg") or 0, self.game:get_value("tb") or 0, self.game:get_value("ta") or 0
  
  if self.game:get_value("cr") then
    self.tone_surface:fill_color{self.game:get_value("cr"), self.game:get_value("cg"), self.game:get_value("cb"), self.game:get_value("ca")}
  end
  
  self:store_all_tone()
  self:check()
  game_initialized = true
  
  if self.game.sun_song_finished then
  self:store_all_tone()
  self:rebuild_tone()
  self.game.sun_song_finished = false
  end
end

function tone_manager:set_new_tone(r,g,b,a)
   tr = r
   cr = cr
   
   tg = g
   cg = cg

   tb = b
   cb = cb
   
   ta = a
   ca = ca
end

-- Checks if the tone need to be updated
-- and updates it if necessary.
function tone_manager:check()
local minute = self.game:get_value("current_minute")
local hour = self.game:get_value("current_hour")
-- local world = self.game:get_map():get_world() or nil
local need_rebuild = false

  if self.game:get_map():get_tileset() ~= "hyrule" then
    self.time_system = false
  else
    self.time_system = true
  end
  
  if self.game.has_played_sun_song then
	self.tone_surface:clear()
	self.game:set_value("cr", tr)
	self.game:set_value("cg", tg)
	self.game:set_value("cb", tb)
    self.game:set_value("ca", ta)
	self.game:set_value("tr", tr)
    self.game:set_value("tg", tg)
    self.game:set_value("tb", tb)
    self.game:set_value("ta", ta)
	self.tone_surface:fill_color{tr,tg,tb,ta}
  end
  
  if minute == 0 or minute == 30 and game_initialized then
   need_rebuild = true
  end
  
  if need_rebuild then
	 self:store_all_tone()
	 need_rebuild = false
  end 
  
  -- Schedule the next check.
  sol.timer.start(self, self.game.time_flow, function()
    self:check()
	  if self.game.is_new_map then -- if self.time_system and self.game.is_new_map
	    self:rebuild_tone()
	    self.game.is_new_map = false
	  end
  end)
end

function tone_manager:store_all_tone()
local minute = self.game:get_value("current_minute")
local hour = self.game:get_value("current_hour")

  if hour == 24 then
   self:set_new_tone(0, 0, 64,160) --160))
  else
  if hour >= 0 and hour <= 2 then
   self:set_new_tone(0, 0, 70,155)
  elseif hour == 3 and minute == 0 and minute <= 30 then
   self:set_new_tone(0, 0, 70,150)
  elseif hour == 3 and minute >= 30 then
   self:set_new_tone(0, 0, 70,148)
  elseif hour == 4 and minute == 0 and minute <= 30 then
   self:set_new_tone(0, 0, 70,140)
  elseif hour == 4 and minute >= 30 then
   self.game:set_value("time_of_day", "night_ending")
   self:set_new_tone(10, 10, 60, 130)
  elseif hour == 5 and minute == 0 and minute <= 30 then
   self:set_new_tone(30,150, 50, 110)
  elseif hour == 5 and minute >= 30 then
   self.game:set_value("time_of_day", "twilight_sunrise")
    self:set_new_tone(253, 125, 5, 100)
  elseif hour == 6 and minute == 0 and minute <= 30 then
   self.game:set_value("time_of_day", "sunrise")
   self:set_new_tone(253, 125, 5, 80)
  elseif hour == 6 and minute >= 30 then
   self.game:set_value("time_of_day", "daytime")
   self:set_new_tone(253, 125, 5, 60)
  elseif hour >= 7 and hour <= 11 then
   self:set_new_tone(0, 0, 0, 0)
  elseif hour >= 12 and hour <= 15 then
   self:set_new_tone(255, 255, 0, 25)
  elseif hour == 16 and minute == 0 and minute <= 30 then
   self.game:set_value("time_of_day", "day_ending")
   self:set_new_tone(253, 125, 5, 60)
  elseif hour == 16 and minute >= 30 then
   self:set_new_tone(253, 125, 5, 75)
  elseif hour == 17 and minute == 0 and minute <= 30 then
   self:set_new_tone(253, 125, 5, 90)
  elseif hour == 17 and minute >= 30 then
   self.game:set_value("time_of_day", "sunset")
   self:set_new_tone(200, 100, 50, 100)
  elseif hour == 18 and minute >= 0 and minute <= 30 then
   self.game:set_value("time_of_day", "twilight_sunset")
   self:set_new_tone(150, 0, 70,120)
  elseif hour == 18 and minute >= 30 then
   self:set_new_tone(25, 0, 70,140) --??? 100 0 70 140
  elseif hour == 19 and minute >= 0 and minute <=30 then
   self.game:set_value("time_of_day", "night")
   self:set_new_tone(0, 0, 64, 160)
  elseif hour == 19 and minute >= 30 then
   self:set_new_tone(0, 0, 64, 170)
  elseif hour == 20 then
   self:set_new_tone(0, 0, 64, 150)
  elseif hour >= 21 and hour <= 23 then
   self:set_new_tone(0, 0, 75,160)

  end
  end
  
self.game:set_value("tr", tr)
self.game:set_value("tg", tg)
self.game:set_value("tb", tb)
self.game:set_value("ta", ta)
end

function tone_manager:rebuild_tone()
  tone_timer = sol.timer.start(self, self.game.time_flow / 2, function() -- 5.5
      if cr ~= tr then
	   if cr < tr then
	    cr = cr + 1
	   else
	    cr = cr - 1
	   end
	  else
	    cr = tr
	  end
	  
	  if cg ~= tg then
	   if cg < tg then
	    cg = cg + 1
	   else
	    cg = cg - 1
	   end
	  else
	    cg = tg
	  end
	  
	  if cb ~= tb then
	   if cb < tb then
	    cb = cb + 1
	   else
	    cb = cb - 1
	   end
	  else
	    cb = tb
	  end
	  
	  if ca ~= ta then
	   if ca < ta then
	    ca = ca + 0.5
	   else
	    ca = ca - 0.5
	   end
	  else
	    ca = ta
	  end
	  
	  self.tone_surface:clear()
	  self.tone_surface:fill_color{cr,cg,cb,ca}
	  
	  self.game:set_value("cr", cr)
	  self.game:set_value("cg", cg)
	  self.game:set_value("cb", cb)
	  self.game:set_value("ca", ca)
	return true
	end)
	tone_timer:set_suspended_with_map(true)
end

function tone_manager:on_finished()
sol.timer.stop_all(self)
self.time_system = false
end

function tone_manager:on_draw(dst_surface)
 if self.time_system then
  self.tone_surface:draw(dst_surface,0,0)
 end
end

return tone_manager