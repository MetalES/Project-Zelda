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
-- when he is warped, he will land 8 pixel away from the other room's warp
entity:add_collision_test("origin", function()
if entity:overlaps(entity:get_game():get_hero()) then entity:on_interaction() end
end)


function entity:on_interaction()
local hero = entity:get_game():get_hero()
local warp_dst = "teleporter_" ..self:get_name()
local delay

sol.audio.play_sound("/objects/warp/warp_pad_teleport_out")
-- todo : animate this
hero:freeze()

hero:teleport(self:get_name(), warp_dst, "fade")
end