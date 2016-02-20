local enemy = ...
-- This is called when the enemy has been created
local number_of_hit = 0
local timer, state, can_attack, movement
local fight_started, is_inhaling, obstacle_reached = false
local intro_bgm = "dungeons/boss/k_dodongo_intro"
local loop_bgm = "dungeons/boss/k_dodongo_loop"
local can_attack_bgm = "dungeons/boss/k_dodongo_can_attack"
local sprite = enemy:create_sprite("enemies/boss/d_king/body")
local head_sprite = enemy:get_map():get_entity("kdongo_mouth")
local down = 3 * math.pi / 2
local up = math.pi / 2

--todo cutscene

enemy:set_hammer_reaction("protected", sprite)
enemy:set_attack_arrow("protected", sprite)
enemy:set_ice_reaction("protected", sprite)
enemy:set_fire_reaction("protected", sprite)
enemy:set_deku_reaction("protected", sprite)
enemy:set_attack_hookshot("protected", sprite)
enemy:set_attack_boomerang("protected", sprite)

enemy:set_life(20)
enemy:set_damage(3)
enemy:set_push_hero_on_sword(true)
enemy:set_pushed_back_when_hurt(false)
enemy:set_hurt_style("boss")
enemy:set_optimization_distance(0)
enemy:set_invincible(sprite)
enemy:set_attack_consequence_sprite(sprite, "sword", "custom")

local function straight_movement(angle, speed, target)
  if movement ~= nil then movement:stop() end
  movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_angle(angle)
  movement:set_max_distance(12000)
  movement:set_ignore_obstacles(false)
  movement:start(target)
end

function enemy:on_restarted()
  enemy:jump("rolling")
end
	
function enemy:on_update()
  if self:exists() then
    if not is_inhaling then
	  head_sprite:set_position(-32, -32)
	end
  end
  if self:get_game().king_dodongo_swallowing_bomb then
	head_sprite:set_enabled(false)
    self:get_game().king_dodongo_swallowing_bomb = false
	self:start_damage_seq()
  end
end

function enemy:start_damage_seq()
  is_inhaling = false
  sol.timer.stop_all(self)
  sprite:set_direction(0)
  sprite:set_animation("swallowb")
  sol.audio.play_sound("ennemies/_boss/king_dodongo/swallow")
  sprite:set_frame_delay(5000) -- frames are different, control them manually
  sol.timer.start(self, 250, function()
    sprite:set_frame(1)
	sol.timer.start(self, 250, function()
	  sprite:set_frame(2)
	  sol.timer.start(self, 250, function()
	    sprite:set_frame(3)
		sol.timer.start(self, 1000, function()
		  sprite:set_frame(4)
		  sol.audio.play_sound("ennemies/_boss/king_dodongo/hit")
		  sol.audio.play_sound("ennemies/_boss/king_dodongo/hit")
		  sol.audio.play_sound("explosion")
		  sol.audio.play_sound("explosion")
		  sol.timer.start(self, 500, function()
		    sprite:set_frame(5)
			sol.timer.start(500, function()
			  sprite:set_animation("hurt")
			  can_attack = true
			  sol.audio.play_music(can_attack_bgm)
			end)
		  end)
		end)
	  end)
	end)
  end)
end
	
-- called when the boss is about to inhale, this is where he is vulnerable to the bomb
function enemy:inhale()
  local px, py = self:get_position()
  sprite:set_animation("vulnerable")
  movement:stop()
  head_sprite:set_enabled(true)
  head_sprite:set_position(px, py)
  sprite:set_frame_delay(5000)
  is_inhaling = true
  sol.timer.start(self, 500, function()
   sprite:set_frame(1)
   	  sol.timer.start(self, 500, function()
	   sprite:set_frame(2)
	   	  sol.timer.start(self, 500, function()
		   sprite:set_frame(3)
				sol.timer.start(self, 500, function()
					sprite:set_frame(4)
					sol.timer.start(self, 500, function()
					    is_inhaling = false
						sprite:set_frame(5)
						sol.timer.start(self, 250, function()
						  self:exhale()
						end)
					end)
				end)
		  end)
	  end)
  end)
  sol.audio.play_sound("ennemies/_boss/king_dodongo/inhale")
end
	
-- Spawn fire
function enemy:exhale()
  sol.audio.play_sound("ennemies/_boss/king_dodongo/exhale_roll")
  sol.timer.start(250, function()
	sprite:set_frame(4)
	sol.timer.start(250, function()
	  sprite:set_frame(3)
	  sol.timer.start(800, function()
	    sprite:set_frame(2)
		sol.timer.start(100, function()
			sprite:set_frame(1)
			sol.timer.start(100, function()
				sprite:set_frame(0)
				sol.timer.start(100, function()
				  sprite:set_frame(0)
				  sol.timer.start(600, function()
				  local rand = math.random(1, 2)
				    if enemy:get_distance(enemy:get_map():get_entity("wall")) > 192 then
					  sol.timer.start(500, function()
					    if rand == 1 then
					      self:walk()
						else
						  self:jump("rolling")
						end
					  end)	
					else
				    self:jump("obstacle_reached")
					end
				  end)
				end)
			end)
		end)
      end)
    end)
  end)
  local spawned_fire = 0
  sol.timer.start(100, function()
	self:shoot_fire()
	spawned_fire = spawned_fire + 1
	return spawned_fire < 15
  end)
end
	
function enemy:walk()
  state = "walk"
  sprite:set_animation("walking")
  sprite:set_direction(0)
  straight_movement(down, 10, sprite)
  straight_movement(down, 10, enemy)
  local function randomnize(number)
    math.randomseed(os.time() - os.clock() * 10000000)
    return math.random(number)
  end
  sol.timer.start(self, 2000 + randomnize(12000), function()
	local rand = math.random(1, 10)
	movement:stop()
	if rand == 1 then
	  sol.timer.start(1250, function()
	    self:ground_pound()
	  end)
	elseif rand >= 2 and rand <=6 then
	  sol.timer.start(750, function()
	  self:jump("rolling")
	  end)
	elseif rand >= 7 and rand <= 10 then
	  sol.timer.start(500, function()
	    self:inhale()
	  end)
	end
  end)
end
	
function enemy:jump(to)
  if to == "rolling" then
    sprite:set_animation("jumping")
	sol.timer.start(10, function()
		local m = sol.movement.create("straight")
		m:set_speed(120)
		m:set_angle(1 * math.pi / 2)
		m:set_max_distance(24)
		m:set_ignore_obstacles(false)
		m:start(sprite, function()
		  sprite:set_animation("rolling")
		  sol.timer.start(self, 200, function()
			  straight_movement(down, 70, sprite)
			    sol.timer.start(self, 200, function()
				self:shake_screen(self:get_map(), 0, 20)
				sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
				sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
				enemy:spawn_falling_rocks("jump")
				state = "rolling"
				straight_movement(down, 80, enemy)
			  end)
		   end)
		end)
	end)
  elseif to == "obstacle_reached" then
	sprite:set_animation("jumping")
	sol.timer.start(100, function()
	sprite:set_direction(1)
	sol.timer.start(10, function()
	    local x, y = enemy:get_position()
		enemy:set_position(x, y, 2)
		sprite:fade_out(10)
		local m = sol.movement.create("straight")
		m:set_speed(300)
		m:set_angle(up)
		m:set_max_distance(96)
		m:set_ignore_obstacles(true)
		m:start(sprite, function()
		sprite:set_xy(0, 24)
		  enemy:set_position(216, 144, 2)
		  sol.timer.start(3000, function()
		      sprite:set_direction(2)
			  sol.timer.start(600, function()
				  sprite:set_xy(0, -96)
				  sprite:fade_in(20)
				  local n = sol.movement.create("straight")
				  n:set_speed(500)
				  n:set_angle(down)
				  n:set_max_distance(96)
				  n:set_ignore_obstacles(false)
				  n:start(sprite, function()
				    enemy:set_position(216, 144, 0)
				    self:shake_screen(self:get_map(), 0, 300)
					-- spam the sound, sounds like a big stomp
					sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
					sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
					sol.timer.start(200, function()
					  enemy:spawn_falling_rocks("jump")
					  sol.timer.start(100, function()
					    sprite:set_direction(1)
						sol.timer.start(200, function()
						  sprite:set_direction(0)
						  sprite:set_animation("walking")
						  self:walk()
						end)
					  end)
					end)
				  end)
			   end)
	      end)
		end)
	end)
  end)
  elseif to == "recover" then
	sprite:set_animation("jumping")
	sprite:set_frame_delay(5000)
	sol.timer.start(100, function()
	  sprite:set_direction(1)
		sol.timer.start(10, function()
			sprite:fade_out(10)
			local m = sol.movement.create("straight")
			m:set_speed(300)
			m:set_angle(up)
			m:set_max_distance(96)
			m:set_ignore_obstacles(true)
			m:start(sprite, function()
			enemy:set_position(216, 144, 2)
			 sol.timer.start(500, function()
			  self:spawn_falling_rocks("groundp")
			     sol.timer.start(11000, function()
			         sprite:set_direction(2)
					  sol.timer.start(600, function()
						  sprite:set_xy(0, -96) --96 --240
						  sprite:fade_in(20)
						  local n = sol.movement.create("straight")
						  n:set_speed(500)
						  n:set_angle(down)
						  n:set_max_distance(96)
						  n:set_ignore_obstacles(false)
						  n:start(sprite, function()
							enemy:set_position(216, 144, 0)
							self:shake_screen(self:get_map(), 0, 300)
							-- spam the sound, sounds like a big stomp
							sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
							sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
							sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
							sol.timer.start(100, function()
								sprite:set_direction(1)
								sol.timer.start(200, function()
									sprite:set_direction(0)
									self:walk()
								end)
							end)
						  end)
					  end)
				  end)
			 end)
			end)
		end)
	end)
  end
end
	
function enemy:get_back_up()
	sprite:set_direction(0)
	sprite:set_animation("jumping")
	sprite:set_frame_delay(5000)
	sprite:set_frame(0)
	sol.timer.start(800, function()
	  self:jump("recover")
	  sol.audio.play_music(loop_bgm)
	end)
end
	
function enemy:ground_pound()
  local ground_pnd = 0
  sprite:set_direction(0)
  sprite:set_animation("groundp")
  sol.timer.start(50, function()
    sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
	ground_pnd = ground_pnd + 1
	return ground_pnd <= 20
  end)
  sol.timer.start(250, function()
    self:spawn_falling_rocks("groundp")
  end)
  sol.timer.start(9000, function()
    sprite:set_animation("walking")
    enemy:walk()
  end)
end
	
function sprite:on_frame_changed(animation, frame)
  if self:get_animation() == "walking" and frame == 2 or frame == 6 then
	sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
  end
end	
	
function enemy:on_obstacle_reached(movement)
 if state == "rolling" then
	self:shake_screen(self:get_map(), 0, 10)
	   movement:stop()
	   state = "hit_wall"
	   sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
	   sol.audio.play_sound("ennemies/_boss/king_dodongo/stomp")
	   local n = sol.movement.create("straight")
	   n:set_speed(100)
	   n:set_angle(up)
	   n:set_max_distance(32)
	   n:set_ignore_obstacles(true)
	   n:start(sprite, function()
		   local f = sol.movement.create("straight")
		   f:set_speed(100)
		   f:set_angle(down)
		   f:set_max_distance(32)
		   f:set_ignore_obstacles(false)
		   f:start(sprite, function()
		      sprite:set_animation("jumping")
			  sprite:set_direction(2)
			  sol.timer.start(self, 200, function()
			    sprite:set_direction(1)
				sol.timer.start(self, 200, function()
				  sprite:set_direction(0)
				  sol.timer.start(self, 1000, function()
				    local rand = math.random(1, 2)
					if rand == 1 then
					  -- shoot fire
					  sprite:set_animation("walking")
					  local backward = sol.movement.create("straight")
					  backward:set_speed(20)
					  backward:set_max_distance(16)
					  backward:set_angle(up)
					  backward:start(self, function()
					    enemy:inhale()
					  end)
					else
					sol.timer.start(self, 1000, function()
					  self:jump("obstacle_reached")
					end)
					end
				  end)
				end)
			  end)
			  -- self:set_position(x, y, 0)
		   end)
	   end)
	 else -- walking
	   state = "recover"
	   if not obstacle_reached then
	    sprite:set_animation("walking")
		sprite:set_frame_delay(5000)
		local backward = sol.movement.create("straight")
			  backward:set_speed(20)
			  backward:set_max_distance(16)
			  backward:set_angle(1 * math.pi / 2)
			  backward:start(self)
		sol.timer.start(1000, function()
		    local rand = math.random(1, 2)
			if rand == 1 then
			  sprite:set_animation("walking")
			  enemy:inhale()
			  obstacle_reached = false
			elseif rand == 2 then
			sol.timer.start(1000, function()
			  self:jump("obstacle_reached")
			  obstacle_reached = false
			end)
			end
		  end)
	  obstacle_reached = true
	  end
	 end
	end
	
  function enemy:on_custom_attack_received(attack, sprite)
	  if attack == "sword" and sprite == sprite then
		if can_attack then
		  sol.audio.play_sound("ennemies/_boss/king_dodongo/hit")
		  sprite:set_direction(1)
		  self:remove_life(enemy:get_game():get_ability('sword'))
		  sol.timer.start(250, function()
		  	sprite:set_direction(0)
		  end)
		number_of_hit = number_of_hit + 1
		
		if number_of_hit == math.random(2, 4) and self:get_life() > 5 then
			number_of_hit = 0
			can_attack = false
			sol.timer.start(250, function()
				sprite:set_direction(0)
				self:get_back_up()
			end)
		end
		
		else
		sol.audio.play_sound("sword_tapping")
		end
	  end
		
	  if self:get_life() <= 5 then
	  -- self:start_dying_cutscene() (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((()))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
	  self:set_position(296, 144, 0)
	    self:get_map():get_entity("k_dodongo_dead_body"):set_enabled(true)
		sol.audio.play_music("dungeons/boss/dying", function()
		 sol.audio.play_music("dungeons/boss/beaten")
		 self:get_map():get_entity("heart_container"):set_enabled(true)
		 self:get_map():get_entity("k_dodongo_dead_body"):set_enabled(true)
		end)
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

  if context == "groundp" then
    target_time = 65
	target_rock = 250
  elseif context == "rolling" then
    target_time = 70
	target_rock = 50
  elseif context == "jump" then
    target_time = 80
	target_rock = 40
  end
  
  sol.timer.start(target_time, function()
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

function enemy:shoot_fire()
  local x, y = self:get_position()
  local fire = self:get_map():create_enemy({
    breed = "boss/king_dodongo/fire",
    x = x - 4,
    y = y - 24,
    layer = 0,
    direction = 0,
  })
local fire_mvt = sol.movement.create("straight")
fire_mvt:set_angle(3 * math.pi / 2)
fire_mvt:set_speed(200)
fire_mvt:set_max_distance(64)
fire_mvt:set_smooth(false)
fire_mvt:set_ignore_obstacles(true)
fire_mvt:start(fire)
end

function enemy:shake_screen(map, direction, length)
  local map = self:get_map()
  local speed = 200
  local hx, hy, _ = map:get_hero():get_position()
  local w, h = map:get_size()
  local x, y, dx, dy
  if direction%2 == 0 then x = w/2; y = hy; dx = 2; dy = 0
  else x = hx; y = h/2; dx = 0; dy = 4 end
  map:move_camera(x+dx, y+dy, speed, function() 
	map:move_camera(x-dx, y-dy, speed, function()
	  self:shake_screen(map, direction, length)
	end, 0, length)
  end, 0, length)
end