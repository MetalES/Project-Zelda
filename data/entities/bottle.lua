local bottle = ...
local game = bottle:get_game()
local slot
local sprite
local treasure
local item_name
local catching_entity = false

function bottle:on_created()
  local x, y = game:get_hero():get_position()
  local bx
  local by
  local direction4 = game:get_hero():get_direction()
  
  if direction4 == 0 then bx = x - 16; by = 0
  elseif direction4 == 1 then by = y + 16; bx = 0
  elseif direction4 == 2 then bx = x - 16; by = 0
  else by = y - 16; bx = 0
  end
  
  bottle:set_size(16, 16)
  bottle:set_origin(bx + x, by + y)
  bottle_spr = self:create_sprite("entities/misc/item/bottle/bottle_swing")
  bottle_spr:set_direction(direction4)
  
  function bottle_spr:on_animation_finished()
	bottle:remove()
  end
end

bottle:add_collision_test("sprite", function(bottle, other)
local b1x, b1y, layer = bottle:get_position()
local direction_btl = game:get_hero():get_direction()
local b_dir_x
local b_dir_y

if direction_btl == 0 then b_dir_x = 16; b_dir_y = 0
elseif direction_btl == 1 then b_dir_y = -22; b_dir_x = 0
elseif direction_btl == 2 then b_dir_x = -16 ; b_dir_y = 0
else b_dir_y = 8; b_dir_x = 0
end
  
	sol.timer.start(250, function()
		if other:get_type() == "pickable" and other:get_sprite():get_animation() == "fairy" then
			if not catching_entity then
				game:get_hero():freeze()
				if game:get_value("_item_slot_1") == "bottle_1" or game:get_value("_item_slot_1") == "bottle_2" or game:get_value("_item_slot_1") == "bottle_3" or game:get_value("_item_slot_1") == "bottle_4" then slot = game:get_value("_item_slot_1")
				elseif game:get_value("_item_slot_2") == "bottle_1" or game:get_value("_item_slot_2") == "bottle_2" or game:get_value("_item_slot_2") == "bottle_3" or game:get_value("_item_slot_2") == "bottle_4" then slot = game:get_value("_item_slot_2") end
	
				if not show_bars then game:show_bars() end
				game:set_hud_enabled(false)
				game:set_pause_allowed(false)
	
				if other:get_sprite():get_animation() == "fairy" then
					treasure = 7
					other:remove()
				end
				
				bottle:remove()
				sol.audio.play_sound("items/bottle/close")
				game:get_hero():set_animation("bottle_catching", function()
				game:get_hero():set_direction(3)
					game:set_hud_enabled(true)
					game:get_hero():start_treasure(slot, treasure, savegame_variable, function()
						game:set_pause_allowed(true)
						catching_entity = false
						game:get_hero():unfreeze()
					end)
				end)
			  catching_entity = true
			end
		end
		
	-- soft water
		if game:get_map():get_ground(b1x + b_dir_x, b1y + b_dir_y, layer) == "shallow_water" or game:get_map():get_ground(b1x + b_dir_x, b1y + b_dir_y, layer) == "deep_water" then
			if not catching_entity then
				game:get_hero():freeze()
				if game:get_value("_item_slot_1") == "bottle_1" or game:get_value("_item_slot_1") == "bottle_2" or game:get_value("_item_slot_1") == "bottle_3" or game:get_value("_item_slot_1") == "bottle_4" then slot = game:get_value("_item_slot_1")
				elseif game:get_value("_item_slot_2") == "bottle_1" or game:get_value("_item_slot_2") == "bottle_2" or game:get_value("_item_slot_2") == "bottle_3" or game:get_value("_item_slot_2") == "bottle_4" then slot = game:get_value("_item_slot_2") end
	
				if not show_bars then game:show_bars() end
				bottle:remove()

				game:set_hud_enabled(false)
	
				sol.audio.play_sound("items/bottle/close")
				game:get_hero():set_animation("bottle_catching", function()
				game:get_hero():set_direction(3)
					game:set_hud_enabled(true)
					game:get_hero():start_treasure(slot, 2, savegame_variable, function()
						game:set_pause_allowed(true)
						catching_entity = false
						game:get_hero():unfreeze()
					end)
				end)
			  catching_entity = true
			end
		end
	end)
end)