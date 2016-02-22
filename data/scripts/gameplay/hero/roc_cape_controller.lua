--[[
/script\Jump Controller Script.
/author\Made by MetalZelda - 16.02.2016

/desc\Custom Jump
/instruction\Custom Jump to be compatible with the Roc's Cape

/copyright\Credits if you plan to use the script would be nice. Not for resale. Script and project are part of educationnal project.
]]

local game = ...
local jump_hdl = {}

local dirs = {[0]="right",[1]="up",[2]="left",[3]="down"}
local command_dir = dirs[dir]
local current_height, ticks = 0, 0
local max_speed = 100
local height_max = 48
local slot, hero_speed, sprite, tile, hero_new_sprite, kb_up, kb_down, kb_left, kb_right, jp_up, jp_left, jp_right, jp_down, sword_entity, down_thrust_check_script
local first_jump = math.floor(height_max / 3)
local can_down_thrust = false
local with_shield = game:get_ability("shield") and "_with_shield" or nil

-- todo disable pickable, speed control, shake, voice, tile when down thrust

function game:start_roccape_jump()
  sol.menu.start(self, jump_hdl, false)
end

function game:stop_roccape_jump()
  sol.menu.stop(jump_hdl)
end

function jump_hdl:on_started()
  self.game = game
  self:first_jump()
  
  self.game.is_down_thrusting = false
  slot = "item_1"
  if self.game:get_value("_item_slot_2") == "roc_cape" then 
    slot = "item_2" 
  end
  -- disable teletransporters while jumping
  for teleporters in self.game:get_map():get_entities("teleporter") do
    teleporters:set_enabled(false)
  end
  -- disable walkable switch during the jump
  for walkable_switch in self.game:get_map():get_entities("walk_switch") do
    walkable_switch:set_locked(true)
  end
  -- disable teleporters during the jump
  for custom_teleporters in self.game:get_map():get_entities("custom_teleporters") do
    custom_teleporters:set_enabled(false)
  end
  
  local kb_action_key = self.game:get_command_keyboard_binding("action")
  local kb_attack_key = self.game:get_command_keyboard_binding("attack")
  local kb_item_1_key = self.game:get_command_keyboard_binding("item_1")
  local kb_item_2_key = self.game:get_command_keyboard_binding("item_2")
  local jp_action_key = self.game:get_command_joypad_binding("action")
  local jp_attack_key = self.game:get_command_joypad_binding("attack")
  local jp_item_1_key = self.game:get_command_joypad_binding("item_1")
  local jp_item_2_key = self.game:get_command_joypad_binding("item_2")

  if self.game:get_value("_item_slot_1") ~= "roc_cape" then self.game:set_command_keyboard_binding("item_1", nil); self.game:set_command_joypad_binding("item_1", nil) end
  if self.game:get_value("_item_slot_2") ~= "roc_cape" then self.game:set_command_keyboard_binding("item_2", nil); self.game:set_command_joypad_binding("item_2", nil) end
  self.game:set_command_keyboard_binding("attack", nil); self.game:set_command_joypad_binding("attack", nil)
  self.game:set_command_keyboard_binding("action", nil); self.game:set_command_joypad_binding("action", nil)
  
  self.game:set_value("item_saved_kb_action", kb_action_key)
  self.game:set_value("item_saved_kb_attack", kb_attack_key)
  self.game:set_value("item_1_kb_slot", kb_item_1_key)
  self.game:set_value("item_2_kb_slot", kb_item_2_key)
  self.game:set_value("item_saved_jp_action", jp_action_key)
  self.game:set_value("item_saved_jp_attack", jp_attack_key)
  self.game:set_value("item_1_jp_slot", jp_item_1_key)
  self.game:set_value("item_2_jp_slot", jp_item_2_key)
  self.game:set_pause_allowed(false)
end

-- Return true if the hero can jump/save on this ground.
local function is_solid_ground(ground_type)
  return ((ground_type == "traversable") or (ground_type == "low_wall")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water")  or (ground_type == "ice"))
end


function jump_hdl:on_update()
  self.game:set_custom_command_effect("action", "clear")
end

function jump_hdl:first_jump()

  local hero = self.game:get_hero()
  local dir = hero:get_direction()
  local x,y,layer = hero:get_position()
  
  tile = self.game:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  tile:create_sprite("entities/shadow")
  tile:get_sprite():set_animation("big")
  
  sol.audio.play_sound("jump")
  hero:save_solid_ground()
  hero:set_invincible(true, 10000000)
  hero:set_visible(false)
  
  hero_new_sprite = self.game:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  hero_new_sprite:set_modified_ground("traversable")
  hero_new_sprite:create_sprite("hero/tunic"..self.game:get_ability("tunic"))
  hero_new_sprite:set_direction(hero:get_direction())
  hero_new_sprite:get_sprite():set_animation("rolling")
  
  if self.game:get_hero().is_walking then
    hero_speed = 88
  else
    hero_speed = 0
  end
  
  function tile:on_update() 
    local hero_x, hero_y, hero_layer = hero:get_position()
    tile:set_position(hero_x, hero_y + (height_max - height_max), hero_layer) 
  end
  
  sol.timer.start(self, 20, function() can_down_thrust = true end)
  
  sol.timer.start(self, 10, function()
  
    local hero_x, hero_y, hero_layer = hero:get_position()
	current_height = current_height + 1
	
	if current_height >= 13 then can_down_thrust = false end
	
	if current_height >= first_jump then
	  sol.timer.start(25, function()
	  if not self.game.is_down_thrusting then
	    self:clip_determinate_second_jump()
	  end
	  end)
	  return false
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer)
	return true
  end)
end

function jump_hdl:clip_determinate_second_jump()

  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.game:get_hero():get_position()
	current_height = current_height - 1
	if current_height <= 5 then
	  if self.game:is_command_pressed(slot) then
        self:roc_jump()
	  else
	    self:land()
      end
	  return false
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer)
	return true
  end)
end

function jump_hdl:roc_jump()

  local hero = self.game:get_hero()
  local x,y,layer = hero:get_position()
  
  sol.audio.play_sound("items/roc_cape/fly")
  
  -- reload the sprite animation : delete everything and remade it
  hero_new_sprite:remove()
  hero_new_sprite = self.game:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  hero_new_sprite:set_modified_ground("traversable")
  hero_new_sprite:create_sprite("hero/item/roc_cape/roc_cape.tunic_"..self.game:get_ability("tunic"))
  hero_new_sprite:set_direction(hero:get_direction())
  

  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.game:get_hero():get_position()
	current_height = current_height + 1
	if current_height >= height_max then
	  current_height = height_max
	  ticks = ticks + 1
	  if ticks >= 30 then
	    self:land()
		return false
	  end
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer + 1)
	return true
  end)
end

function jump_hdl:land()

  local hero = self.game:get_hero()
  local x,y,layer = hero:get_position()
  
  self.game:set_command_keyboard_binding("item_1", nil); self.game:set_command_joypad_binding("item_1", nil)
  self.game:set_command_keyboard_binding("item_2", nil); self.game:set_command_joypad_binding("item_2", nil)

  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.game:get_hero():get_position()
	current_height = current_height - 1
	if current_height <= 0 then
	  current_height = 0
	  self:has_landed()
	  return false
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer + 1)
	return true
  end)
end

function jump_hdl:has_landed()

  local hero = self.game:get_hero()
  tile:remove()  
  hero:set_visible(true)
  hero_new_sprite:set_position(hero:get_position())
  current_height, ticks = 0, 0
  if is_solid_ground() == "shallow_water" then
    hero:set_walking_speed(88 * 4 / 5)
  else
    hero:set_walking_speed(88)
  end
  hero_new_sprite:remove()
  sol.timer.start(self, 10, function()
    local ground = self.game:get_map():get_ground(hero:get_position())
      if is_solid_ground(ground) then
        hero:reset_solid_ground()
      end
    end)
  sol.menu.stop(self)
end

function jump_hdl:on_command_pressed(commands)
  local hero = self.game:get_hero()
  local dir = hero:get_direction()
  local handled = true
 
    for dir_hero ,str_dir in pairs(dirs) do
        if self.game:is_command_pressed(str_dir) then
		  if hero_new_sprite:get_direction() ~= dir_hero then
		  
		    if dir_hero == (hero_new_sprite:get_direction() / 2) % 4 then
			  sol.timer.start(self, 20, function()
			      hero_speed = hero_speed - 1
		          hero:set_walking_speed(hero_speed)
				  print(hero_speed)
			  return true
		      end)
			end
		  else
		  
		  print("Dir")
		  
		  end		  
		end
    end
 handled = true
end

--since commands are disabled, we need to check a key
function jump_hdl:on_key_pressed(key)
  if key == (self.game:get_value("item_saved_kb_attack") or self.game:get_value("item_saved_jp_attack")) and can_down_thrust and not self.game.is_down_thrusting and self.game:is_skill_learned(6) then
    self:start_down_thrust()
  end
end

function jump_hdl:on_command_released(commands)
  local hero = self.game:get_hero()
  local dir = hero:get_direction()
  
  if commands == slot and not self.game.is_down_thrusting then
	can_down_thrust = false
    sol.timer.stop_all(self)
    self:land()
  end
end

function jump_hdl:start_down_thrust()
  local folder = "characters/link/voice/"
  local hero = self.game:get_hero()
  local x, y, layer = hero:get_position()
  local dx, dy, dl = hero_new_sprite:get_position()
  local tims = 0
  local sprite
  
  self.game:set_command_keyboard_binding("item_1", nil); self.game:set_command_joypad_binding("item_1", nil)
  self.game:set_command_keyboard_binding("item_2", nil); self.game:set_command_joypad_binding("item_2", nil) 
  
  sword_entity = self.game:get_map():create_custom_entity({
    model = "hero/down_thrust",
    x = dx, 
	y = dy - 5, 
	layer = dl, 
	direction = 0,
	sprite = "hero/item/roc_cape/down_thrust.sword"
  })
  
  sword_entity:get_sprite():set_animation(self.game:get_ability("sword"))
  sword_entity:bring_to_front()
  
  sol.timer.start(self, 10, function()
    local d2x, d2y, d2l = hero_new_sprite:get_position()
	if hero_new_sprite:get_sprite():get_frame() == 3 then
	  sword_entity:set_position(d2x, d2y - 6, d2l + 1)
	elseif hero_new_sprite:get_sprite():get_frame() == 4 then
	  sword_entity:set_position(d2x, d2y - 8, d2l + 1)
	else
	  sword_entity:set_position(d2x, d2y, d2l + 1)
	end
	return true
  end)
  
  self:can_move(false)
  self.game.is_down_thrusting = true
  
  sol.audio.play_sound(folder.."roc_cape_down_thrust_charging")
  
  -- reload the sprite animation : delete everything and remade it
  hero_new_sprite:remove()
  hero_new_sprite = self.game:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  hero_new_sprite:set_modified_ground("traversable")
  hero_new_sprite:create_sprite("hero/item/roc_cape/roc_cape_down_thrust.tunic_"..self.game:get_ability("tunic"))
  hero_new_sprite:set_direction(0)
  
  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = hero:get_position()
	current_height = current_height + 1
	if current_height >= 24 then
	  current_height = 24
	  tims = tims + 1
	  if tims >= 40 then
	    self:down_thrust_finish()
		tims = 0
		return false
	  end
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer)
	return true
  end)

end

function jump_hdl:down_thrust_finish()

  local folder = "characters/link/voice/"
  local tickss = 0
  local hero = self.game:get_hero()
  sol.audio.play_sound(folder.."roc_cape_down_thrust")
  
  hero_new_sprite:get_sprite():set_animation("charging_ground")

  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = hero:get_position()
	current_height = current_height - 2
	if current_height <= 6 then
	  current_height = 6
	  tickss = tickss + 1
	  tile:remove() --todo
	  if self.game:get_map():get_ground(hero_x, hero_y, hero_layer) == "deep_water" or self.game:get_map():get_ground(hero_x, hero_y, hero_layer) == "hole" or self.game:get_map():get_ground(hero_x, hero_y, hero_layer) == "lava" or tickss >= 45 then
	    self.game.is_down_thrusting = false
		sword_entity:remove()
				
		self:has_landed()
		self:can_move(true)
		tickss = 0
		
		
        return false
	  else
		tickss = 0
	    self:attack()
		return false
	  end
	  
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer)
	return true
  end)
end

function jump_hdl:attack()
  local _, _, l = self.game:get_hero():get_position()
  local dx, dy, dl = hero_new_sprite:get_position()
  sword_entity:set_position(dx, dy - 4, l)
  sword_entity:check_enemy(sword_entity)
  
  sol.timer.start(self, 450, function()
    self.game.is_down_thrusting = false
	tile:remove()
	sword_entity:remove()
	self:has_landed()
	self:can_move(true)
    self:has_landed()
  end)
  
end

function jump_hdl:can_move(boolean)
 
 if not boolean then
   kb_up = self.game:get_command_keyboard_binding("up")
   kb_down = self.game:get_command_keyboard_binding("down")
   kb_left = self.game:get_command_keyboard_binding("left")
   kb_right = self.game:get_command_keyboard_binding("right")
   jp_up = self.game:get_command_joypad_binding("up")
   jp_left = self.game:get_command_joypad_binding("left")
   jp_right = self.game:get_command_joypad_binding("right")
   jp_down = self.game:get_command_joypad_binding("down")
   
   self.game:simulate_command_released("up")
   self.game:simulate_command_released("down")
   self.game:simulate_command_released("left")
   self.game:simulate_command_released("right")

   self.game:set_command_keyboard_binding("up", nil)
   self.game:set_command_keyboard_binding("down", nil)
   self.game:set_command_keyboard_binding("left", nil)
   self.game:set_command_keyboard_binding("right", nil)
   self.game:set_command_joypad_binding("up", nil)
   self.game:set_command_joypad_binding("down", nil)
   self.game:set_command_joypad_binding("left", nil)
   self.game:set_command_joypad_binding("right", nil)
 else
   self.game:set_command_keyboard_binding("up", kb_up)
   self.game:set_command_keyboard_binding("down", kb_down)
   self.game:set_command_keyboard_binding("left", kb_left)
   self.game:set_command_keyboard_binding("right", kb_right)
   self.game:set_command_joypad_binding("up", jp_up)
   self.game:set_command_joypad_binding("down", jp_down)
   self.game:set_command_joypad_binding("left", jp_left)
   self.game:set_command_joypad_binding("right", jp_right)
 end
end

function jump_hdl:on_finished()
  sol.timer.stop_all(self)
  
  self.game:set_command_keyboard_binding("item_1", self.game:get_value("item_1_kb_slot")); self.game:set_command_joypad_binding("item_1", self.game:get_value("item_1_jp_slot"))
  self.game:set_command_keyboard_binding("item_2", self.game:get_value("item_2_kb_slot")); self.game:set_command_joypad_binding("item_2", self.game:get_value("item_2_jp_slot"))
  self.game:set_command_keyboard_binding("action", self.game:get_value("item_saved_kb_action")); self.game:set_command_joypad_binding("action", self.game:get_value("item_saved_jp_action"))
  self.game:set_command_keyboard_binding("attack", self.game:get_value("item_saved_kb_attack")); self.game:set_command_joypad_binding("attack", self.game:get_value("item_saved_jp_attack"))

  self.game:set_pause_allowed(true)
  self.game:get_hero():set_invincible(false)
  self.game:get_hero():set_visible(true)
  self.game:set_custom_command_effect("action", nil)
  self.game:set_item_on_use(false)
  
  current_height, ticks = 0, 0
  can_down_thrust = false
  
  --todo
  for _ , str_dir in pairs(dirs) do
    if self.game:get_hero():get_animation() ~= "stopped"..with_shield then
	  if self.game:is_command_pressed(str_dir) then
	    self.game:simulate_command_pressed(str_dir % 2)
		
	  end
	end
  end
  
  for teleporters in self.game:get_map():get_entities("teleporter") do
    teleporters:set_enabled(true)
  end
  
  for walkable_switch in self.game:get_map():get_entities("walk_switch") do
    walkable_switch:set_locked(false)
  end
  
  self.game:get_item("roc_cape"):set_finished()  
  
end