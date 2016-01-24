local item = ...

-- This script defines the behavior of pickable fairies present on the map.

function item:on_created()
  self:set_shadow(nil)
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
end

function item:on_pickable_created(pickable)

  if self:get_game():get_value("hero_mode") then pickable:remove() end

   -- Create a movement that goes into random directions,
   -- with a speed of 28 pixels per second.
  local movement = sol.movement.create("random")
  movement:set_speed(28)
  movement:set_ignore_obstacles(true)
  movement:set_max_distance(40)  -- Don't go too far.

  -- Put the fairy on the highest layer to show it above all walls.
  local x, y = pickable:get_position()
  
  pickable:set_position(x, y)
  pickable:set_layer_independent_collisions(true)  -- But detect collisions with lower layers anyway

  -- When the direction of the movement changes,
  -- update the direction of the fairy's sprite
  function pickable:on_movement_changed(movement)

    if pickable:get_followed_entity() == nil then

      local fairy_sprite = pickable:get_sprite()
      local angle = movement:get_angle()  -- Retrieve the current movement's direction.
      if angle >= math.pi / 2 and angle < 3 * math.pi / 2 then
        fairy_sprite:set_direction(1)  -- Look to the left.
      else
        fairy_sprite:set_direction(0)  -- Look to the right.
      end
    end
  end

  movement:start(pickable)
end

function item:on_obtaining(variant, savegame_variable)

sol.audio.play_sound("objects/fairy/interact")
sol.audio.play_sound("heart")
local x, y, layer = self:get_game():get_hero():get_position()
local fairy_c_sprite = self:get_game():get_map():create_custom_entity({
x = x,
y = y,
layer = layer + 1,
direction = 0,
sprite = "entities/items",
})

    fairy_c_sprite:set_can_traverse("crystal", true)
    fairy_c_sprite:set_can_traverse("crystal_block", true)
    fairy_c_sprite:set_can_traverse("hero", true)
    fairy_c_sprite:set_can_traverse("jumper", true)
    fairy_c_sprite:set_can_traverse("stairs", true)
    fairy_c_sprite:set_can_traverse("stream", true)
    fairy_c_sprite:set_can_traverse("switch", true)
    fairy_c_sprite:set_can_traverse("wall", true)
    fairy_c_sprite:set_can_traverse("teletransporter", true)
    fairy_c_sprite:set_can_traverse_ground("deep_water", true)
    fairy_c_sprite:set_can_traverse_ground("wall", true)
    fairy_c_sprite:set_can_traverse_ground("shallow_water", true)
    fairy_c_sprite:set_can_traverse_ground("hole", true)
    fairy_c_sprite:set_can_traverse_ground("lava", true)
    fairy_c_sprite:set_can_traverse_ground("prickles", true)
    fairy_c_sprite:set_can_traverse_ground("low_wall", true) 
    fairy_c_sprite.apply_cliffs = true
	
fairy_c_sprite:get_sprite():set_animation("fairy")

local movement = sol.movement.create("circle")
movement:set_center(self:get_game():get_hero())
movement:set_radius(16)
movement:set_angle_speed(500)
movement:set_max_rotations(7)
movement:start(fairy_c_sprite)

self:get_game():add_life(10 * 4)

sol.timer.start(4250, function() fairy_c_sprite:get_sprite():fade_out(10, function() fairy_c_sprite:remove(); movement:stop() end) end)
end