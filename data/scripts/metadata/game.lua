local game_metatable = sol.main.get_metatable("game")

function game_metatable:disable_input(direction, attack, action, pause, item1, item2)
  local direction = {"right", "up", "left", "down"}
  -- save these in local variables
  self.keyboard_up = self:get_command_keyboard_binding("up") 
  self.keyboard_down = self:get_command_keyboard_binding("down") 
  self.keyboard_left = self:get_command_keyboard_binding("left")
  self.keyboard_right = self:get_command_keyboard_binding("right") 
  self.keyboard_action = self:get_command_keyboard_binding("action") 
  self.keyboard_attack = self:get_command_keyboard_binding("attack") 
  self.keyboard_item_1 = self:get_command_keyboard_binding("item_1") 
  self.keyboard_item_2 = self:get_command_keyboard_binding("item_2")  

  self.joypad_up = self:get_command_joypad_binding("up") 
  self.joypad_down = self:get_command_joypad_binding("down") 
  self.joypad_left = self:get_command_joypad_binding("left") 
  self.joypad_right = self:get_command_joypad_binding("right") 
  self.joypad_action = self:get_command_joypad_binding("action") 
  self.joypad_attack = self:get_command_joypad_binding("attack") 
  self.joypad_item_1 = self:get_command_joypad_binding("item_1") 
  self.joypad_item_2 = self:get_command_joypad_binding("item_2")
  
  if direction then
    for i = 1, 4 do
	  self:set_command_keyboard_binding(direction[i], nil) 
	end
  end
  
  if attack then
    self:set_command_keyboard_binding("attack", nil)
	self:set_command_joypad_binding("attack", nil)
  end
  
  if action then
    self:set_command_keyboard_binding("action", nil)
	self:set_command_joypad_binding("action", nil)
  end
  
  if pause then 
    self:set_pause_allowed(false)
  end
  
  if item1 then
    self:set_command_keyboard_binding("item_1", nil)
	self:set_command_joypad_binding("item_1", nil)
  end
  
  if item2 then 
    self:set_command_keyboard_binding("item_2", nil)
	self:set_command_joypad_binding("item_2", nil)
  end
  
  -- Make sure all input are released
  self:simulate_command_released("attack")
  self:simulate_command_released("action")
  self:simulate_command_released("item_1")
  self:simulate_command_released("item_2")
  self:simulate_command_released("up")
  self:simulate_command_released("down")
  self:simulate_command_released("left")
  self:simulate_command_released("right")
end

function game_metatable:enable_input(direction, attack, action, pause, item1, item2)
  
  if direction then
    self:set_command_keyboard_binding("up", self.keyboard_up) 
    self:set_command_keyboard_binding("down", self.keyboard_down)  
    self:set_command_keyboard_binding("left", self.keyboard_left)
    self:set_command_keyboard_binding("right", self.keyboard_right) 
	
	self:set_command_joypad_binding("up", self.joypad_up) 
	self:set_command_joypad_binding("down", self.joypad_down)  
	self:set_command_joypad_binding("left", self.joypad_left)   
	self:set_command_joypad_binding("right", self.joypad_right)
  end
  
  if attack then
    self:set_command_keyboard_binding("attack", self.keyboard_attack)
	self:set_command_joypad_binding("attack", self.joypad_attack)
  end
  
  if action then
    self:set_command_keyboard_binding("action", self.keyboard_action)
	self:set_command_joypad_binding("action", self.joypad_action)
  end
  
  if pause then
    self:set_pause_allowed(true)
  end
  
  if item1 then
    self:set_command_keyboard_binding("item_1", self.keyboard_item_1)
    self:set_command_keyboard_binding("item_2", self.keyboard_item_2)
  end
  
  if item2 then
    self:set_command_joypad_binding("item_1", self.joypad_item_1)
	self:set_command_joypad_binding("item_2", self.joypad_item_2)
  end
end

-- Magic Function
function game_metatable:set_max_magic_meter(m)
  self:set_value("max_magic", m)
end

function game_metatable:get_max_magic_meter()
  return self:get_value("max_magic") or 0
end

-- Plunging Function
-- Don't need to save the values
function game_metatable:get_air()
  return self.plunging_air or self:get_max_air()
end

function game_metatable:get_max_air()
  local value = 42
  
  if self:has_item("flippers") then
    value = 85
  end
  
  return value
end

-- Lantern Oil

-- This event need to be call when you start a cutscene or a dialog triggered by a sensor
-- It basically stop the current item and restore the hero to it's default animation.
function game_metatable:stop_all_items()
  for i = 1, 2 do
    local slot = self:get_item_assigned(i) or nil
    if slot ~= nil and slot:is_active() then
	  slot:stop()
	end
  end
end

-- The player is currently using an item, signal the engine.
function game_metatable:set_item_on_use(boolean)
  local boolean = boolean or false
  if boolean then
    self.using_an_item = true
  else
    self.using_an_item = false
  end
end

function game_metatable:is_using_item()
  return self.using_an_item
end

-- Set this scene a cutscene
function game_metatable:set_current_scene_cutscene(boolean)
  local boolean = boolean or false
  if boolean then
    self.is_cutscene = true
  else
    self.is_cutscene = false
  end
end

function game_metatable:is_current_scene_cutscene()
  return self.is_cutscene
end

-- Fade the Audio
function game_metatable:fade_audio(targetsound, timetransit)
  local timer
  local final_target = self:is_paused() and math.floor(targetsound / 3) or targetsound

  if timer ~= nil then timer:stop() end  
  timer = sol.timer.start(self, timetransit, function()
    local volume = sol.audio.get_music_volume()
	
	if volume == final_target then
	  return false
	end
	
	local final = final_target > volume and volume + 1 or volume - 1
	sol.audio.set_music_volume(final)
    return volume ~= final_target
  end)
  timer:set_suspended_with_map(false)
end

-- Ocarina Songs management
function game_metatable:is_ocarina_song_learned(song_index)
  return self:get_value("song_" .. song_index .. "_learned")
end

function game_metatable:set_ocarina_song_learned(song_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("song_" .. song_index .. "_learned", learned)
end

-- Blade Skills Management
function game_metatable:is_skill_learned(skill_index)
  return self:get_value("skill_" .. skill_index .. "_learned")
end

function game_metatable:set_skill_learned(skill_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("skill_" .. skill_index .. "_learned", learned)
end

-- Mail System related
function game_metatable:add_mail(name)
  local mail_bag = self:get_item("mail_bag")
  local value = mail_bag:get_amount() + 1
  
  self:set_value("mail_" .. value .. "_name", name)
  self:set_value("mail_" .. value .. "_obtained", true)
  self:set_value("mail_" .. value .. "_opened", false)
  self:set_value("mail_" .. value .. "_highlighted", false)

  mail_bag:add_amount(1)
  
  self:get_hero():start_treasure("mail")
end

function game_metatable:has_mail(value)
  return self:get_value("mail_" .. value .. "_obtained")
end

function game_metatable:get_mail_name(value)
  return self:get_value("mail_" .. value .. "_name")
end

-- Get the Player Name
function game_metatable:get_player_name()
  return self:get_value("player_name")
end