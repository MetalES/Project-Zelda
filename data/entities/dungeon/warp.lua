local entity = ...
local map = entity:get_map()

-- Dungeon Warp, location depends on event name.

function entity:on_created()
self:set_size(16,16)
self:set_traversable_by("hero", true)
local tx, ty, tl = self:get_position()
local effect = map:create_custom_entity({
      x = tx,
      y = ty,
      layer = tl,
      direction = entity:get_direction(),
      sprite = "entities/dungeon/warp_effect",
    })
end

-- we need to test if the hero is on the teleporter, if yes, start interaction automatically, no input needed.
entity:add_collision_test("origin", function()
entity:on_interaction()
end)

function entity:on_interaction()
local hero = sol.main.game:get_map():get_hero()
hero:teleport(self:get_name(), "_same", "fade")
end
