local item = ...
local game = item:get_game()

local item_name = "farore_wind"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"
local volume_bgm = game:get_value("old_volume")

local magic_needed = 10
local state = 0 -- no warp made, warp made

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
end

function item:on_using()
local hero = game:get_hero()
local x, y, layer = hero:get_position()

if game:is_in_dungeon() then
	if state == 0 then
		game:set_hud_enabled(false)
		if not show_bars then game:show_bars() end
		if game:get_magic() >= magic_needed then game:remove_magic(magic_needed) end
		
		hero:set_animation("brandish")
		
		local warp_effect = game:get_map():create_custom_entity({
			x = x,
			y = y - 20,
			layer = layer + 1,
			direction = 0,
			sprite = "effects/hero/farore_wind"
		})
		warp_effect:set_drawn_in_y_order(true)
		sol.audio.play_sound(sound_dir.."cast")
		
		sol.timer.start(6000, function()
			warp_effect:get_sprite():set_animation("end")
			sol.timer.start(500, function()
				warp_effect:remove()
				state = 1
				game:set_hud_enabled(true)
				self:set_finished()
			end)
		end)	
	elseif state == 1 then 
	print("would warp")
	self:set_finished()
end


else
print("not in a dungeon")
end
-- self:set_finished()
end