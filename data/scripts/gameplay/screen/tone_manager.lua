--[[
--> Tone Manager
--> Manage time system tones and also light effects.
]]

return function(game)
  local tone_manager = {
    lantern_effect = sol.sprite.create("entities/item_lantern_lamp_ef"),
	torch_light = sol.sprite.create("entities/effect_light_torch"),
	lava_effect = sol.sprite.create("entities/effect_light_torch_tile"),
	street_light = sol.sprite.create("entities/effect_light_street")
  }
  local mr, mg, mb, ma = nil, nil, nil, nil
  -- Create the current tone
  local cr, cg, cb = nil
  -- Create the target tone
  local tr, tg, tb = nil
  local d
  
  -- Day/Night system - Tone.
  function game:start_tone_system()
    sol.menu.start(self:get_map(), tone_manager, true)
  end
  
  function game:stop_tone_system()
    sol.menu.stop(tone_manager)
  end
  
  function game:on_tone_system_saving()
    if cr ~= nil then
      game:set_value("cr", cr)
      game:set_value("cg", cg)
      game:set_value("cb", cb)
    end 
	game:set_value("tr", tr)
    game:set_value("tg", tg)
    game:set_value("tb", tb)
  end
  
  function game:set_time(hour, minute, day)
    if minute == nil then 
      minute = 0
    elseif day == nil then 
      day = self:get_value("current_day")
    end
    self:set_value("current_hour", hour)
    self:set_value("current_minute", minute)
    self:set_value("current_day", day)
	
	if (hour >= 6 and hour < 18 and minute > 30) then
	  game:set_value("time_of_day", "day")
	elseif hour > 18 or hour < 4 then
	  game:set_value("time_of_day", "night")
	end
  
    self:set_clock_enabled(false)
    self:set_clock_enabled(self.was_clock_enabled)
	
	tone_manager:get_new_tone()
	d = 1	
	
	cr = tr
	cg = tg
	cb = tb
	
	self:stop_tone_system()	
	self:start_tone_system()
  end

  function game:set_time_flow(int)
    self.time_flow = int
	
	self:stop_tone_system()
  
    self:set_clock_enabled(false)
    self:set_clock_enabled(true)

    self:start_tone_system()
  end

  function game:get_time_of_day()
    return game:get_value("time_of_day")
  end
  
  function game:set_map_tone(r,g,b,a)
    mr, mg, mb, ma = r, g, b, a
  end
  
  local item = game:get_item("lamp")
  function item:set_light_animation(anim)
    tone_manager.lantern_effect:set_animation(anim)
  end
  
  function item:set_surface_opacity(opacity)
    tone_manager.shadow:set_opacity(opacity)
  end
    
  function tone_manager:on_started()
    self.lantern_effect:set_blend_mode("blend")
	self.torch_light:set_blend_mode("blend")
    self.map = game:get_map()
	
	self.time_system = game:get_map():get_tileset() == "exterior"
	
    -- Shadow surface -> Draw tones
    self.shadow = sol.surface.create(320, 240)
    self.shadow:set_blend_mode("multiply")
	
	-- Light surface -> Draw light effects
	self.light = sol.surface.create(320, 240)
    self.light:set_blend_mode("add")
	
	cr, cg, cb = game:get_value("cr"), game:get_value("cg"), game:get_value("cb")
    tr, tg, tb = game:get_value("tr"), game:get_value("tg"), game:get_value("tb")
  
    self:get_new_tone()
    self:check()
  end
  
  function tone_manager:set_new_tone(r, g, b)
    tr = r   
    tg = g
    tb = b   
  end
  
  -- Checks if the tone need to be updated
  -- and updates it if necessary.
  function tone_manager:check()
    local minute = game:get_value("current_minute")
    local need_rebuild = false

    if minute == 0 or minute == 30 then
      need_rebuild = true
    end
  
    if need_rebuild then
	  self:get_new_tone()
	  need_rebuild = false
    end 
  
    -- Schedule the next check.
    sol.timer.start(self, game.time_flow, function()
      self:check()
    end)
  end
    
  function tone_manager:get_new_tone(hour, minute)
    local minute = game:get_value("current_minute")
    local hour = game:get_value("current_hour")
	
    if hour == 4 and minute < 30 then
      self:set_new_tone(120, 120, 190)
	  
	elseif hour == 4 and minute >= 30 then
     self:set_new_tone(140, 125, 170)
	  
	elseif hour == 5 and minute < 30 then
	  game:set_value("time_of_day", "dawn")
      self:set_new_tone(155, 130, 140)

	elseif hour == 5 and minute >= 30 then
      self:set_new_tone(170, 130, 100)
	  
	elseif hour == 6 and minute < 30 then
      self:set_new_tone(210, 180, 150)
	
	elseif hour == 6 and minute >= 30 then
      self:set_new_tone(240, 240, 230)

	elseif hour == 7 and minute < 30 then
      self:set_new_tone(255, 255, 255)
    	  
	elseif hour > 7 and hour <= 9 then
	  self:set_new_tone(255, 255, 255) 
	  
	elseif hour > 9 and hour < 16 then
	  self:set_new_tone(255, 255, 225)

	elseif hour == 16 and minute < 30 then
	  self:set_new_tone(255, 230, 210)
	  
	elseif hour == 16 and minute >= 30 then
	  self:set_new_tone(255, 210, 180)
	  
	elseif hour == 17 and minute < 30 then
	  self:set_new_tone(255, 190, 160)
	  
	elseif hour == 17 and minute >= 30 then
      game:set_value("time_of_day", "sunset")
	  self:set_new_tone(225, 170, 150)
	  
	elseif hour == 18 and minute < 30 then
	  self:set_new_tone(180, 140, 120)
	  
	elseif hour == 18 and minute >= 30 then
	  game:set_value("time_of_day", "twilight_sunset")
	  self:set_new_tone(150, 110, 100)
	  
	elseif hour == 19 and minute < 30 then
      game:set_value("time_of_day","night")
	  self:set_new_tone(110, 105, 190)	 
	
	elseif hour == 19 and minute >= 30 then
	  self:set_new_tone(90, 90, 225)
	  
	elseif hour == 3 and minute >= 30 then
	  self:set_new_tone(80, 80, 230)
	
	end
	
	if game.raining then
	  self:set_new_tone(150, 150, 255)
	end
	
  d = game.has_played_sun_song == true and 30 or 1800
end

  function tone_manager:on_finished()
    sol.timer.stop_all(self)
    game:on_tone_system_saving()
  end

  function tone_manager:on_draw(dst_surface)
    local lamp_state = game:get_item("lamp"):get_state()
    local hero = game:get_hero()
    local cam_x, cam_y = game:get_map():get_camera():get_position()
    local x, y = hero:get_position()
  
    -- Calculate and reach the target tone before minutes reach 30 or 0
    if (not game:is_paused() and not game:is_suspended()) then
      cr = cr ~= tr and (cr * (d - 1) + tr) / d or tr
      cg = cg ~= tg and (cg * (d - 1) + tg) / d or tg
      cb = cb ~= tb and (cb * (d - 1) + tb) / d or tb
      d = d - 1
    end
	
    -- Fill the Tone Surface
    if mr ~= nil then
      -- We are in a map where tone are defined
	  self.shadow:clear() 
      self.shadow:fill_color{mr, mg, mb, ma}
    elseif self.time_system and mr == nil then
      -- We are outside
      self.shadow:fill_color{cr, cg, cb, 255}
    elseif not self.time_system and mr == nil then
      -- The map has undefined tone.
      self.shadow:fill_color{255, 255, 255, 255}
    end
  
    -- Rebuild the light surface
    self.light:clear()
  
    -- Next, this section is about entities.
    local map = game:get_map()
  
    for e in map:get_entities("torch_") do
      if e:is_enabled() and e:get_sprite():get_animation() == "lit" and e:get_distance(hero) <= 300 then
        local xx,yy = e:get_position()
        self.torch_light:draw(self.light, xx - cam_x, yy - cam_y)
      end
    end
		
    for e in map:get_entities("night_") do
      if e:is_enabled() and e:get_distance(hero) <= 300 then
	    if e.is_street_light then
		  local xe, ye = e:get_position()
		  self.street_light:draw(self.light, xe - cam_x, ye - cam_y)
		else
		  local xx,yy = e:get_position()
          self.torch_light:draw(self.light, xx - cam_x, yy - cam_y)
		end
      end
    end  
  
    for e in map:get_entities("lava_") do
      if e:is_enabled() and e:get_distance(hero) <= 300 then
        local xx,yy = e:get_position()
	    self.lava_effect:draw(self.light, xx - cam_x, yy - cam_y)
      end
    end
  
    if lamp_state ~= "inactive" or mr ~= nil then
      self.lantern_effect:set_direction(hero:get_direction())
      self.lantern_effect:draw(self.light, x - cam_x, y - cam_y)
	end
  
    self.light:draw(self.shadow)
    self.shadow:draw(dst_surface)
  end

  return tone_manager
end