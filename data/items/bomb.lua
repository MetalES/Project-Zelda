local item = ...
local sound_when_picked = "common/get_small_item0"

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
  self:set_sound_when_picked(sound_when_picked)
end

function item:on_started()
  -- Disable pickable bombs if the player has no bomb bag.
  -- We cannot do this from on_created() because we don't know if the bomb bag
  -- is already created there.
  local bomb_bag = self:get_game():get_item("bomb_bag")
  self:set_obtainable(bomb_bag:has_variant())
end

function item:on_obtaining(variant, savegame_variable)
  -- Obtaining bombs increases the bombs counter.
  local amounts = {1, 3, 8}
  local amount = amounts[variant]
  if amount == nil then
    error("Invalid variant '" .. variant .. "' for item 'bomb'")
  end
  self:get_game():get_item("bomb_counter"):add_amount(amount)

local x, y, layer = self:get_game():get_hero():get_position()
local bomb_sprite = self:get_game():get_map():create_custom_entity({
x = x,
y = y - 8,
layer = layer,
direction = 0,
sprite = "entities/items",
})

    bomb_sprite:get_sprite():set_animation("bomb")
    bomb_sprite:set_direction(variant - 1)

    bomb_sprite:set_can_traverse("crystal", true)
    bomb_sprite:set_can_traverse("crystal_block", true)
    bomb_sprite:set_can_traverse("hero", true)
    bomb_sprite:set_can_traverse("jumper", true)
    bomb_sprite:set_can_traverse("stairs", true)
    bomb_sprite:set_can_traverse("stream", true)
    bomb_sprite:set_can_traverse("switch", true)
    bomb_sprite:set_can_traverse("wall", true)
    bomb_sprite:set_can_traverse("teletransporter", true)
    bomb_sprite:set_can_traverse_ground("deep_water", true)
    bomb_sprite:set_can_traverse_ground("wall", true)
    bomb_sprite:set_can_traverse_ground("shallow_water", true)
    bomb_sprite:set_can_traverse_ground("hole", true)
    bomb_sprite:set_can_traverse_ground("lava", true)
    bomb_sprite:set_can_traverse_ground("prickles", true)
    bomb_sprite:set_can_traverse_ground("low_wall", true) 
    bomb_sprite.apply_cliffs = true

local movement_update = sol.timer.start(10, function()
local lx, ly, ll = self:get_game():get_hero():get_position()
bomb_sprite:set_position(lx, ly - 24, ll)
return true
end)

sol.timer.start(250, function() bomb_sprite:get_sprite():fade_out(2, function() movement_update:stop(); bomb_sprite:remove() end) end)
end