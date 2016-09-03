local roc_cape_controller = {
  slot = "item_1",
  opposite_slot = "item_2",
  opposite_slot_to_number = 2,
  
}

roc_cape_controller.direction = {[0]="right",[1]="up",[2]="left",[3]="down"}
roc_cape_controller.max_speed = 100
roc_cape_controller.max_height = 48
roc_cape_controller.shadow_tile = "entities/shadow"
roc_cape_controller.sound_jump_0 = "jump"
roc_cape_controller.sound_jump_1 = "items/roc_cape/fly"
roc_cape_controller.sound_jump_2 = "characters/link/voice/roc_cape_down_thrust_charging"
roc_cape_controller.sound_jump_3 = "characters/link/voice/roc_cape_down_thrust"

roc_cape_controller.hero_down_thrust_tunic = ""

local current_height, ticks = 0, 0

-- these need to go away
local sprite
local tile
local hero_new_sprite
local sword_entity
local down_thrust_check_script
local tile
local hero_speed
local kb_up
local kb_down
local kb_left
local kb_right
local jp_up
local jp_left
local jp_right
local jp_down

local can_down_thrust = false
local is_down_thrusting = false

-- todo disable pickable, speed control, shake, cutscene collision event handler

function roc_cape_controller:start_roc_cape(game)
  self.game = game
  self.hero = self.game:get_hero()
  self.hero_direction = self.hero:get_direction()
  self.hero_x, self.hero_y, self.hero_layer = self.hero:get_position()
  self.hero:unfreeze()
  self.game:set_item_on_use(true)
  
  --Direction Fix the hero
  self.hero:set_fixed_direction(self.hero_direction)
  self.hero:set_fixed_animations("roc_cape_stopped", "roc_cape_walking")
  
  self.current_tunic = self.game:get_ability("tunic")
  self.hero_flying_tunic = "hero/tunic"..self.current_tunic
  self.hero_flying_tunic_roc = "hero/item/roc_cape/roc_cape.tunic_"..self.current_tunic
  self.hero_down_thrust_tunic = "hero/item/roc_cape/roc_cape_down_thrust.tunic_"..self.current_tunic
  
  tile = self.game:get_map():create_custom_entity({x = self.hero_x, y = self.hero_y, layer = self.hero_layer,direction = 0, width = 8, height = 8})
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  tile:create_sprite(roc_cape_controller.shadow_tile)
  tile:get_sprite():set_animation("big")
  
  sol.audio.play_sound(self.sound_jump_0)
  self.hero:save_solid_ground() --todo
  self.hero:set_invincible(true, 10000000)
  self.hero:set_visible(false)
  
  hero_new_sprite = self.game:get_map():create_custom_entity({x = self.hero_x, y = self.hero_y, layer = self.hero_layer, direction = 0, width = 8, height = 8})
  hero_new_sprite:set_modified_ground("traversable")
  hero_new_sprite:create_sprite(self.hero_flying_tunic)
  hero_new_sprite:set_direction(self.hero:get_direction())
  hero_new_sprite:get_sprite():set_animation("rolling")
   
  hero_speed = 88
  
  function tile:on_update() 
    local hero_x, hero_y, hero_layer = roc_cape_controller.hero:get_position()
    tile:set_position(hero_x, hero_y + (roc_cape_controller.max_height - roc_cape_controller.max_height), hero_layer) 
  end
  
  sol.timer.start(self, 20, function() can_down_thrust = true end)
  
  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.hero:get_position()
	current_height = current_height + 1
	if current_height >= 13 then can_down_thrust = false end
	if current_height >= 16 then
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
  
  if self.game:get_value("_item_slot_2") == "roc_cape" then 
    self.slot = "item_2" 
	self.opposite_slot = "item_1"
    self.opposite_slot_to_number = 1
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
  
  self.game:set_custom_command_effect("action", "clear")
  sol.menu.start(self.game:get_map(), self)
end

-- Return true if the hero can jump/save on this ground.
local function is_solid_ground(ground_type)
  return ((ground_type == "traversable") or (ground_type == "low_wall")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water")  or (ground_type == "ice"))
end

function roc_cape_controller:clip_determinate_second_jump()
  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.hero:get_position()
	current_height = current_height - 1
	if current_height <= 5 then
	  if self.game:is_command_pressed(self.slot) then
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

function roc_cape_controller:roc_jump()
  sol.audio.play_sound(self.sound_jump_1)
  hero_new_sprite:create_sprite(self.hero_flying_tunic_roc)
  hero_new_sprite:set_direction(self.hero_direction)

  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.hero:get_position()
	current_height = current_height + 1
	if current_height >= self.max_height then
	  current_height = self.max_height
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

function roc_cape_controller:land()
  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = self.hero:get_position()
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

function roc_cape_controller:has_landed()
  self.hero:set_visible(true)
  hero_new_sprite:set_position(self.hero:get_position())
  current_height, ticks = 0, 0
  
  if is_solid_ground() == "shallow_water" then
    self.hero:set_walking_speed(88 * 4 / 5)
  else
    self.hero:set_walking_speed(88)
  end
  
  hero_new_sprite:remove()
  tile:remove() 
  
  sol.timer.start(self, 10, function()
    local ground = self.game:get_map():get_ground(self.hero:get_position())
      if is_solid_ground(ground) then
        self.hero:reset_solid_ground()
      end
  end)
  sol.menu.stop(self)
end

function roc_cape_controller:on_command_pressed(commands)
  local hero = self.game:get_hero()
  for dir_hero, str_dir in pairs(self.direction) do
    if self.game:is_command_pressed(str_dir) then 
	  if dir_hero == ((hero_new_sprite:get_direction() + 1) %4) or dir_hero == ((hero_new_sprite:get_direction() + 3) %4) or dir_hero == ((hero_new_sprite:get_direction() + 2) %4) then
	  -- The player pressed a side direction or the opposite direction
		sol.timer.start(self, 25, function()
		  hero_speed = hero_speed - 1
		  hero:set_walking_speed(hero_speed)
		return self.game:is_command_pressed(str_dir) and hero_speed ~= 0
		end)
	  elseif dir_hero == hero_new_sprite:get_direction() then
	  -- The player pressed the same direction as the new_sprite direction, physically, he is faster then the walking speed besause of gravity.
	    sol.timer.start(self, 25, function()
		  hero_speed = hero_speed + 4
		  hero:set_walking_speed(hero_speed)
		  return self.game:is_command_pressed(str_dir) and hero_speed ~= 100 
		end)
	  end		  
	end
  end
  
  if commands == "attack" and can_down_thrust and not self.game.is_down_thrusting and self.game:is_skill_learned(6) then
	self:start_down_thrust()  -- Down thrust only if the skill is learned
  end
  
 return true
end

function roc_cape_controller:on_command_released(commands)
  local hero = self.game:get_hero()
  local dir = hero:get_direction()
  
  if commands == self.slot and not self.game.is_down_thrusting then
	can_down_thrust = false
    sol.timer.stop_all(self)
    self:land()
  end
return true
end

function roc_cape_controller:start_down_thrust()
  local hero = self.hero
  local x, y, layer = hero:get_position()
  local dx, dy, dl = hero_new_sprite:get_position()
  local tims = 0
  
  self.game.is_down_thrusting = true

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
  
  self.hero:freeze()
  sol.audio.play_sound(self.sound_jump_2)
  
  -- reload the sprite animation : delete everything and remade it
  hero_new_sprite:remove()
  hero_new_sprite = self.game:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  hero_new_sprite:set_modified_ground("traversable")
  hero_new_sprite:create_sprite(self.hero_down_thrust_tunic)
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

function roc_cape_controller:down_thrust_finish()
  local tickss = 0
  local hero = self.game:get_hero()
  sol.audio.play_sound(roc_cape_controller.sound_jump_3)
  
  hero_new_sprite:get_sprite():set_animation("charging_ground")
  
  sol.timer.start(self, 10, function()
    local hero_x, hero_y, hero_layer = hero:get_position()
	local get_ground = self.game:get_map():get_ground(hero_x, hero_y, hero_layer)
	current_height = current_height - 2
	if current_height == 8 then tile:remove() end
	if current_height <= 6 then
	  current_height = 6
	  tickss = tickss + 1
	   if (is_solid_ground(get_ground)) or tickss >= 45 then
		  self:attack()
		  tickss = 0
		  return false
		else
		  self.game.is_down_thrusting = false
		  self:has_landed()
		  sword_entity:remove()
		  self.hero:unfreeze()
		  tickss = 0
		  return false
	    end
	end
    hero_new_sprite:set_position(hero_x, hero_y - current_height, hero_layer)
	return true
	end)
end
	
function roc_cape_controller:attack()
  local x, y, l = self.game:get_hero():get_position()
  local dx, dy, dl = hero_new_sprite:get_position()
  --recreate the tile
  tile = self.game:get_map():create_custom_entity({x = x, y = y, layer = l, direction = 0, width = 8, height = 8})
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  tile:create_sprite(roc_cape_controller.shadow_tile)
  tile:get_sprite():set_animation("big")
    
  sword_entity:set_position(dx, dy - 4, l)
  sword_entity:check_enemy(sword_entity)
  sol.timer.start(self, 450, function()
     self.game.is_down_thrusting = false
     tile:remove()
     sword_entity:remove()
	 self:has_landed()
	 self.hero:unfreeze()
	 self:has_landed()
   end)
end
 
   
function roc_cape_controller:on_finished()
   self.hero:set_invincible(false)
   self.hero:set_visible(true)
   self.game:set_custom_command_effect("action", nil)
   
   current_height, ticks = 0, 0
   can_down_thrust = false
   
   self.hero:cancel_direction_fix()
   
   for teleporters in self.game:get_map():get_entities("teleporter") do
   teleporters:set_enabled(true)
   end
   
   for walkable_switch in self.game:get_map():get_entities("walk_switch") do
   walkable_switch:set_locked(false)
   end
   
   self.game:set_item_on_use(false)
   self.game:get_item("roc_cape"):set_finished()  
   
   sol.timer.stop_all(self)
   sol.menu.stop(self)
end
   
return roc_cape_controller