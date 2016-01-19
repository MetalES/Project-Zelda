local entity = ...
local game = entity:get_game()
local hero = game:get_map():get_entity("hero")

local function random_walk()
  local m = sol.movement.create("random_path")
  m:set_speed(12) --32
  m:start(entity)
  entity:get_sprite():set_animation("walking")
end

function entity:on_created()
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", true)
  self:set_traversable_by("hero", true)
  random_walk()
end

function entity:on_movement_changed(movement)
  local direction = movement:get_direction4()
  entity:get_sprite():set_direction(direction)
end
