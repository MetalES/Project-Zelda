local item = ...
local game = item:get_game()

-- fire rod - Four Swords Adventure style - Work in Progress - 95%

function item:on_created()
  self:set_savegame_variable("i1853")
  self:set_assignable(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("/common/big_item")
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    local sword = game:get_ability("sword")
    game:set_ability("sword", 0)
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
    local kb_action_key = game:get_command_keyboard_binding("action")
    game:set_command_keyboard_binding("action", nil)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
    game:set_value("item_saved_action", kb_action_key)
    game:set_pause_allowed(false)
end

function item:on_using()
local map = game:get_map()
local hero = game:get_hero()

--freeze_hero, play animation of arming the rod, and then unfreeze
--debug test pass. It works perfectly.

hero:unfreeze()

sol.timer.start(300,function()
store_equipment()
magic_timer = sol.timer.start(300, function()
if fire_timer ~= nil then
item:get_game():remove_magic(1)
end
return true
end)

fire_timer = sol.timer.start(50, function()
if sol.input.is_key_pressed("x") then -- add joypad and get the item slot.
if self:get_game():get_magic() > 0 then self:shoot_fire() end
else
fire_timer:stop()
magic_timer:stop()

hero:set_walking_speed(88)
hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
game:set_ability("tunic", game:get_value("item_saved_tunic"))
game:set_ability("sword", game:get_value("item_saved_sword"))
game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_pause_allowed(true)

hero:unfreeze()

self:set_finished()
end
  return true
end)
end)
end

-- Creates some fire on the map.
function item:shoot_fire()
  local hero = self:get_map():get_entity("hero")
  local direction = hero:get_direction()
  local dx, dy
  if direction == 0 then
    dx, dy = 8, -4
  elseif direction == 1 then
    dx, dy = 0, -14
  elseif direction == 2 then
    dx, dy = -12, -4
  else
    dx, dy = 0, 6
  end

  local x, y, layer = hero:get_position()
  local fire = self:get_map():create_fire{
    x = x + dx,
    y = y + dy,
    layer = layer
    --sprite = "entities/fire_burns" don't work...
  }

local fire_mvt = sol.movement.create("straight")
fire_mvt:set_angle(hero:get_direction() * math.pi / 2)
fire_mvt:set_speed(175) --set speed faster then Link (for movement logics)
fire_mvt:set_max_distance(32)
fire_mvt:set_smooth(false)
fire_mvt:start(fire)
end
