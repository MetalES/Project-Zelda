local item = ...
local game = item:get_game()
-- item configuration
local item_name = "cloak_darkness"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"
local volume_bgm = game:get_value("old_volume")

local magic_need = 1
local ghost_trail
local magic_timer
local cloak_logic
local hero_dead_sprite

-- Cloak of Darkness

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end


function item:on_map_changed()
  game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
  if game:get_value("item_"..item_name.."_state") > 0 then 
	game:get_hero():freeze()
	game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
	game:set_ability("sword", game:get_value("item_saved_sword"))
	game:get_hero():set_walking_speed(88)
	if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
	game:get_hero():unfreeze()
	self:set_finished()
  end
self:set_finished()
end


function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

if ghost_trail ~= nil then ghost_trail:stop(); ghost_trail = nil end
if magic_timer ~= nil then magic_timer:stop(); magic_timer = nil end
if cloak_logic ~= nil then cloak_logic:stop(); cloak_logic = nil end
        
hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))

game:set_ability("shield", game:get_value("item_saved_shield"))

self:set_finished()
hero:unfreeze()
if game:get_value("starting_cutscene") ~= true then game:set_pause_allowed(true) end
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
local hero = game:get_hero()
local tunic = game:get_value("item_saved_tunic")
local x, y, layer = hero:get_position()

local function cancel_item() game:get_map():move_camera(hero_dead_sprite.x, hero_dead_sprite.y, 300, function() hero:set_position(hero_dead_sprite.x, hero_dead_sprite.y, hero_dead_sprite.layer); hero_dead_sprite:remove(); hero:set_visible(true); sol.audio.play_sound("stairs_indicator"); self:transit_to_finish() end, 10, 0) end
local function end_by_collision() game:set_ability("shield", game:get_value("item_saved_shield")); cancel_item(); sol.audio.play_sound(sound_dir.."ending"); game:set_pause_allowed(true) end

game:using_item()

if game:get_value("item_"..item_name.."_state") == 0 then
	hero:unfreeze()
	self:store_equipment()
	sol.audio.play_sound("common/item_show")
	sol.audio.play_sound(sound_dir.."on")
	sol.audio.play_sound(sound_dir.."is_ghost")
	game:set_value("item_"..item_name.."_state", 1)
	
	hero:set_tunic_sprite_id("hero/item/"..item_name.."/tunic"..tunic)

	    hero_dead_sprite = game:get_map():create_custom_entity({
				x = x,
				y = y,
				layer = layer,
				direction = 0,
				sprite = "hero/item/"..item_name.."/dead_sprite.tunic"..tunic,
			    }) 
		hero_dead_sprite.x, hero_dead_sprite.y, hero_dead_sprite.layer = hero_dead_sprite:get_position()
		hero_dead_sprite:set_drawn_in_y_order(true)	
		
		sol.audio.set_music_volume(volume_bgm * 0.55)
		
	-- for entity in map:get_entities("invisible_") do
    -- entity:set_visible(true)
	-- entity:set_enabled(true)
	-- end
		
		cloak_logic = sol.timer.start(10, function()
			if hero:get_direction() == 0 then new_x = -1; new_y = 0 
			elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
			elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
			elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
			end
			
			if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
			if hero:get_state() == "falling" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
		   return true
		end)
	     
	game:remove_magic(magic_need)
		magic_timer = sol.timer.start(1200, function() 
			if game:get_magic() > 0 then 
			game:remove_magic(magic_need)
		    else
			game:remove_life(magic_need)
			end
		return true
		end)
		
		ghost_trail = sol.timer.start(50, function()
		local lx, ly, llayer = hero:get_position()
			local trail = game:get_map():create_custom_entity({
				x = lx,
				y = ly,
				layer = llayer,
				direction = hero:get_direction(),
				sprite = "hero/item/"..item_name.."/tunic"..tunic,
			    })
			trail:get_sprite():set_animation(hero:get_animation())
			trail:get_sprite():fade_out(22, function() trail:remove() end)
		return true
		end)
		
elseif game:get_value("item_"..item_name.."_state") == 1 then
hero:unfreeze()
if ghost_trail ~= nil then ghost_trail:stop(); ghost_trail = nil end
if magic_timer ~= nil then magic_timer:stop(); magic_timer = nil end
if cloak_logic ~= nil then cloak_logic:stop(); cloak_logic = nil end
sol.audio.play_sound(sound_dir.."ending")

hero:set_visible(false)
game:get_map():move_camera(hero_dead_sprite.x, hero_dead_sprite.y, 200, function() 
hero:set_position(hero_dead_sprite.x, hero_dead_sprite.y, hero_dead_sprite.layer)
hero_dead_sprite:remove()
hero:set_visible(true) 
sol.audio.set_music_volume(volume_bgm)
sol.audio.play_sound("stairs_indicator")
self:transit_to_finish() end, 10, 0)

end
end


function item:set_finished()
	if ghost_trail ~= nil then ghost_trail:stop(); ghost_trail = nil end
	if magic_timer ~= nil then magic_timer:stop(); magic_timer = nil end
	if cloak_logic ~= nil then cloak_logic:stop(); cloak_logic = nil end
		
	game:set_value("item_"..item_name.."_state", 0)
	game:item_finished()
	
game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))

game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
end