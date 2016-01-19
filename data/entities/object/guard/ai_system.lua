local entity = ...

-- Ai system

function entity:on_created()
  self:create_sprite("entities/objects/avoid_guard/detection")
  self:get_game().hero_caught_by_guard = false
end

entity:add_collision_test("sprite", function(entity, other)
  if other:get_type() == "hero" then
    if not entity:get_game().hero_caught_by_guard then
	  entity:get_game().hero_caught_by_guard = true	 
	end
  end
end)