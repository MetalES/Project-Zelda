local item = ...
local game = item:get_game()
-- item configuration
local item_name = "cloak_darkness"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

-- Cloak of Darkness

--Item description (for on_using())

-- item that allow to pass through cellars and see what normal eye can't see (Alternate Eye of Truth)
-- during the phase, Link is a ghost, an image (dead) of him is created, but controllable, he can activate floor switches
-- if he touch a light source, the ghost image is deplecated, teleport the old ghost to the dead link entity and make it
-- alive again, BUT Link lose 1 heart
-- if Link ran out of magic, he will loose 1/4 heart every 300ms.

function item:on_created()
  self:set_savegame_variable(item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end


function item:on_map_changed()
if link_dead_sprite ~= nil then link_dead_sprite:remove() end
if cloak_process ~= nil then cloak_process:stop(); cloak_process = nil end 
self:set_finished()
end

function item:on_using()

end