local hyrule_field_bgm = {
  folder = "hyrule_field/",
}

-- When player is on hyrule fields, the music played depends on their actions and on the surrounding environment, and also the time.
-- Start this menu when you're on these maps.

function hyrule_field_bgm:on_started()
  self.game = self.map:get_game()
  self.time_of_day = ""
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
  elseif time_of_day == "twilight_sunrise" or time_of_day == "dawn" then
    self.time_of_day = "dawn"
  end
  
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
  
  
  if hour < 20 then
    sol.audio.play_music(folder.."environment_effect/twilight", function()
      self:play_dusk()
    end)
  else
    self:play_night()
  end
end

function hyrule_field_bgm:play_night()
  sol.audio.play_music("hyrule_field/night")
end

function hyrule_field_bgm:check_partition()
  local map = self.map
  local hero = map:get_hero()
  local hero_anim = hero:get_animation()
  local folder = self.folder
  local hour = self.game:get_value("current_hour")
  local minute = self.game:get_value("current_minute")
  local with_shield = ""
  local current_time = ""
  
  if self.game:get_ability("shield") > 0 then
    with_shield = "_with_shield"
  end
  
  if hour > 12 then
    current_time = "midday_"
  end
  
  local next_partition = math.random(0, 4)

  if hour == 18 and minute > 29 then
    self.near_enemy = false
	self.need_intro_night = true
	sol.audio.play_music(folder .. "stopped_foot_midday_0", function()
	  sol.audio.play_music(folder .. "nighttime_intro", function()
		self.need_intro_night = false
		self:play_dusk()
	  end)
	end)
	return
  end
  
  for e in map:get_entities("enemy") do
	if e:get_distance(hero) <= 64 and e:exists() and not self.need_intro_night then
	  self.near_enemy = true
	  sol.audio.play_music(folder .. "walking_foot_" .. current_time .. "near_enemy_" .. self.enemy_partition_played, function()
	    self.enemy_partition_played = self.enemy_partition_played + 1
	    if self.enemy_partition_played == 3 then self.enemy_partition_played = 0 end
		self.near_enemy = false
		self:check_partition()
	  end)
	  return
   	end
	self.enemy_partition_played = 0
  end
	
  if not self.near_enemy then
	if (hero_anim == "stopped" .. with_shield or map:get_game():is_suspended()) then
	  sol.audio.play_music(folder .. "stopped_foot_" .. current_time .. "0", function()
	    self:check_partition()
	  end)
	  return
	end
	sol.audio.play_music(folder .. "walking_foot_" .. current_time .. next_partition, function()
	  self:check_partition()
	end)
  end
end

return hyrule_field_bgm