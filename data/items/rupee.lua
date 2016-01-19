local item = ...
local game = item:get_game()

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_sound_when_picked("picked_rupee")
  self:set_brandish_when_picked(false)
end

function item:on_obtaining(variant, savegame_variable)
  local amounts = {1, 5, 20, 50, 100, 300}
  local amount = amounts[variant]
  local x, y, layer = game:get_hero():get_position()

self:get_game():add_money(amount)

local x, y, layer = self:get_game():get_hero():get_position()
local rupee_sprite = self:get_game():get_map():create_custom_entity({
x = x,
y = y - 8,
layer = layer,
direction = 0,
sprite = "entities/items",
})

    rupee_sprite:get_sprite():set_animation("rupee")
    rupee_sprite:set_direction(variant - 1)

    rupee_sprite:set_can_traverse("crystal", true)
    rupee_sprite:set_can_traverse("crystal_block", true)
    rupee_sprite:set_can_traverse("hero", true)
    rupee_sprite:set_can_traverse("jumper", true)
    rupee_sprite:set_can_traverse("stairs", true)
    rupee_sprite:set_can_traverse("stream", true)
    rupee_sprite:set_can_traverse("switch", true)
    rupee_sprite:set_can_traverse("wall", true)
    rupee_sprite:set_can_traverse("teletransporter", true)
    rupee_sprite:set_can_traverse_ground("deep_water", true)
    rupee_sprite:set_can_traverse_ground("wall", true)
    rupee_sprite:set_can_traverse_ground("shallow_water", true)
    rupee_sprite:set_can_traverse_ground("hole", true)
    rupee_sprite:set_can_traverse_ground("lava", true)
    rupee_sprite:set_can_traverse_ground("prickles", true)
    rupee_sprite:set_can_traverse_ground("low_wall", true) 
    rupee_sprite.apply_cliffs = true

local movement_update = sol.timer.start(10, function()
local lx, ly, ll = self:get_game():get_hero():get_position()
rupee_sprite:set_position(lx, ly - 24, ll)
return true
end)

sol.timer.start(250, function() rupee_sprite:get_sprite():fade_out(2, function() movement_update:stop(); rupee_sprite:remove() end) end)
end
