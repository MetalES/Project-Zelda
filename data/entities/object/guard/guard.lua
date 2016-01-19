local entity = ...
local ai_system

function entity:on_created()
  self:set_size(16,16)
  self:set_traversable_by("hero", false)
  self:set_traversable_by("custom_entity", false)
  self:set_can_traverse("hero", false)
  self:set_can_traverse("custom_entity", false)
  self:set_drawn_in_y_order(true)
  
  local x, y, z = self:get_position()
  local direction = self:get_direction()
  ai_system = self:get_game():get_map():create_custom_entity({
	model = "object/guard/ai_system",
	x = x,
	y = y,
	layer = z,
	direction = direction,
  })
  ai_system:set_direction(self:get_direction())
end

entity:add_collision_test("touching", function(sprite, other)
  if other:get_type() == "hero" then
    entity:get_game().hero_caught_by_guard = true
  end
end)

function entity:on_detection_guard_interaction()
  self:go_hero()
  sol.timer.start(200, function()
	  self:get_game():start_dialog("gameplay.objects.guards.hero_spotted", function()
		entity:get_game().hero_caught_by_guard = false
		entity:get_game():get_hero():teleport("dungeons/d_water_ice/2/boss_preroom_rel")
	  end)
  end)
end

function entity:go_hero()
  local target = sol.movement.create("target")
  target:set_target(self:get_game():get_hero():get_position())
  target:set_speed(98)
  target:set_ignore_obstacles(false)
  target:start(self)
end

function entity:on_position_changed()
  local x, y, z = self:get_position()
  ai_system:set_position(x, y, z)
end

function entity:on_movement_changed(movement)
  local direction = movement:get_direction4()
  ai_system:set_direction(direction)
  self:set_direction(direction)
end

function entity:on_update()
  if self:get_game().hero_caught_by_guard then
    self:on_detection_guard_interaction()
  end
end