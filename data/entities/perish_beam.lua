local perish_beam = ...
local game = perish_beam:get_game()
local map = perish_beam:get_map()
local hero = map:get_hero()
local direction = hero:get_direction()
local default_sprite
local enemies_touched = {}
local entity_reached
local entity_reached_dxy
local flying
local cur_num_rays = 0

local function initialize_meta()
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_attack_p_beam ~= nil then
    return
  end

  enemy_meta.attack_p_beam = 1
  enemy_meta.attack_p_beam_default_sprite = {}
  
  function enemy_meta:get_attack_p_beam(default_sprite)
    if default_sprite ~= nil and self.attack_p_beam_default_sprite[default_sprite] ~= nil then
      return self.attack_p_beam_default_sprite[default_sprite]
    end
    return self.attack_p_beam
  end

  function enemy_meta:set_attack_p_beam(reaction, default_sprite)
    self.attack_p_beam = reaction
  end

  function enemy_meta:set_attack_p_beam_default_sprite(default_sprite, reaction)
    self.attack_p_beam_default_sprite[default_sprite] = reaction
  end

  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_attack_p_beam("ignored")
  end
  local previous_set_invincible_default_sprite = enemy_meta.set_invincible_default_sprite
  function enemy_meta:set_invincible_default_sprite(default_sprite)
    previous_set_invincible_default_sprite(self, default_sprite)
    self:set_attack_p_beam_default_sprite(default_sprite, "ignored")
  end
end
initialize_meta()

function perish_beam:on_created()
  local direction = perish_beam:get_direction()
  local horizontal = direction % 2 == 0
  
  if horizontal then
    perish_beam:set_size(16, 8)
    perish_beam:set_origin(8, 4)
  else
    perish_beam:set_size(8, 16)
    perish_beam:set_origin(4, 8)
  end

  perish_beam:set_can_traverse_ground("hole", true)  -- For cases of shooting perish_beam near a hole, so it's not destroyed right away.
  perish_beam:set_optimization_distance(0)  -- Make the perish_beam continue outside the screen until the max distance.
end

-- Traversable rules.
perish_beam:set_can_traverse("crystal", true)
perish_beam:set_can_traverse("crystal_block", true)
perish_beam:set_can_traverse("hero", true)
perish_beam:set_can_traverse("jumper", true)
perish_beam:set_can_traverse("stairs", false)
perish_beam:set_can_traverse("stream", true)
perish_beam:set_can_traverse("switch", true)
perish_beam:set_can_traverse("teletransporter", true)
perish_beam:set_can_traverse_ground("deep_water", true)
perish_beam:set_can_traverse_ground("shallow_water", true)
perish_beam:set_can_traverse_ground("hole", true)
perish_beam:set_can_traverse_ground("lava", true)
perish_beam:set_can_traverse_ground("prickles", true)
perish_beam:set_can_traverse_ground("low_wall", true)
perish_beam.apply_cliffs = true

-- Triggers the animation and sound of the perish_beam reaching something
-- and removes the perish_beam after some delay.
local function halt()
  flying = false
  default_sprite:set_animation("explosion")
  default_sprite:set_direction(0)
  perish_beam:stop_movement()

  -- Remove the perish_beam after a delay.
    function default_sprite:on_animation_finished()
	  cur_num_rays = 0
	  perish_beam:remove()
    end
end

-- Hurt ennemies
perish_beam:add_collision_test("sprite", function(perish, entity)

  if entity:get_type() == "enemy" then
    local enemy = entity
    if enemies_touched[enemy] then
      -- If protected we don't want to play the sound repeatedly.
      return
    end
    enemies_touched[enemy] = true
    local reaction = enemy:get_attack_p_beam(enemy_default_sprite)
    enemy:receive_attack_consequence("p_beam", reaction)
    halt()
  end
  
end)

-- Activate crystals and solid switches.
perish_beam:add_collision_test("overlapping", function(perish_beam, entity)
  local entity_type = entity:get_type()
  if entity_type == "crystal" then
    -- Activate crystals.
    if flying then
      sol.audio.play_sound("switch")
      map:change_crystal_state()
      halt()
    end
  elseif entity_type == "switch" then
    -- Activate solid switches.
    local switch = entity
    local default_sprite = switch:get_default_sprite()
    if flying and default_sprite ~= nil and
         (default_sprite:get_animation_set() == "entities/switch_crystal" or
         default_sprite:get_animation_set() == "entities/switch_eye_down" or
         default_sprite:get_animation_set() == "entities/switch_eye_left" or
         default_sprite:get_animation_set() == "entities/switch_eye_right" or
         default_sprite:get_animation_set() == "entities/switch_eye_up" or
         default_sprite:get_animation_set() == "entities/switch_eye_invisible") then
      if not switch:is_activated() then
        sol.audio.play_sound("switch")
        switch:set_activated(true)
        if switch:on_activated() ~= nil then switch:on_activated() end
      end
      halt()
    end
  end
end)

function perish_beam:go()
  default_sprite = perish_beam:create_sprite("effects/hero/perish_beam")
  default_sprite:set_direction(direction)
  
  sol.audio.play_sound("characters/link/effect/perish_beam")
if cur_num_rays < 1 then
  local movement = sol.movement.create("straight")
  local angle = direction * math.pi / 2
  movement:set_speed(500) -- 192
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:set_max_distance(1000) --1500
  movement:start(perish_beam, function() perish_beam:remove() end)
  flying = true
end
  cur_num_rays = 1
end

function perish_beam:on_map_changed()
cur_num_rays = 0
print(cur_num_rays)
end

function perish_beam:on_obstacle_reached()
  halt()
end