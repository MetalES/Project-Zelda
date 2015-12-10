local bottle = ...
local game = bottle:get_game()
local slot
local sprite

function bottle:on_created()
  local x, y = self:get_game():get_hero():get_position()
  local bx
  local by
  local direction4 = game:get_hero():get_direction()
  
  if direction4 == 0 then bx = x + 60; by = 0
  elseif direction4 == 1 then by = y + 60; bx = 0
  elseif direction4 == 2 then bx = x - 60; by = 0
  else by = y - 60; bx = 0
  end
  
  bottle:set_size(40, 32)
  bottle:set_origin(bx + x, by + y)
  bottle_spr = self:create_sprite("entities/misc/item/bottle/bottle_swing")
  bottle_spr:set_direction(direction4)
  
  function bottle_spr:on_animation_finished()
	bottle:remove()
  end
end

bottle:add_collision_test("sprite", function(bottle, other)
sol.timer.start(200, function()
  if other:get_type() == "pickable" then
  --TODO
    if game:get_value("_item_slot_1") == item_name then slot = ("bottle_^(.*)_[0-9]+$")
    elseif game:get_value("_item_slot_2") == item_name then slot = ("bottle_^(.*)_[0-9]+$") end
 
  print("pick")
  if not show_bars then game:show_bars() end
  game:set_hud_enabled(false)
  game:get_hero():set_animation("bottle_catching", function()
  game:get_hero():start_treasure(slot, treasure)
  end)
end
end)
end)