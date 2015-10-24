local entity = ...
local game = entity:get_game()
local map = entity:get_game():get_map()
local open = false

-- Boss door -- WORK IN PROGRESS

function entity:on_created()
  self:set_size(32, 16)
  self:set_origin(16,20)
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
  self:set_traversable_by("hookshot", false)
  self:set_traversable_by("arrow", false)
  self:set_can_traverse("arrow", false)
  self:set_traversable_by("destructible", false)
end

function go_up()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(32)
  m:start(entity)
end

function p_go_up()
  local m = sol.movement.create("straight")
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(32)
  m:start(hero)
end

function go_down()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(false)
  m:set_speed(32)
  m:set_angle(3 * math.pi)
  m:set_max_distance(32)
  m:start(entity)
end

function entity:on_interaction()

local hero = self:get_map():get_entity("hero")
local x,y = entity:get_position()
local direction = hero:get_direction()

if game:get_value("dungeon_" .. dungeon .. "_big_key") == true then -- does Link have the key ?

hero:freeze() -- avoid player input during the phase
game:set_pause_allowed(false) -- it is a cutscene so you can't access the pause menu

sol.audio.play_sound("/common/boss_door_unlock")
--self:get_sprite():set_animation("unlocking")
hero:set_position(x, y+12) -- center hero
game:draw_cutscene_bars()
game:set_hud_enabled(false)

sol.timer.start(650,function()
sol.audio.play_sound("/common/door/stone_open")
go_up()
end)

sol.timer.start(1000,function()
open = true
p_go_up()
end)

sol.timer.start(3000,function()
sol.audio.play_sound("/common/door/stone_close")
go_down()
hero:unfreeze()
game:set_pause_allowed(true)
end)

else -- Link don't have the key
game:start_dialog("gameplay.cannot_open_boss_door")
end
end

