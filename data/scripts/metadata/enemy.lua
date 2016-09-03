local enemy_meta = sol.main.get_metatable("enemy")

  -- Enemies: redefine the damage of the hero's sword. (The default damages are less important.)
function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)
  -- Here, self is the enemy.
  local game = self:get_game()
  local hero_mode = game:get_value("hero_mode")
  local sword = game:get_ability("sword")
  local damage_factors = { 1, 2, 4, 8 }  -- Damage factor of each sword.
  local damage_factor = damage_factors[sword]
	
  if hero:get_state() == "sword spin attack" then
	if hero_mode then
	  damage_factor = damage_factor
	else
	  damage_factor = damage_factor * 2  -- The spin attack is twice as powerful, but costs more stamina.
	end
  end
	
  if hero:get_state() == "sword swinging" then
	if hero_mode then
	  damage_factor =  damage_factor / 1.5 -- damage are ridiculous
	else
	  damage_factor = damage_factor  -- Dafault damage value
	end
  end
		
  local reaction = self:get_attack_consequence_sprite(enemy_sprite, "sword")
  self:remove_life(reaction * damage_factor)
end

function enemy_meta:spawn_heart_container(callback)
  local m = self:get_map()
  local hero = m:get_hero()
  local game = m:get_game()
  local hx, hy, hz = hero:get_position()
  local x, y, z = self:get_position()
  local dungeon = game:get_dungeon_index()
  local tx, ty, tl = m:get_entity("heart_container_place"):get_position()
  
  local function shift_sprite(sprite, duration)
    local max_height = math.floor(-duration / 5)

    local function f(t)
      return math.floor(4 * max_height * (t / duration - (t / duration) ^ 2))
    end
  
    local t = 0
    sol.timer.start(self, 10, function()
      sprite:get_sprite():set_xy(0, f(t))
      t = t + 1
      if t > duration then return false 
        else return true 
      end
    end)
  end
  
  local heart_container = m:create_pickable({
    name = "heart_container",
	x = x,
	y = y,
	layer = hz + 2,
    treasure_name = "heart_container",
	treasure_savegame_variable = "dungeon_".. dungeon .. "_heart_container_picked"
  })
  
  local movement = sol.movement.create("target")
  movement:set_target(tx, ty)
  movement:set_speed(100)
  movement:start(heart_container, function()
    sol.timer.start(100, function()
    -- create a bounce effect
	local j = sol.movement.create("straight")
	j:set_angle(math.pi / 2)
	j:set_speed(50)
	j:set_max_distance(6)
	j:start(heart_container, function()
      -- create a bounce effect 2
	  j:set_angle(3 * math.pi / 2)
	  j:set_speed(40)
	  j:set_max_distance(6)
	  j:start(heart_container, function()
        -- create a bounce effect
	    j:set_angle(math.pi / 2)
	    j:set_speed(30)
	    j:set_max_distance(4)
	    j:start(heart_container, function()
          -- create a bounce effect
	      j:set_angle(3 * math.pi / 2)
	      j:set_speed(20)
	      j:set_max_distance(4)
	      j:start(heart_container, function()
		    local camera = m:get_camera()
			sol.timer.start(2000, function()
			  camera:start_manual()
			  local m = sol.movement.create("target")
			  m:set_target(camera:get_position_to_track(hx, hy))
			  m:set_speed(75) 
			  m:start(camera, function() callback() end)
			  game:set_hud_enabled(true)
			  game:set_clock_enabled(true)
			end)
		  end) 
		end) 
	  end)
	end)
	end)
  end)
  
  shift_sprite(heart_container, 100)  
end

  -- Helper function to inflict an explicit reaction from a scripted weapon.
function enemy_meta:receive_attack_consequence(attack, reaction)
  if type(reaction) == "number" then
    self:hurt(reaction)
  elseif reaction == "immobilized" then
    self:immobilize()
  elseif reaction == "protected" then
    sol.audio.play_sound("sword_tapping")
  elseif reaction == "custom" then
    if self.on_custom_attack_received ~= nil then
      self:on_custom_attack_received(attack)
    end
  end
end