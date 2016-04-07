local hyrule_field_bgm = {}

-- When player is on hyrule fields, the music played depends on their actions and on the surrounding environment, and also the time.
-- Start this menu when you're on these maps.

function hyrule_field_bgm:on_started()
  self.map = sol.main.game:get_map()
  self.folder = "hyrule_field/"
  self.time_of_day = ""
  self.enemy_partition = 2
  self.enemy_partition_played = 0
  
  self.near_enemy = false
  self.need_intro_night = false
  
  if not self.map:get_game().is_in_field then
    self:determine_partition()
	self.map:get_game().is_in_field = true
  end
end

function hyrule_field_bgm:get_time_of_day()
  local game = self.map:get_game()
  local time_of_day = game:get_time_of_day()
  self.time_of_day = ""
  
  if time_of_day == "twilight_sunset" then
    self.time_of_day = "dusk"
  elseif time_of_day == "night" then
    self.time_of_day = "night"
  elseif time_of_day == "twilight_sunrise" then
    self.time_of_day = "dawn"
  end
  
  print(self.time_of_day)
  
  return self.time_of_day
end

-- Analyse and determine what to play, depending on the time of day, the player has just entered the map.
-- This is the function to call when you start a map
function hyrule_field_bgm:determine_partition()
  local tod = self:get_time_of_day()
  
  if tod == "dawn" then
    self:play_dawn()
  elseif tod == "dusk" then
    self:play_dusk()
  elseif tod == "night" then
    self:play_night()
  elseif (tod == "" or tod == "midday_") then
    self:play_intro()
  end
end

function hyrule_field_bgm:play_dawn()
  sol.audio.play_music("hyrule_field/environment_effect/dawn", function()
    self:play_dawn()
  end)
end

function hyrule_field_bgm:play_intro()
  local map = self.map
  local hero = map:get_hero()
  local folder
  local hour = map:get_game():get_value("current_hour")
  local minute = map:get_game():get_value("current_minute")
  -- local epona = hero:is_riding_epona()
  
  -- We have just enterred the map. Play a intro
  sol.audio.play_music(self.folder .. "intro_foot" .. self:get_time_of_day(), function()
    self:check_partition()
  end)
end

function hyrule_field_bgm:play_dusk()
  local folder = self.folder
  local map = self.map
  local folder = self.folder
  local hour = map:get_game():get_value("current_hour")
  local minute = map:get_game():get_value("current_minute")
  
  if self.time_of_day == "dusk" then
    sol.audio.play_music(folder.."environment_effect/twilight", function()
      self:play_dusk()
    end)
  elseif self.time_of_day == "night" then
	self:play_night()
  end
end

function hyrule_field_bgm:play_night()
  local map = self.map
  local hour = map:get_game():get_value("current_hour")
  local minute = map:get_game():get_value("current_minute")
  
  sol.audio.play_music("hyrule_field/night")
  if (hour == 5 and minute == 30) then
    self:play_dawn()
  end
end

function hyrule_field_bgm:check_partition()
  local map = self.map
  local hero = map:get_hero()
  local hero_anim = hero:get_animation()
  local folder = self.folder
  local hour = map:get_game():get_value("current_hour")
  local minute = map:get_game():get_value("current_minute")
  local with_shield = map:get_game():get_ability("shield") and "_with_shield" or nil
  local current_time = self:get_time_of_day()
  
  local next_partition = math.random(0, 4)
  
  for e in map:get_entities("enemy") do
	if e:get_distance(hero) <= 64 and e:exists() and not self.need_intro_night then
	  self.near_enemy = true
	  sol.audio.play_music(folder .. "walking_foot_" .. current_time .. "near_enemy_" .. self.enemy_partition_played, function()
	    self.enemy_partition_played = self.enemy_partition_played + 1
		if self.enemy_partition_played == 3 then self.enemy_partition_played = 0 end
		self.near_enemy = false
		self:check_partition()
	  end)
   	end
		
	e.on_dead = function()
	  hyrule_field_bgm.near_enemy = false
	  hyrule_field_bgm.enemy_partition_played = 0
	end
  end

  if hour == 18 and minute > 29 then
    self.near_enemy = false
	self.need_intro_night = true
	sol.audio.play_music(folder .. "stopped_foot_midday_0", function()
	  sol.audio.play_music(folder .. "nighttime_intro", function()
		self.need_intro_night = false
		self:play_dusk()
	  end)
	end)
  else
   	
	if (hero_anim == "stopped" .. with_shield or map:get_game():is_suspended()) then
	  if not self.near_enemy then
		sol.audio.play_music(folder.."stopped_foot_" .. current_time .. "0", function()
		  self:check_partition()
		end)
	  end
	else
	  if not self.near_enemy then
		sol.audio.play_music(folder.."walking_foot_" .. current_time .. next_partition, function()
		  self:check_partition()
		end)
	  end
	end	
  end
end

return hyrule_field_bgm