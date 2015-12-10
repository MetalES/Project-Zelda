local entity = ...
local game = entity:get_game()
local map = game:get_map()
local hero = entity:get_map():get_entity("hero")
local x_coordinate, y_coordinate = entity:get_position()
local mx, my = map:get_size()

-- Hud notification

entity:add_collision_test("touching", function(small_door, other)
if other:get_type() == "hero" then
if game:get_value("dungeon_" .. game:get_dungeon_index() .. "_" .. map:get_world() .. "_" .. mx .. "_" .. my .. "_door_open") ~= true and game:get_value("dungeon_" .. game:get_dungeon_index() .. "_small_keys") == 0 and hero:get_direction() == entity:get_direction() then
game:set_custom_command_effect("action", "look")
elseif game:get_value("dungeon_" .. game:get_dungeon_index() .. "_" .. map:get_world() .. "_" .. mx .. "_" .. my .. "_door_open") == true and hero:get_direction() == entity:get_direction() then
game:set_custom_command_effect("action", "open")
elseif game:get_value("dungeon_" .. game:get_dungeon_index() .. "_" .. map:get_world() .. "_" .. mx .. "_" .. my .. "_door_open") ~= true and game:get_value("dungeon_" .. game:get_dungeon_index() .. "_small_keys") >= 1 and hero:get_direction() == entity:get_direction() then
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
if game:get_value("dungeon_" .. dungeon .. "_" .. self:get_name() .. "_door_open") == true then 
sol.main.game:get_map():get_entity(self:get_name() .. "_door_chain"):remove()
end
end

function entity:on_interaction()

local hero = self:get_map():get_entity("hero")
local x,y = self:get_position()
local direction = hero:get_direction()
local dungeon = game:get_dungeon_index()
local delay

--local name = self:get_name():match("^(.*)_[0-9]+$")

if game:get_value("dungeon_" .. game:get_dungeon_index() .. "_small_keys") > 0 then

hero:freeze()
game:set_pause_allowed(false)
hero:set_position(x, y+12)
game:set_hud_enabled(false)

if game:get_value("dungeon_" .. dungeon .. "_" .. self:get_name() .. "_door_open") ~= true then
sol.main.game:get_map():get_entity(self:get_name() .. "_door_chain"):get_sprite():set_animation("unlocking")
sol.audio.play_sound("/common/door/unlock_small_key")
game:remove_small_key()
delay = 750
else
delay = 0
end
--game:draw_cutscene_bars()


sol.timer.start(delay,function()
if game:get_value("dungeon_" .. dungeon .. "_" .. self:get_name() .. "_door_open") ~= true then sol.main.game:get_map():get_entity(self:get_name() .. "_door_chain"):remove() end
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

sol.timer.start((delay + 950),function()

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
  
game:set_value("dungeon_" .. dungeon .. "_" .. self:get_name() .. "_door_open", true)
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
game:start_dialog("gameplay.logic._cant_open_need_key")
end
end

