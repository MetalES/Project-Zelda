local item = ...
local game = item:get_game()

local item_name = "nayru_love"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."possession")
  self:set_assignable(true)
end