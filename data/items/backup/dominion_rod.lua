local item = ...
local game = item:get_game()
-- item configuration
local item_name = "dominion_rod"
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
end


function item:on_map_changed()
-- if link_dead_sprite ~= nil then link_dead_sprite:remove() end
-- if cloak_process ~= nil then cloak_process:stop(); cloak_process = nil end 
self:set_finished()
end


function item:transit_to_finish() --TODO
local hero = game:get_hero()
hero:freeze()

-- if ghost_trail ~= nil then ghost_trail:stop(); ghost_trail = nil end
-- if magic_timer ~= nil then magic_timer:stop(); magic_timer = nil end
-- if cloak_logic ~= nil then cloak_logic:stop(); cloak_logic = nil end
        
hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))

game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_value("item_"..item_name.."_state", 0)

self:set_finished()
hero:unfreeze()
game:set_pause_allowed(true)
end

function item:store_equipment()
	local kb_item_1_key = game:get_command_keyboard_binding("item_1")
	local kb_item_2_key = game:get_command_keyboard_binding("item_2")
	local jp_item_1_key = game:get_command_joypad_binding("item_1")
	local jp_item_2_key = game:get_command_joypad_binding("item_2")
	
    game:set_ability("shield", 0)
	
	if game:get_value("_item_slot_1") ~= item_name then game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil) end
	if game:get_value("_item_slot_2") ~= item_name then game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil) end

	game:set_value("item_1_kb_slot", kb_item_1_key)
	game:set_value("item_2_kb_slot", kb_item_2_key)
	game:set_value("item_1_jp_slot", jp_item_1_key)
	game:set_value("item_2_jp_slot", jp_item_2_key)
	
	game:set_pause_allowed(false)
end

function item:on_using()
self:set_finished()
end