local game = ...
local shop_manager = {}

--Shop Manager : Manage the whole shop process (cursor, treasure)

local getting_treasure = false
local shopkeeper_dst
local max_item_cursor = {}
function game:start_shop()
  sol.menu.start(game, shop_manager, true)
end

function game:stop_shop()
  sol.menu.stop_menu(shop_manager)
end

function shop_manager:on_started()
  local font_size = 14

  self.game = game

  --refresth the time
  self.game.time_flow = 1000 * 1000 * 1000 * 1000 
  self.game:set_clock_enabled(false)
  self.game:set_clock_enabled(true)

  self.game:get_hero():freeze()
  self.game:set_pause_allowed(false)
  
  shopkeeper_dst = self.game:get_map():get_entity("shopkeeper"):get_distance(self.game:get_hero())
  
  for items in self.game:get_map():get_entities("shop_item") do
    max_item_cursor[#max_item_cursor + 1] = items
  end
 
  -- avoid using default dialog (we want dialog to be dynamic), use text surface spawn the dialog
  self.dialog_text_line0 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    font = "lttp",
    font_size = font_size,
	color = {255,102,102}
  }
  
  self.dialog_text_line1 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    font = "lttp",
    font_size = font_size,
  }
  
  self.dialog_text_line2 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    font = "lttp",
    font_size = font_size,
  }
  
  self.dialog_text_line0:set_text_key("equipment.caption.deku_nuts_bag_3")
  self.dialog_text_line1:set_text_key("equipment.caption.deku_nuts_bag_2")
  self.dialog_text_line2:set_text_key("equipment.caption.deku_nuts_bag_1")
  self.menu_surface = sol.surface.create(320, 240)
  self.dialog_box_src = sol.surface.create("hud/dialog_box.png")
  self.cursor_sprite_src = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite_src:set_animation("letter")
end

function shop_manager:on_finished()
  sol.timer.stop_all(self)

end

function shop_manager:on_draw(dst_surface)
  local width, height = dst_surface:get_size()
  local x = width / 2
  local y = height / 2
  
  
  if not getting_treasure then
    self.dialog_box_src:draw_region(0, 0, 280, 60, dst_surface, x - 140, y + 24)
	self.dialog_text_line0:draw(dst_surface, x - 124, 164)
	if self.dialog_text_line1:get_text() ~= nil then
	  self.dialog_text_line1:draw(dst_surface, x - 124, 177)
	end
	if self.dialog_text_line2:get_text() ~= nil then
	  self.dialog_text_line2:draw(dst_surface, x - 124, 190)
	end
  end
end

function shop_manager:on_command_pressed(command)
  local handled = false

  if not handled then
    if command == "left" then
      handled = true
    elseif command == "right" then
      handled = true
    elseif command == "up" then
      sol.audio.play_sound("menu/cursor")
      handled = true
    elseif command == "down" then
      sol.audio.play_sound("menu/cursor")
      handled = true
    elseif command == "action" then
      sol.audio.play_sound("danger")
	  handled = true
    elseif command == "attack" then
	 sol.menu.stop(self)
	 self.game:get_hero():unfreeze()
	end
    handled = true
  end

  return handled
end

return shop_manager