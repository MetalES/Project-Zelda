local enemy = ...

-- A bouncing triple fireball, usually shot by another enemy.

local speed = 192
local bounces = 0
local used_sword = false
local sprite2 = nil
local sprite3 = nil
local snd = 0

function enemy:on_created()

  self:set_life(1)
  self:set_damage(8)
  self:create_sprite("enemies/phantom_ganon/energy")
  self:set_size(16, 16)
  self:set_origin(8, 8)
  self:set_obstacle_behavior("flying")
  self:set_invincible()
  self:set_attack_consequence("sword", "custom")
  self:set_enabled(true)

  -- Two smaller fireballs just for the displaying.
  -- sprite2 = sol.sprite.create("enemies/red_fireball_triple")
  -- sprite2:set_animation("small")
  -- sprite3 = sol.sprite.create("enemies/red_fireball_triple")
  -- sprite3:set_animation("tiny")
end

function enemy:on_restarted()

  local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
  local angle = self:get_angle(hero_x, hero_y - 5)
  local m = sol.movement.create("straight")
  m:set_speed(speed)
  m:set_angle(angle)
  m:set_smooth(false)
  m:start(self)
end

function enemy:on_obstacle_reached()

    -- self:remove()
end

function enemy:on_custom_attack_received(attack, sprite)

  if attack == "sword" then
    local hero_x, hero_y = self:get_map():get_entity("hero"):get_position()
	local target_x, target_y
    local angle = self:get_angle(hero_x, hero_y - 5) + math.pi
    local m = sol.movement.create("straight")
    m:set_speed(speed)
    m:set_angle(angle)
    m:set_smooth(false)
    m:start(self)
	sol.audio.play_music("dungeons/miniboss/phantom_ganon/projectile_back"..snd, function()
	   sol.audio.play_music("dungeons/miniboss/phantom_ganon/projectile_back"..snd.."_loop")
	end)
    -- sol.audio.play_sound("boss_fireball")
    used_sword = true
  end
end

function enemy:on_collision_enemy(other_enemy, other_sprite, my_sprite)
  if used_sword then
    if other_enemy.receive_bounced_fireball ~= nil then
      other_enemy:receive_bounced_fireball(self)
    end
  end
end

function enemy:on_pre_draw()

  -- local m = self:get_movement()
  -- local angle = m:get_angle()
  -- local x, y = self:get_position()

  -- local x2 = x - math.cos(angle) * 12
  -- local y2 = y + math.sin(angle) * 12

  -- local x3 = x - math.cos(angle) * 24
  -- local y3 = y + math.sin(angle) * 24

  -- self:get_map():draw_sprite(sprite2, x2, y2)
  -- self:get_map():draw_sprite(sprite3, x3, y3)
end

-- Method called by other enemies.
function enemy:bounce()

  local m = self:get_movement()
  local angle = m:get_angle()
  angle = angle + math.pi

  m:set_angle(angle)
  m:set_speed(speed)
  used_sword = false
end

