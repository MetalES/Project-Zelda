--[[ Minish Cap styled Boss Door System  ]]

local entity = ...
local game = entity:get_game()

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
 -- check if the door has been already open, if yes, delete the entity that represent the chain.
local dungeon = game:get_dungeon_index()
if game:get_value("dungeon_" .. dungeon .. "boss_door_open") == true then 
sol.main.game:get_map():get_entity("boss_door_chain"):remove()
end
end

function go_up()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(50)
  m:set_angle(math.pi / 2)
  m:set_max_distance(32)
  m:start(entity)
end

function p_go_up()
  local m = sol.movement.create("straight")
  m:set_speed(50)
  m:set_angle(math.pi / 2)
  m:set_max_distance(512)
  m:start(sol.main.game:get_hero())
end

function go_down()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(50)
  m:set_angle(3 * math.pi / 2)
  m:set_max_distance(32)
  m:start(entity)
end

function entity:on_interaction()

local hero = self:get_map():get_entity("hero")
local x,y = self:get_position()
local direction = hero:get_direction()
local dungeon = game:get_dungeon_index()
local delay = 750

if game:get_value("dungeon_" .. dungeon .. "_boss_key") == true then
--game:draw_bars()
hero:freeze()
game:set_pause_allowed(false)
hero:set_position(x, y+12)
game:set_hud_enabled(false)

if game:get_value("dungeon_" .. dungeon .. "boss_door_open") ~= true then
sol.main.game:get_map():get_entity("boss_door_chain"):get_sprite():set_animation("unlocking")
sol.audio.play_sound("/common/boss_door_unlock")
delay = 750
else 
delay = 0
end



sol.timer.start(delay,function()
if game:get_value("dungeon_" .. dungeon .. "boss_door_open") ~= true then sol.main.game:get_map():get_entity("boss_door_chain"):remove() end
sol.audio.play_sound("/common/door/stone_open")
go_up()
self:set_can_traverse("hero", true)
 self:set_traversable_by("hero", true)
end)

sol.timer.start((delay + 850),function()
p_go_up()
end)

sol.timer.start((delay + 1900),function()
sol.audio.play_sound("/common/door/stone_close")
go_down()
hero:unfreeze()
game:set_pause_allowed(true)
game:set_value("dungeon_" .. dungeon .. "boss_door_open", true)
end)

sol.timer.start((delay + 2500),function()
sol.audio.play_sound("/common/door/stone_slam")
end)

sol.timer.start((delay + 2900),function()
p_go_up()
end)
else
game:start_dialog("gameplay.logic._cant_open_boss_door")
end
end

