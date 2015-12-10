local entity = ...
local game = entity:get_game()
local hero = entity:get_map():get_entity("hero")

-- Hud notification
entity:add_collision_test("touching", function(boss_door, other)
if other:get_type() == "hero" then 
if game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss_door_open") ~= true and game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss_key") ~= true and hero:get_direction() == entity:get_direction() then
game:set_custom_command_effect("action", "look")
elseif game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss_door_open") == true and hero:get_direction() == entity:get_direction() then
game:set_custom_command_effect("action", "open")
elseif game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss_door_open") ~= true and game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss_key") == true and hero:get_direction() == entity:get_direction() then
game:set_custom_command_effect("action", "open")
else game:set_custom_command_effect("action", nil)
end
end
end)

-- Boss door

function entity:on_created()
  self:set_size(32, 16)
  self:set_origin(16,20)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
  self:set_traversable_by("hookshot", false)
  self:set_traversable_by("arrow", false)
  self:set_can_traverse("arrow", false)
  self:set_traversable_by("destructible", false)
local dungeon = game:get_dungeon_index()
if game:get_value("dungeon_" .. dungeon .. "_boss_door_open") == true then 
sol.main.game:get_map():get_entity("boss_door_chain"):remove()
end
end

function entity:on_interaction()

local hero = self:get_map():get_entity("hero")
local x,y = self:get_position()
local direction = hero:get_direction()
local dungeon = game:get_dungeon_index()
local delay

  if not show_bars then game:show_bars(); sol.audio.play_sound("common/bars_dungeon")end

if game:get_value("dungeon_" .. dungeon .. "_boss_key") == true then

hero:freeze()
game:set_pause_allowed(false)
hero:set_position(x, y+12)
game:set_hud_enabled(false)

if game:get_value("dungeon_" .. dungeon .. "_boss_door_open") ~= true then
sol.main.game:get_map():get_entity("boss_door_chain"):get_sprite():set_animation("unlocking")
sol.audio.play_sound("/common/boss_door_unlock")
delay = 750
else 
delay = 0
end


sol.timer.start(delay,function()
if game:get_value("dungeon_" .. dungeon .. "_boss_door_open") ~= true then sol.main.game:get_map():get_entity("boss_door_chain"):remove() end
sol.audio.play_sound("/common/door/stone_open")

  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(50)
  m:set_angle(self:get_direction() * math.pi / 2)
  m:set_max_distance(32)
  m:start(self)

self:set_can_traverse("hero", true)
self:set_traversable_by("hero", true)
end)

sol.timer.start((delay + 850),function()

  local m = sol.movement.create("straight")
  m:set_speed(50)
  m:set_angle(hero:get_direction() * math.pi / 2)
  m:set_max_distance(48)
  m:start(hero)
  
if game:get_value("i1820") >= 1 then hero:set_animation("walking_with_shield") else hero:set_animation("walking") end
end)

sol.timer.start((delay + 1900),function()
sol.audio.play_sound("/common/door/stone_close")
self:set_can_traverse("hero", true)
self:set_traversable_by("hero", true)

local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(50)
  m:set_angle((self:get_direction() - 2) * math.pi / 2)
  m:set_max_distance(32)
  m:start(self)
  
game:set_value("dungeon_" .. dungeon .. "_boss_door_open", true)
end)

sol.timer.start((delay + 2500),function()
sol.audio.play_sound("/common/door/stone_slam")
end)


sol.timer.start((delay + 3200),function()

  local m = sol.movement.create("straight")
  m:set_speed(50)
  m:set_angle(hero:get_direction() * math.pi / 2)
  m:set_max_distance(48)
  m:start(hero)
  
game:set_pause_allowed(true)
end)

else
sol.timer.start(50, function()
game:start_dialog("gameplay.logic._cant_open_boss_door", function()
if show_bars == true and not starting_cutscene then game:hide_bars()end
end)
end)
end
end

