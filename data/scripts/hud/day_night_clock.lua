local time_system_clock = {}
local has_started = false

-- Day/Night system - HUD Clock.

function time_system_clock:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function time_system_clock:initialize(game)
  local horizontal_alignment = "center"
  local vertical_alignment = "middle"
  local font = "clock"
  
  self.game = game
  self.game.time_flow = 1000
  self.hour = self.game:get_value("current_hour")
  self.minute = self.game:get_value("current_minute")
  self.current_time = 0
  
  self.hour_text = self.game:get_value("current_hour")
  
  -- the supposed clock position in the HUD.
  self.clock_x = 116
  self.clock_y = 192

  --Surfaces
  self.time_system_clock_base = sol.surface.create("hud/clock/base.png") 
  self.time_system_clock_sun = sol.surface.create("hud/clock/sun.png") 
  self.time_system_clock_moon = sol.surface.create("hud/clock/moon.png") 
  self.time_system_minute_base = sol.surface.create("hud/clock/minute_base.png") 
  self.time_system_minute_indicator = sol.surface.create("hud/clock/minute_indicator.png") 
  self.time_system_time_indicator = sol.surface.create("day_night_indicator.png", true) 
  
  --Size of the surfaces
  self.sun_width, self.sun_height = self.time_system_clock_sun:get_size()
  self.moon_width, self.moon_height = self.time_system_clock_moon:get_size()
  
  self.sun_x = self.clock_x + 44 - self.sun_width / 2
  self.moon_x = self.clock_x + 44 - self.moon_width / 2
  self.sun_hour_x, self.moon_hour_x = self.clock_x + 44, self.clock_x + 44
  self.sun_y = self.clock_y + 39 - self.sun_height / 2
  self.moon_y = self.clock_y + 39 - self.moon_height / 2
  self.sun_hour_y = self.clock_y + 39
  self.moon_hour_y = self.clock_y + 39
  
  
  self.minute_x = self.clock_x + 44 - self.time_system_minute_indicator:get_size() / 2 + 1
  self.minute_y = self.clock_y + 44 - self.time_system_minute_indicator:get_size() / 2 - 12 ----- todo

  --Position in the HUD script
  self.dst_x = 0
  self.dst_y = 0
  
  --used to display the current hour.
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

function time_system_clock:on_started()
  self.audio_mgr = require("scripts/gameplay/audio/hyrule_field_audio_mgr")
  if self.game:get_value("current_hour") >= 6 and self.game:get_value("current_hour") <= 17 then
    self.current_time = 0
  else
    self.current_time = 1
  end
  self:check()
  has_started = true
end

function time_system_clock:check_time()
   local language = sol.language.get_language()
     if language ~= "fr" then 
       if self.game:get_value("current_hour") > 12 then
        self.time_system_hour_sun:set_text(self.game:get_value("current_hour") - 12)
	    self.time_system_hour_moon:set_text(self.game:get_value("current_hour") - 12)
       elseif self.game:get_value("current_hour") == 24 or self.game:get_value("current_hour") == 0 then
        self.time_system_hour_moon:set_text("12")
	   else
		self.time_system_hour_sun:set_text(self.game:get_value("current_hour"))
	    self.time_system_hour_moon:set_text(self.game:get_value("current_hour"))
       end
     else
	   self.time_system_hour_sun:set_text(self.game:get_value("current_hour"))
	   self.time_system_hour_moon:set_text(self.game:get_value("current_hour"))
       if self.game:get_value("current_hour") == 24 or self.game:get_value("current_hour") == 0  then
        self.time_system_hour_moon:set_text("0")
       end
     end
end

function time_system_clock:check()
   local radians = (self.game:get_value("current_hour") + self.game:get_value("current_minute") / 60) * math.pi / 12  
   local csin = math.sin(radians)
   local ccos = math.cos(radians)
   local inc = math.floor(self.game:get_value("current_minute") + 1 / self.game.time_flow)

   if self.game.has_played_sun_song then
     if (self.game:get_value("current_hour") == 6 or self.game:get_value("current_hour") == 18) and self.game:get_value("current_minute") == 0 then
	   sol.timer.stop_all(self)
	   self.game:set_time_flow(1000)
	   self.game.has_played_sun_song = false
       self.game:stop_tone_system()
	   self.game.sun_song_finished = true
       self.game:start_tone_system()
	 end
   end   
   
   if self.game:get_value("current_hour") == 5 and self.game:get_value("current_minute") == 59 then
    self.current_time = 0
   elseif self.game:get_value("current_hour") == 17 and self.game:get_value("current_minute") == 59 then
    self.current_time = 1
   end 
   
   if not self.game:is_dialog_enabled() or not self.game:is_suspended() or self.game.stop_time or not self.game:is_suspended() then
     self.game:set_value("current_minute", self.game:get_value("current_minute") + 1)
     self:check_time()
   end
   
   if self.game:get_value("current_minute") > 59 then
     self.game:set_value("current_minute", 0)
     self.game:set_value("current_hour", self.game:get_value("current_hour") + 1)
     self:check_time()

   elseif self.game:get_value("current_hour") > 23 then
	  self.game:set_value("current_hour", 0)
	  self.game:set_value("current_day", (self.game:get_value("current_day") or 0) + 1)
   elseif self.game:get_value("current_day") == 7 then
      self.game:set_value("current_day", 0)
   end 
   
   if self.game:get_value("current_hour") == 24 then
    self:check_time()
   end

  self.sun_ox, self.sun_oy = csin * 38, ccos * -31
  self.moon_ox, self.moon_oy = csin * -38, ccos * 31
  self.sun_hour_ox, self.sun_hour_oy = csin * 50, ccos * -45
  self.moon_hour_ox, self.moon_hour_oy = csin * -50, ccos * 45
  
  if self.game:get_value("current_minute") == 0 then
    self.minute_ox = 1
    self.minute_oy = 16
  elseif self.game:get_value("current_minute") < 15 then
    self.minute_ox = - 17 * inc / 15
    self.minute_oy = 15 - 15 * inc / 15
  elseif self.game:get_value("current_minute") < 30 then
    self.minute_ox = -15 + 17 * (inc - 15) / 15.0
    self.minute_oy = -14 * (inc - 15) / 15.0
  elseif self.game:get_value("current_minute") < 45 then
    self.minute_ox = 2 + 17 * (inc - 30) / 15.0
    self.minute_oy = -12 + 15 * (inc - 30) / 15.0
  elseif self.game:get_value("current_minute") < 60 then
    self.minute_ox = 17 - 17 * (inc - 45) / 15.0
    self.minute_oy = 3 + 15 * (inc - 45) / 15.0
  end
  
  -- A New day is rising, play a intro music only if we are in Hyrule Fields
  if self.game:get_value("current_hour") == 5 and self.game:get_value("current_minute") == 30 and has_started and self.game:get_map():get_world() == "field" then
    self.audio_mgr:play_dawn()
  end
  
  if self.game:get_value("current_hour") == 6 and self.game:get_value("current_minute") == 30 and has_started and self.game:get_map():get_world() == "field" then 
    local folder = "hyrule_field/"
    sol.audio.play_music(folder.."dawn", function()
	  sol.audio.play_music(folder.."dawn_intro_0", function()
	    sol.audio.play_music(folder.."dawn_intro_1", function()
		  self.audio_mgr:check_partition()
	    end)
	  end)
	end)
  end

  if not self.game.using_ocarina then
    sol.timer.start(self, self.game.time_flow, function()
      self:check()
    end)
  else 
    sol.timer.start(self, 100, function()
      if self.game.using_ocarina then
  	    return true
	  else
		self:check()
		return false
      end
    end)
  end
end

function time_system_clock:on_finished()
  self.audio_mgr = nil
  has_started = false
  sol.timer.stop_all(self)
end

function time_system_clock:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function time_system_clock:on_draw(dst_surface)
  if not self.game.using_ocarina then
    self.time_system_clock_base:draw(dst_surface, self.dst_x, self.dst_y)
    self.time_system_clock_sun:draw(dst_surface, self.sun_x - self.sun_ox, self.sun_y - self.sun_oy)
	self.time_system_clock_moon:draw(dst_surface, self.moon_x - self.moon_ox, self.moon_y - self.moon_oy)
	self.time_system_hour_sun:draw(dst_surface, self.sun_hour_x - self.sun_hour_ox, self.sun_hour_y - self.sun_hour_oy)
	self.time_system_hour_moon:draw(dst_surface, self.moon_hour_x - self.moon_hour_ox, self.moon_hour_y - self.moon_hour_oy)
	self.time_system_minute_base:draw(dst_surface, 144, 208)
	self.time_system_time_indicator:draw_region(0, 13 * self.current_time, 26, 13, dst_surface, 147, 215)
	self.time_system_minute_indicator:draw(dst_surface, self.minute_x - self.minute_ox, self.minute_y - self.minute_oy)
  end
end

return time_system_clock