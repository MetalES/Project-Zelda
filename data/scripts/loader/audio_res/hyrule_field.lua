return function(game) 
  local map
  local hero  
  local audio = {}
  
  local path = "hyrule_field/"
  local old_music = nil
  local enemy_partition_played = 0
  
  function audio:start()
    enemy_partition_played = 0
  
    if not game.is_in_field then
      self:determine_partition()
	  game.is_in_field = true
    end
  end
  
  function audio:get_time_of_day()
    local value = game:get_value("time_of_day")
	local result = ""
	
    if value == "twilight_sunset" then
      result = "dusk"
    elseif value == "night" then
      result = "night"
    elseif (value == "twilight_sunrise" or value == "dawn") then
      result = "dawn"
    end
  
    return result
  end
  
  -- Analyse and determine what to play, depending on the time of day, the player has just entered the map.
  function audio:determine_partition()
    local tod = self:get_time_of_day()
  
    if tod == "dawn" then
      self:play_dawn()
    elseif tod == "dusk" then
      self:play_dusk()
    elseif tod == "night" then
      self:play_night()
    elseif tod == "" or tod == "midday_" then
      self:play_intro()
    end
  end
  
  function audio:play_dawn()
    sol.audio.play_music(path .. "environment_effect/dawn", function()
      self:play_dawn()
    end)
  end

  function audio:play_intro()
    -- local epona = hero:is_riding_epona()
  
    -- We have just enterred the map. Play a intro
    sol.audio.play_music(path .. "intro_foot" .. self:get_time_of_day(), function()
      self:check()
    end)
  end

  function audio:play_dusk()
    local hour = game:get_value("current_hour")
    local minute = game:get_value("current_minute")
  
    if hour < 20 and minute < 30 then
      sol.audio.play_music(path .. "environment_effect/twilight", function()
        self:play_dusk()
      end)
    else
      self:play_night()
    end
  end

  function audio:play_night()
    sol.audio.play_music(path .. "night")
  end
  
  function audio:check()
    local hero_anim = hero:get_animation()
    local hour = game:get_value("current_hour")
    local minute = game:get_value("current_minute")
    local current_time = hour > 12 and "midday_" or ""
    local next_partition = math.floor(math.random(0, 12) / 3)

    if hour == 18 and minute > 29 then
      enemy_partition_played = 0
	  
	  sol.timer.start(math.random(200, 10000), function()
	    game:get_map():check_night()
	  end)
	
	  local function play_nighttime(self)
	    sol.audio.play_music(path .. "nighttime_intro", function()
		  self:play_dusk()
	    end)
	  end
	
	  if old_music == path .. "stopped_foot_midday_0" then
	    play_nighttime(self)
	  else
	    sol.audio.play_music(path .. "stopped_foot_midday_0", function()
	      play_nighttime(self)
	    end)
	  end
	  return
    end
  
    for e in map:get_entities_by_type("enemy") do
	  if e:get_distance(hero) <= 64 and e:exists() then
	    sol.audio.play_music(path .. "walking_foot_" .. current_time .. "near_enemy_" .. enemy_partition_played, function()
	      enemy_partition_played = enemy_partition_played + 1
	      if enemy_partition_played == 3 then enemy_partition_played = 0 end
		  self:check()
	    end)
		old_music = sol.audio.get_music()
	    return
   	  end
    end
    enemy_partition_played = 0
	
    if (hero_anim:match("stopped") or game:is_suspended()) then
	  sol.audio.play_music(path .. "stopped_foot_" .. current_time .. "0", function()
	    self:check()
	  end)
    else
      sol.audio.play_music(path .. "walking_foot_" .. current_time .. next_partition, function()
	    self:check()
      end)
    end 
  
    old_music = sol.audio.get_music()
  end
  
  function game:start_field_audio()
    map = game:get_map()
    hero = map:get_hero()
    audio:start()
  end
  
  return audio
end