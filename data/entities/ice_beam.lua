-- An ice beam that can unlight torches and freeze water.
local ice_beam = ...
local sprite

local enemies_touched = {}

function ice_beam:on_created()

  ice_beam:set_size(8, 8)
  ice_beam:set_origin(4, 0)
  ice_beam_spr = ice_beam:create_sprite("entities/ice_beam")
  ice_beam_spr:set_direction(0)
  
  function ice_beam_spr:on_animation_finished()
    ice_beam:remove()
  end
end

-- Traversable rules.
ice_beam:set_can_traverse("crystal", true)
ice_beam:set_can_traverse("crystal_block", true)
ice_beam:set_can_traverse("hero", true)
ice_beam:set_can_traverse("jumper", true)
ice_beam:set_can_traverse("stairs", false)
ice_beam:set_can_traverse("stream", true)
ice_beam:set_can_traverse("switch", true)
ice_beam:set_can_traverse("teletransporter", true)
ice_beam:set_can_traverse_ground("deep_water", true)
ice_beam:set_can_traverse_ground("shallow_water", true)
ice_beam:set_can_traverse_ground("hole", true)
ice_beam:set_can_traverse_ground("lava", true)
ice_beam:set_can_traverse_ground("prickles", true)
ice_beam:set_can_traverse_ground("low_wall", true)
ice_beam.apply_cliffs = true

-- Hurt enemies.
ice_beam:add_collision_test("sprite", function(ice_beam, entity)

  if entity:get_type() == "enemy" then
    local enemy = entity
    if enemies_touched[enemy] then
      -- If protected we don't want to play the sound repeatedly.
      return
    end
    enemies_touched[enemy] = true
    local reaction = enemy:get_ice_reaction(enemy_sprite)
    enemy:receive_attack_consequence("ice", reaction)
    ice_beam:remove()
  end
end)

-- Create an ice square at the specified place if there is deep water.
local function check_square(x, y)

  local map = ice_beam:get_map()
  local _, _, layer = ice_beam:get_position()

  -- Top-left corner of the candidate 16x16 square.
  x = math.floor(x / 16) * 16
  y = math.floor(y / 16) * 16

  -- Check that the four corners of the 16x16 square are on deep water
  if map:get_ground(      x,      y, layer) ~= "deep_water" or
      map:get_ground(x + 15,      y, layer) ~= "deep_water" or
      map:get_ground(     x, y + 15, layer) ~= "deep_water" or
      map:get_ground(x + 15, y + 15, layer) ~= "deep_water" then
    return
  end

  local ice_path = map:create_custom_entity({
    x = x,
    y = y,
    layer = layer,
    width = 16, 
    height = 16,
    direction = 0,
    ground = "ice",
  })
  ice_path:set_origin(0, 0)
  ice_path:set_modified_ground("ice")
  ice_path:create_sprite("entities/ice")
end

-- Create ice on two squares around the specified place if there is deep water.
local function check_two_squares(x, y)

  local movement = ice_beam:get_movement()
  if movement == nil then
    return
  end
  local direction4 = movement:get_direction4()
  local horizontal = (direction4 % 2) == 0
  if horizontal then
    check_square(x, y - 8)
    check_square(x, y + 8)
  else
    check_square(x - 8, y)
    check_square(x + 8, y)
  end
end

function ice_beam:on_obstacle_reached()
sol.timer.start(ice_beam_spr, 350, function() ice_beam:remove()end)
end