local hyrule_field_bgm = {
  folder = "hyrule_field/",
  old_music = nil
}

-- When player is on hyrule fields, the music played depends on their actions and on the surrounding environment, and also the time.
-- Start this menu when you're on these maps.

function hyrule_field_bgm:on_started()

  self.game = sol.main.game
  self.map = self.game:get_map()
  self.time_of_day = ""
  self.enemy_partition_played = 0
  
  if not self.game.is_in_field then
    self:determine_partition()
	self.game.is_in_field = true
  end
end

function hyrule_field_bgm:get_time_of_day()
  local game = self.game
  local time_of_day = game:get_value("time_of_day")
  self.time_of_day = ""
  
  if time_of_day == "twilight_sunset" then
    self.time_of_day = "dusk"
  elseif time_of_day == "night" then
    self.time_of_day = "night"
  elseif (time_of_day == "twilight_sunrise" or time_of_day == "dawn") then
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
  elseif tod == "" or tod == "midday_" then
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
  local hour = self.game:get_value("current_hour")
  local minute = self.game:get_value("current_minute")
  
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
  local hour = self.game:get_value("current_hour")
  local minute = self.game:get_value("current_minute")
  local current_time = hour > 12 and "midday_" or ""
  local next_partition = math.floor(math.random(0, 12) / 3)

  if hour == 18 and minute > 29 then
    self.enemy_partition_played = 0
	
	local function play_nighttime(self)
	  sol.audio.play_music(self.folder .. "nighttime_intro", function()
		self:play_dusk()
	  end)
	end
	
	if self.old_music == self.folder .. "stopped_foot_midday_0" then
	  play_nighttime(self)
	else
	  sol.audio.play_music(self.folder .. "stopped_foot_midday_0", function()
	    play_nighttime(self)
	  end)
	end
	return
  end
  
  for e in map:get_entities_by_type("enemy") do
	if e:get_distance(hero) <= 64 and e:exists() then
	  sol.audio.play_music(self.folder .. "walking_foot_" .. current_time .. "near_enemy_" .. self.enemy_partition_played, function()
	    self.enemy_partition_played = self.enemy_partition_played + 1
	    if self.enemy_partition_played == 3 then self.enemy_partition_played = 0 end
		self:check_partition()
	  end)
	  return
   	end
  end
  self.enemy_partition_played = 0
	
  if (hero_anim:match("stopped") or map:get_game():is_suspended()) then
	sol.audio.play_music(self.folder .. "stopped_foot_" .. current_time .. "0", function()
	  self:check_partition()
	end)
  else
    sol.audio.play_music(self.folder .. "walking_foot_" .. current_time .. next_partition, function()
	  self:check_partition()
    end)
  end 
  
  self.old_music = sol.audio.get_music()
end

return hyrule_field_bgm