local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- just like dungeon warp, except it compute a value for chamber of sage's cutscene, else Link is warped outside

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
entity:add_collision_test("origin", function(boss_warp, other)
if other:get_type() == "hero" then entity:on_interaction() end
end)

function entity:on_interaction()
local game = entity:get_game()
local map =  game:get_map()
local hero = game:get_hero()
local hero_was_visible
local hero_dummy_sprite
local hero_dummy_x, hero_dummy_y
local fade_sprite = sol.sprite.create("hud/gameover_fade")
local warp_dst = "cutscene_" ..self:get_name()

--fade_sprite = sol.sprite.create("hud/gameover_fade")
hero_was_visible = hero:is_visible()
--hero:set_visible(false)
hero:freeze() -- we don't see the hero, so disable all of it's input
game:set_pause_allowed(false) -- disable pause too, it's a cutscene


--[[
if game:get_value(warp_dst) ~= true then
hero:teleport("/cutscene/sage", warp_dst, "fade") --warp to sage room, cutscene depend on destination.
else
hero:teleport(self:get_name(), warp_dst, "fade") --warp to the entrance of the dungeon.
end--]]

end