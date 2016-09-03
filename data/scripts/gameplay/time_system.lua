local game = ...
local tone_manager = {}

-- Initialize the values
local cr, cg, cb, ca = nil
local tr, tg, tb, ta = nil
local game_initialized = false

-- Day/Night system - Tone.
function game:start_tone_system()
  sol.menu.start(self:get_map(), tone_manager, false)
end

function game:stop_tone_system()
  sol.menu.stop(tone_manager)
end

function game:on_tone_system_saving()
  if cr ~= nil then
    game:set_value("cr", cr)
    game:set_value("cg", cg)
    game:set_value("cb", cb)
    game:set_value("ca", ca)
  end 
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
  
  -- todo disable and re-enavble clock
end

function game:set_time_flow(int)
  self.time_flow = int
  for _, timeclock in ipairs(self.clock) do
	if sol.menu.is_started(timeclock) then
	  sol.timer.stop_all(timeclock)
	  sol.menu.stop(timeclock)
	  sol.menu.start(self, timeclock)
	end
  end
  game:stop_tone_system()
  game:start_tone_system()
end

function game:get_time_of_day()
  return game:get_value("time_of_day")
end

function tone_manager:on_started()
  self.tone_surface = sol.surface.create(320, 240)
  self.tone_surface:set_blend_mode("multiply")
  
  cr, cg, cb, ca = game:get_value("cr") or 0, game:get_value("cg") or 0, game:get_value("cb") or 0, game:get_value("ca") or 0
  tr, tg, tb, ta = game:get_value("tr") or 0, game:get_value("tg") or 0, game:get_value("tb") or 0, game:get_value("ta") or 0
  
  if game:get_value("cr") then
    self.tone_surface:fill_color{game:get_value("cr"), game:get_value("cg"), game:get_value("cb"), game:get_value("ca")}
  end
  
  self:store_all_tone()
  self:check()
  game_initialized = true
  
  -- Rebuild the Tone
  self:rebuild_tone()
end

function tone_manager:set_new_tone(r, g, b, a)
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
  local minute = game:get_value("current_minute")
  local hour = game:get_value("current_hour")
  local need_rebuild = false
  self.time_system = false
  local tileset =  game:get_map():get_tileset()

  if tileset == "exterior"  then
    self.time_system = true
  end

  if minute == 0 or minute == 30 and game_initialized then
   need_rebuild = true
  end
  
  if need_rebuild then
	self:store_all_tone()
	need_rebuild = false
  end 
  
  -- Schedule the next check.
  sol.timer.start(self, game.time_flow, function()
    self:check()
  end)
end

function tone_manager:store_all_tone()
  local minute = game:get_value("current_minute")
  local hour = game:get_value("current_hour")

    if hour > 19 and hour < 4 then
	  self:set_new_tone(100, 100, 210, 200)
	  
	elseif hour == 4 and minute < 30 then
      self:set_new_tone(130, 130, 170, 220)
	  
	elseif hour == 4 and minute >= 30 then
     self:set_new_tone(150, 130, 120, 215)
	  
	elseif hour == 5 and minute < 30 then
	  game:set_value("time_of_day", "dawn")
      self:set_new_tone(182, 126, 91, 255) --(200, 150, 100, 210)

	elseif hour == 5 and minute >= 30 then
      self:set_new_tone(222, 170, 160, 255) -- self:set_new_tone(225, 175, 85, 220)
	  
	elseif hour == 6 and minute < 30 then
      self:set_new_tone(255, 220, 220, 255)
	
	elseif hour == 6 and minute >= 30 then
      self:set_new_tone(255, 255, 255, 255) 
	  
	elseif hour >= 7 and hour <= 9 then
      self:set_new_tone(255, 255, 255, 255)
	  
	elseif hour > 9 and hour < 16 then
	  self:set_new_tone(255, 255, 225, 255)

	elseif hour == 16 and minute < 30 then
      self:set_new_tone(255, 230, 220, 255)
	  
	elseif hour == 16 and minute >= 30 then
      self:set_new_tone(255, 220, 200, 255)
	  
	elseif hour == 17 and minute < 30 then
      self:set_new_tone(225, 200, 170, 255)
	  
	elseif hour == 17 and minute >= 30 then
      game:set_value("time_of_day", "sunset")
	  self:set_new_tone(225, 170, 150, 255)
	  
	elseif hour == 18 and minute < 30 then
	  self:set_new_tone(225, 150, 135, 240)
	  
	elseif hour == 18 and minute >= 30 then
	  game:set_value("time_of_day","twilight_sunset")
	  self:set_new_tone(160, 130, 120, 230)
	  
	elseif hour == 19 and minute < 30 then
      game:set_value("time_of_day","night")
	  self:set_new_tone(140, 120, 170, 210)
	  
	elseif hour == 19 and minute >= 30 then
      self:set_new_tone(100, 100, 210, 200)
	  
	end
end

function tone_manager:rebuild_tone()
  self.tone_timer = sol.timer.start(self, game.time_flow / 2, function()

    -- Update the Red Ratio
    if cr ~= tr then
	  cr = (cr < tr) and cr + 0.5 or cr - 0.5
	else
	  cr = tr
	end
	  
	--Update the Green Ratio
	if cg ~= tg then
	  cg = (cg < tg) and cg + 0.5 or cg - 0.5
	else
	  cg = tg
	end
	  
	-- Update the Blue Ratio
	if cb ~= tb then
	  cb = (cb < tb) and cb + 0.5 or cb - 0.5
	else
	  cb = tb
	end
	  
	-- Update the Alpha ratio
	if ca ~= ta then
	  ca = (ca < ta) and ca + 0.5 or ca - 0.5
	else
	  ca = ta
	end
	
	self.tone_surface:clear()
	self.tone_surface:fill_color{cr, cg, cb, ca}
	
	return true
  end)
  self.tone_timer:set_suspended_with_map(true)
end

function tone_manager:on_finished()
  sol.timer.stop_all(self)
  self.time_system = false
  game:on_tone_system_saving()
end

function tone_manager:on_draw(dst_surface)
  if self.time_system then
    self.tone_surface:draw(dst_surface)
  end
end

return tone_manager