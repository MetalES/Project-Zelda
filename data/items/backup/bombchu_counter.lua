local item = ...
local game = item:get_game()

local item_name = "bombchu"
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

function item:on_created()
  self:set_savegame_variable("item_bombchu_counter_possession")
  self:set_amount_savegame_variable("item_bombchu_current_amounts")
  self:set_assignable(true)
end

-- Called when the player uses the bombs of his inventory by pressing the corresponding item key.
function item:on_using()
local hero = game:get_hero()
local x, y, layer = hero:get_position()
local direction = hero:get_direction()

  if self:get_amount() == 0 then
    sol.audio.play_sound("wrong")
  else
    hero:freeze()
    self:remove_amount(1)
	self:get_game():get_hero():set_animation("drop")
    sol.audio.play_sound("bomb")
    sol.audio.play_sound("common/item_show")
	
local dx, dy
  if direction == 0 then
    dx, dy = -4, 0
  elseif direction == 1 then
    dx, dy = 3, -20
  elseif direction == 2 then
    dx, dy = -4, 0
  else
    dx, dy = 3, 10
  end

  local bombchu = game:get_map():create_custom_entity({
  x = x + dx,
  y = y + dy,
  layer = layer,
  direction = direction,
  sprite = "entities/misc/item/bombchu/bombchu",
  model = "bombchu"
  })
  sol.timer.start(200, function() hero:unfreeze() end)
  end
  self:set_finished()
end