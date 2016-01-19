local item = ...
local game = item:get_game()
local sound_when_picked = "common/get_small_item0"

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
  self:set_sound_when_picked(sound_when_picked)
end

function item:on_started()
  item:set_obtainable(game:has_item("bow"))
end

function item:on_obtaining(variant, savegame_variable)
  local amounts = { 1, 5, 10 }
  local amount = amounts[variant]
  game:get_item("bow"):add_amount(amount)

local x, y, layer = self:get_game():get_hero():get_position()
local arrow_sprite = self:get_game():get_map():create_custom_entity({
x = x,
y = y - 8,
layer = layer,
direction = 0,
sprite = "entities/items",
})

    arrow_sprite:get_sprite():set_animation("arrow")
    arrow_sprite:set_direction(variant - 1)

    arrow_sprite:set_can_traverse("crystal", true)
    arrow_sprite:set_can_traverse("crystal_block", true)
    arrow_sprite:set_can_traverse("hero", true)
    arrow_sprite:set_can_traverse("jumper", true)
    arrow_sprite:set_can_traverse("stairs", true)
    arrow_sprite:set_can_traverse("stream", true)
    arrow_sprite:set_can_traverse("switch", true)
    arrow_sprite:set_can_traverse("wall", true)
    arrow_sprite:set_can_traverse("teletransporter", true)
    arrow_sprite:set_can_traverse_ground("deep_water", true)
    arrow_sprite:set_can_traverse_ground("wall", true)
    arrow_sprite:set_can_traverse_ground("shallow_water", true)
    arrow_sprite:set_can_traverse_ground("hole", true)
    arrow_sprite:set_can_traverse_ground("lava", true)
    arrow_sprite:set_can_traverse_ground("prickles", true)
    arrow_sprite:set_can_traverse_ground("low_wall", true) 
    arrow_sprite.apply_cliffs = true

local movement_update = sol.timer.start(10, function()
local lx, ly, ll = self:get_game():get_hero():get_position()
arrow_sprite:set_position(lx, ly - 24, ll)
return true
end)

sol.timer.start(250, function() arrow_sprite:get_sprite():fade_out(2, function() movement_update:stop(); arrow_sprite:remove() end) end)
end