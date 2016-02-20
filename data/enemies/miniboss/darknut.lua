local enemy = ...

local body_sprite
local sword_sprite
local shield_sprite
local going_hero

function enemy:on_created()

  body_sprite = enemy:create_sprite("enemies/darknut/"..self:get_name().."/body")
  sword_sprite = enemy:create_sprite("enemies/darknut/"..self:get_sprite().."/sword")
  shield_sprite = enemy:create_sprite("enemies/darknut/"..self:get_sprite().."/shield")
  enemy:set_life(2)
  enemy:set_damage(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Make the sword sprite ignore all attacks.
  enemy:set_invincible_sprite(sword_sprite)
  enemy:set_invincible_sprite(shield_sprite)
  -- Except the sword.
  enemy:set_attack_consequence_sprite(sword_sprite, "sword", "custom")
  
  going_hero = false
end

function enemy:on_restarted()

  enemy:go_random()
  enemy:check_hero()
end

function enemy:check_hero()

  local hero = enemy:get_map():get_entity("hero")
  local distance_to_hero = enemy:get_distance(hero)

  local _, _, layer = enemy:get_position()
  local _, _, hero_layer = hero:get_position()
  local near_hero = layer == hero_layer
    and enemy:get_distance(hero) < 100
    
  if near_hero and not going_hero then
    sol.audio.play_sound("hero_seen")
    enemy:go_hero()
  elseif not near_hero and going_hero then
    enemy:go_random()
  end

  -- Call check_hero repeatedly.
  sol.timer.start(enemy, 500, function()
    enemy:check_hero()
  end)
end

function enemy:go_random()

  going_hero = false
  local movement = sol.movement.create("random_path")
  movement:set_speed(32)
  movement:start(enemy)
end

function enemy:go_hero()

  going_hero = true

  local movement = sol.movement.create("target")
  movement:set_speed(64)
  movement:start(enemy)
end

function enemy:on_movement_changed(movement)

  local direction4 = movement:get_direction4()
  body_sprite:set_direction(direction4)
  sword_sprite:set_direction(direction4)
end

function enemy:on_custom_attack_received(attack, sprite)

  if attack == "sword" and sprite == sword_sprite then
    sol.audio.play_sound("sword_tapping")

    local hero = enemy:get_map():get_entity("hero")
    local angle = hero:get_angle(enemy)
    local movement = sol.movement.create("straight")
    movement:set_speed(128)
    movement:set_angle(angle)
    movement:set_max_distance(26)
    movement:set_smooth(true)
    movement:start(enemy, function()
      enemy:restart()
    end)
  end
end
