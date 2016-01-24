local item = ...
local sound_when_picked = "common/get_small_item0"

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
  self:set_sound_when_picked(sound_when_picked)
end

function item:on_obtaining(variant, savegame_variable)
  self:get_game():add_life(4)

  local x, y, layer = self:get_game():get_hero():get_position()
local heart_sprite = self:get_game():get_map():create_custom_entity({
x = x,
y = y - 8,
layer = layer,
direction = 0,
sprite = "entities/items",
})

    heart_sprite:get_sprite():set_animation("heart")
    heart_sprite:get_sprite():set_frame_delay(400000)
    heart_sprite:get_sprite():set_frame(24)

    heart_sprite:set_can_traverse("crystal", true)
    heart_sprite:set_can_traverse("crystal_block", true)
    heart_sprite:set_can_traverse("hero", true)
    heart_sprite:set_can_traverse("jumper", true)
    heart_sprite:set_can_traverse("stairs", true)
    heart_sprite:set_can_traverse("stream", true)
    heart_sprite:set_can_traverse("switch", true)
    heart_sprite:set_can_traverse("wall", true)
    heart_sprite:set_can_traverse("teletransporter", true)
    heart_sprite:set_can_traverse_ground("deep_water", true)
    heart_sprite:set_can_traverse_ground("wall", true)
    heart_sprite:set_can_traverse_ground("shallow_water", true)
    heart_sprite:set_can_traverse_ground("hole", true)
    heart_sprite:set_can_traverse_ground("lava", true)
    heart_sprite:set_can_traverse_ground("prickles", true)
    heart_sprite:set_can_traverse_ground("low_wall", true) 
    heart_sprite.apply_cliffs = true

local movement_update = sol.timer.start(10, function()
local lx, ly, ll = self:get_game():get_hero():get_position()
heart_sprite:set_position(lx, ly - 24, ll)
return true
end)

sol.timer.start(250, function() heart_sprite:get_sprite():fade_out(2, function() movement_update:stop(); heart_sprite:remove() end) end)
end

function item:on_pickable_created(pickable)

  if self:get_game():get_value("hero_mode") then pickable:remove() end

  if pickable:get_falling_height() ~= 0 then
    -- Replace the default falling movement by a special one.
    local trajectory = {
      { 0,  0},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0, -2},
      { 0,  0},
      { 0,  0},
      { 1,  1},
      { 1,  1},
      { 1,  0},
      { 1,  1},
      { 1,  1},
      { 0,  0},
      {-1,  0},
      {-1,  1},
      {-1,  0},
      {-1,  1},
      {-1,  0},
      {-1,  1},
      { 0,  1},
      { 1,  1},
      { 1,  1},
      {-1,  0}
    }
    local m = sol.movement.create("pixel")
    m:set_trajectory(trajectory)
    m:set_delay(80)
    m:set_loop(false)
    m:set_ignore_obstacles(true)
    m:start(pickable, function() pickable:get_sprite():set_frame_delay(200) end)
  end
end
