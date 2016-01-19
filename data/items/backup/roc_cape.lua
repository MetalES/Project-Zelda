local item = ...
local game = item:get_game()

local item_name = "roc_cape"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

local volume_bgm = game:get_value("old_volume")

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value("item_"..item_name.."_state", 0)
  game:set_value("item_"..item_name.."_type", 0)
end

function item:on_using()
local hero = game:get_hero()
local roc_cape_dst = 0
local dir_to_s
local opposite
local distance = 3

hero:unfreeze()

roc_cape_dst = sol.timer.start(10, function()

if hero:get_direction() == 0 then dir_to_s = "right"; opposite = "left"
elseif hero:get_direction() == 1 then dir_to_s = "up"; opposite = "down"
elseif hero:get_direction() == 2 then dir_to_s = "left"; opposite = "right"
else dir_to_s = "down"; opposite = "up"
end

if game:is_command_pressed(dir_to_s) then 
if distance ~= 300 then distance = distance + 3 else distance = 300 end
elseif not game:is_command_pressed(dir_to_s) or game:is_command_pressed(opposite) then 
if distance ~= 0 then distance = distance - 3 else distance = 0 end
end

print("d"..distance)

return true 
end)

hero:start_jumping(hero:get_direction() * 2, 10, false)

-- local first_step = sol.movement.create("jump")
-- first_step:set_direction8(hero:get_direction() * 2)
-- first_step:set_distance(1 + distance)
-- first_step:start(hero)


self:set_finished()
end