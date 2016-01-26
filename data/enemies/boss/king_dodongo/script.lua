local enemy = ...
local sprite = enemy:create_sprite("enemies/boss/d_king/body")
local head_sprite
local enemy_spawned
local can_attack
local number_of_hit = 4
local attack_done
local timer
local state = "created"

local function protect_parts_from_custom_item()
-- Protect the body from being damaged from any items
  enemy:set_hammer_reaction("protected", sprite)
  enemy:set_attack_arrow("protected", sprite)
  enemy:set_ice_reaction("protected", sprite)
  enemy:set_fire_reaction("protected", sprite)
  enemy:set_deku_reaction("protected", sprite)
  enemy:set_attack_hookshot("protected", sprite)
  enemy:set_attack_boomerang("protected", sprite)
-- Protect the head from being damaged from any items
  -- enemy:set_hammer_reaction("protected", head_sprite)
  -- enemy:set_attack_arrow("protected", head_sprite)
  -- enemy:set_ice_reaction("protected", head_sprite)
  -- enemy:set_fire_reaction("protected", head_sprite)
  -- enemy:set_deku_reaction("protected", head_sprite)
  -- enemy:set_attack_hookshot("protected", head_sprite)
  -- enemy:set_attack_boomerang_sprite("protected", head_sprite)
end

local function start_movement(target, speed)
  local movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_angle(3 * math.pi / 2)
  movement:start(target)
end

function enemy:on_created()
	self:set_life(20)
	self:set_damage(3)
	self:set_push_hero_on_sword(true)
	self:set_pushed_back_when_hurt(false)
	self:set_hurt_style("boss")
	self:set_optimization_distance(0)
	self:set_invincible_sprite(sprite)
	self:set_attack_consequence_sprite(sprite, "sword", "custom")
	
	start_movement(self, 10)
	-- can_attack = true
	self:spawn_falling_rocks("ground_pound")
	
    protect_parts_from_custom_item()
end

function enemy:on_custom_attack_received(attack, sprite)
  if attack == "sword" then
    if can_attack then
	sol.audio.play_sound("ennemies/_boss/king_dodongo/hit")
	self:get_sprite():set_direction(1)
	self:remove_life(enemy:get_game():get_ability('sword'))
	sol.timer.start(250, function()
		self:get_sprite():set_direction(0)
		
	end)
	else
    sol.audio.play_sound("sword_tapping")
	end
  end
  if self:get_life() <= 1 then
	sol.audio.play_music("dungeons/boss/dying", function()
	 sol.audio.play_music("dungeons/boss/beaten")
	 self:get_map():get_entity("heart_container"):set_enabled(true)
	 self:get_map():get_entity("k_dodongo_dead_body"):set_enabled(true)
	end)
  end  
end

function enemy:on_hurt(attack)
if attack == "thrown_item" then
    print("thro")
end
end

function enemy:on_hurt_by_sword(hero, enemy_sprite)
  if (enemy_sprite == self:get_sprite() or enemy_sprite == self:get_sprite()) and can_attack then
    sol.audio.play_sound("ennemies/_boss/king_dodongo/hit")
  end
end

function enemy:on_restarted()
timer = 5000 / (number_of_hit + 1)
-- sprite:get_sprite():set_animation("walking")

  if can_attack then
    sprite:set_animation("hurt")
	self:set_invincible_sprite(nil)
	sol.timer.start(self, timer, function()
	  -- self:jump(to_roll)
	end) 
  elseif not can_attack and attack_done then
    self:get_sprite():set_animation("rolling")
  end  
end

function enemy:spawn_falling_rocks(context)
local number = 0
local target_time = 0
local target_rock = 0

  local function randomnize(number)
    math.randomseed(os.time() - os.clock() * 10000000)
    return math.random(number)
  end

  if context == "ground_pound" then
    target_time = 65
	target_rock = 250
  elseif context == "rolling" then
    target_time = 70
	target_rock = 50
  elseif context == "jump" then
    target_time = 80
	target_rock = 40
  end
  
  sol.timer.start(target_time, function() --65
	  local map_x, map_y, map_w, map_h = self:get_map():get_camera_position()
	  local hx, hy = self:get_map():get_hero():get_position()
		enemy:get_map():create_enemy({
		  x = randomnize(map_x + hx),
		  y = randomnize(map_y + ((hy / 2) + 64)), 
		  layer = 2,
		  direction = 0,
		  breed = "projectiles/falling_rock"
		})
		number = number + 1
		return number <= target_rock
	end)
end

function enemy:start_roll()
state = "rolling"
start_movement(self, 87)
end

function enemy:on_obstacle_reached(movement)
  local function randomnize(number)
    math.randomseed(os.time() - os.clock() * 10000000)
    return math.random(number)
  end
  
  if movement ~= nil then
    randomnize(2)
	if randomnize == 1 then
	print("1")
	else
	print("2")
	end
  end
end

function sprite:on_frame_changed(animation, frame)
  -- The Head sprite need to be sync with the body
  -- mouth_collision:set_frame(body_sprite:get_frame())
  if animation == "walking" and frame == 2 or frame == 6 then
	sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
  end
end