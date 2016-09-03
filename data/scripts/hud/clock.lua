local clock = {
  audio_mgr = require("scripts/gameplay/audio/hyrule_field_audio_mgr")
}
local has_started = false

function clock:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function clock:initialize(game)
  local horizontal_alignment = "center"
  local vertical_alignment = "middle"
  local font = "clock"
  
  self.game = game
  game.time_flow = 1000
  self.current_time = 0
  
  self.hour_text = game:get_value("current_hour")

  --Surfaces
  self.surface = sol.surface.create(106, 60)
  self.clock_base = sol.surface.create("hud/clock/base.png") 
  self.clock_sun = sol.surface.create("hud/clock/sun.png") 
  self.clock_moon = sol.sprite.create("hud/clock/moon") 
  self.time_system_minute_base = sol.surface.create("hud/clock/minute_base.png") 
  self.time_system_minute_indicator = sol.surface.create("hud/clock/minute_indicator.png") 
  self.time_system_time_indicator = sol.surface.create("day_night_indicator.png", true) 
  
  self.clock_moon:set_direction(game:get_value("current_moon_phase"))
  
  -- Used to display the current hour.
  self.time_system_hour_sun = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
	vertical_alignment = vertical_alignment,
	font = font,
    text = self.hour_text,
  }	
  
  self.time_system_hour_moon = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
	vertical_alignment = vertical_alignment,
	font = font, 
	text = self.hour_text,
  }	
end

function clock:on_started()
  self:check_time()
  self:check()
  has_started = true
end


function clock:check_time()
  local game = self.game
  local hour = game:get_value("current_hour")
  local sun = self.time_system_hour_sun
  local moon = self.time_system_hour_moon
  self.current_time = 1
  
  if hour > 5 and hour < 18 then
    self.current_time = 0
  end
  
  if (hour >= 12 and hour <= 16) then
    self.clock_moon:set_direction(self.game:get_value("current_day"))
	game:set_value("current_moon_phase", self.clock_moon:get_direction())
  end
  
  if (hour == 0 or hour == 12 or hour == 24) then
    moon:set_text(0)
    sun:set_text(0)
	return
  end
  
  if hour > 12 then
    sun:set_text(hour - 12)
	moon:set_text(hour - 12)
	return
  end
  
  sun:set_text(hour)
  moon:set_text(hour)  
end

function clock:need_halt_increment()
  local game = self.game
  return game:is_dialog_enabled() or game:is_suspended()
end

function clock:check()
   local game = self.game
   local minute = game:get_value("current_minute")
   local hour = game:get_value("current_hour")
   local day = game:get_value("current_day")
   
   local radians = (hour + minute / 60) * math.pi / 12  
   local csin = math.sin(radians)
   local ccos = math.cos(radians)
   local inc = math.floor(minute + 1 / game.time_flow)
   
   game:set_value("current_minute", game:get_value("current_minute") + 1)
   minute = game:get_value("current_minute")
   
  if (hour == 17 or hour == 5) and minute == 60 then
     if game.has_played_sun_song then
	   game:on_tone_system_saving()
	   game:stop_tone_system()
	   game.has_played_sun_song = false
	   game.time_flow = 1000
	   game:start_tone_system()
	 end
  end 

   if minute > 59 then
     game:set_value("current_minute", 0)
     game:set_value("current_hour", hour + 1)
     self:check_time()
   elseif hour > 23 then
	  game:set_value("current_hour", 0)
	  game:set_value("current_day", day + 1)
   elseif day == 7 then
      game:set_value("current_day", 0)
   end

  self.sun_ox, self.sun_oy = 47 - (csin * 38), 45 - (ccos * -31)
  self.moon_ox, self.moon_oy = 47 - (csin * -38), 45 - (ccos * 31)
  self.sun_hour_ox, self.sun_hour_oy = 53 - (csin * 50), 51 - (ccos * -45)
  self.moon_hour_ox, self.moon_hour_oy = 53 - (csin * -50), 51 - (ccos * 45)
  
  if minute == 60 then
    self.minute_ox = 1
    self.minute_oy = 16
  elseif minute < 15 then
    self.minute_ox = - 17 * inc / 15
    self.minute_oy = 15 - 15 * inc / 15
  elseif minute < 30 then
    self.minute_ox = -15 + 17 * (inc - 15) / 15
    self.minute_oy = -14 * (inc - 15) / 15.0
  elseif minute < 45 then
    self.minute_ox = 2 + 17 * (inc - 30) / 15
    self.minute_oy = -12 + 15 * (inc - 30) / 15
  elseif minute < 60 then
    self.minute_ox = 17 - 17 * (inc - 45) / 15
    self.minute_oy = 3 + 15 * (inc - 45) / 15
  end
  
  -- Refresh the surface and rebuild it
  self:rebuild_surface()
  
  -- A New day is rising, play a intro music only if we are in Hyrule Fields
  if has_started and game:get_map():get_world() == "field" then	
	if hour == 19 and minute == 60 then
	  self.audio_mgr:play_night()
	end
	
    if hour == 5 and minute == 30 then
      self.audio_mgr:play_dawn()
    end  

    if hour == 6 and minute == 30 then 
	  self.game:set_value("time_of_day", "day")
      local folder = "hyrule_field/"
	  local track = 0
	  
	  local function do_track(num)
	    sol.audio.play_music(folder .. "dawn_intro_" .. num, function()
		  if num == 1 then
		    clock.audio_mgr:check_partition()
		    return
		  end
		  do_track(num + 1)
		end)
	  end
	  
      sol.audio.play_music(folder .. "dawn", function()
	    do_track(0)
	  end)
    end	
  end
  
  self.timer = sol.timer.start(self, self.game.time_flow, function()
    self:check()
  end)
  self.timer:set_suspended_with_map(self:need_halt_increment())
end

function clock:rebuild_surface()
  -- Clear the old cycle and redraw the new
  self.surface:clear()

  self.clock_base:draw(self.surface, 9, 12)
  self.clock_sun:draw(self.surface, self.sun_ox, self.sun_oy)
  self.clock_moon:draw(self.surface, self.moon_ox, self.moon_oy)
  self.time_system_hour_sun:draw(self.surface, self.sun_hour_ox, self.sun_hour_oy)
  self.time_system_hour_moon:draw(self.surface, self.moon_hour_ox, self.moon_hour_oy)
  self.time_system_minute_base:draw(self.surface, 37, 28)
  self.time_system_time_indicator:draw_region(0, 13 * self.current_time, 26, 13, self.surface, 40, 35)
  self.time_system_minute_indicator:draw(self.surface, 52 - self.minute_ox, 42 - self.minute_oy)
end

function clock:hide_clock()
  local game = self.game
  return game.using_ocarina or game:is_paused()
end

function clock:on_finished()
  self.audio_mgr = nil
  has_started = false
  sol.timer.stop_all(self)
  self.timer = nil
end

function clock:on_draw(dst_surface)
  if not self:hide_clock() then
    self.surface:draw(dst_surface, 107, 180)
  end
end

return clock