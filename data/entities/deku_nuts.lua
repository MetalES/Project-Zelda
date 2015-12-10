-- Deku Nuts
local deku = ...
local sprite

local enemies_touched = {}

function deku:on_created()
  deku:set_size(8, 8)
  deku:set_origin(4, 0)
  deku_spr = deku:create_sprite("entities/misc/item/deku/nuts")
  deku_spr:set_direction(0)
  
local deku_mvt = sol.movement.create("straight")
deku_mvt:set_angle(self:get_game():get_hero():get_direction() * math.pi / 2)
deku_mvt:set_speed(300)
deku_mvt:set_max_distance(54)
deku_mvt:set_smooth(false)
deku_mvt:start(deku, function() self:explode() end)
end

-- Traversable rules.
deku:set_can_traverse("crystal", false)
deku:set_can_traverse("crystal_block", false)
deku:set_can_traverse("hero", true)
deku:set_can_traverse("jumper", true)
deku:set_can_traverse("stairs", false)
deku:set_can_traverse("stream", true)
deku:set_can_traverse("switch", true)
deku:set_can_traverse("teletransporter", true)
deku:set_can_traverse_ground("deep_water", true)
deku:set_can_traverse_ground("shallow_water", true)
deku:set_can_traverse_ground("hole", true)
deku:set_can_traverse_ground("lava", true)
deku:set_can_traverse_ground("prickles", true)
deku:set_can_traverse_ground("low_wall", true)
deku.apply_cliffs = true

-- Hurt enemies.
deku:add_collision_test("sprite", function(deku, entity)

  if entity:get_type() == "enemy" then
    local enemy = entity
    if enemies_touched[enemy] then
      -- If protected we don't want to play the sound repeatedly.
      return
    end
    enemies_touched[enemy] = true
    local reaction = enemy:get_deku_reaction(enemy_sprite)
    enemy:receive_attack_consequence("deku", reaction)
	deku_spr:remove()
  end
end)

function deku:explode()
deku_spr = deku:create_sprite("entities/misc/item/deku/explosion")
sol.audio.play_sound("items/deku_nuts/hit_ground")

function deku_spr:on_animation_finished()
deku:remove()
end
end

function deku:on_obstacle_reached()
self:explode()
end