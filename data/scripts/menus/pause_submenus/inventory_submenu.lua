local submenu = require("scripts/menus/pause_submenus/submenu_manager")
local mini_menu = submenu:new()

local item_names = {
  "green_chuchu_counter", "red_chuchu_counter", "blue_chuchu_counter", "yellow_chuchu_counter",
  "joy_pendant_counter", "acorn_counter", "skull_necklace_counter", "knight_crest_counter",
  "golden_plume_counter", "amber_counter", "deku_seed_counter"
}

function mini_menu:on_started()
  submenu.on_started(self)  
  self.game:set_custom_command_effect("attack", "return")
  
  self.background_surface = sol.surface.create("pause_submenus_mini.png", true)
  -- self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.name_box = sol.surface.create("menus/pause_sub_mini_namebox.png")
  self.sprites = {}
  self.counters = {}

  for k = 1, #item_names do
    -- Get the item, its possession state and amount.
    local item = self.game:get_item(item_names[k])
    local variant = item:get_variant()

    if variant > 0 then
      if item:has_amount() then
        -- Show a counter in this case.
        local amount = item:get_amount()
        local maximum = item:get_max_amount()

        self.counters[k] = sol.text_surface.create{
          horizontal_alignment = "center",
          vertical_alignment = "top",
          text = item:get_amount(),
          font = (amount == maximum) and "green_digits" or "white_digits",
        }
      end

      -- Initialize the sprite and the caption string.
      self.sprites[k] = sol.sprite.create("entities/items")
      self.sprites[k]:set_animation(item_names[k])
      self.sprites[k]:set_direction(variant - 1)
    end
  end
  
  local index = self.game:get_value("pause_inventory_sub_last_item_index") or 0
  local row = math.floor(index / 4)
  local column = index % 4
  self:set_cursor_position(row, column)
end

function mini_menu:on_finished()
  if self:is_assigning_item() then
    self:finish_assigning_item()
  end

  if self.game.hud ~= nil then
    self.game.hud.primary.item_icon_1.surface:set_opacity(255)
    self.game.hud.primary.item_icon_2.surface:set_opacity(255)
  end
end

function mini_menu:set_cursor_position(row, column)
  self.cursor_row = row
  self.cursor_column = column

  local index = row * 4 + column
  self.game:set_value("pause_inventory_sub_last_item_index", index)

  -- Update the caption text and the action icon.
  local item_name = item_names[index + 1]
  local item = item_name and self.game:get_item(item_name) or nil
  local variant = item and item:get_variant() or 0
  local item_icon_opacity = 128
  
  
  if variant > 0 then
    self:set_caption("inventory.caption.item." .. item_name .. "." .. variant)
    self.game:set_custom_command_effect("action", "info")
	item_icon_opacity = 255
  else
    self:set_caption(nil)
    self.game:set_custom_command_effect("action", nil)
  end
  self.game.hud.item_icon_1.surface:set_opacity(item_icon_opacity)
  self.game.hud.item_icon_2.surface:set_opacity(item_icon_opacity)
end

function mini_menu:get_selected_index()
  return self.cursor_row * 4 + self.cursor_column
end

function mini_menu:is_item_selected()
  local item_name = item_names[self:get_selected_index() + 1]
  return self.game:get_item(item_name):get_variant() > 0
end

function mini_menu:show_info_message()

  local item_name = item_names[self:get_selected_index() + 1]
  local variant = self.game:get_item(item_name):get_variant()

  -- Position of the dialog (top or bottom).
  if self.cursor_row >= 2 then
    self.game:set_dialog_position("top")  -- Top of the screen.
  else
    self.game:set_dialog_position("bottom")  -- Bottom of the screen.
  end

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", nil)
  self.game:set_dialog_style("default")
  self.game:start_dialog("_item_description." .. item_name .. "." .. variant, function()
    self.game:set_custom_command_effect("action", "info")
    self.game:set_custom_command_effect("attack", "save")
    self.game:set_dialog_position("auto")  -- Back to automatic position.
  end)
end


function mini_menu:assign_item(slot)
  local index = self:get_selected_index() + 1
  local item_name = item_names[index]
  local item = self.game:get_item(item_name)

  -- If this item is not assignable, do nothing.
  if not item:is_assignable() then
    return
  end

  -- If another item is being assigned, finish it immediately.
  if self:is_assigning_item() then
    self:finish_assigning_item()
  end

  -- Memorize this item.
  self.item_assigned = item
  self.item_assigned_sprite = sol.sprite.create("entities/items")
  self.item_assigned_sprite:set_animation(item_name)
  self.item_assigned_sprite:set_direction(item:get_variant() - 1)
  self.item_assigned_destination = slot

  -- Play the sound.
  sol.audio.play_sound("/menu/select")

  -- Compute the movement.
  local x1 = 106 + 34 * self.cursor_column
  local y1 = 89 + 34 * self.cursor_row
  local x2 = (slot == 1) and 233 or 281
  local y2 = 36

  self.item_assigned_sprite:set_xy(x1, y1)
  local movement = sol.movement.create("target")
  movement:set_target(x2, y2)
  movement:set_speed(500)
  movement:start(self.item_assigned_sprite, function()
    self:finish_assigning_item()
  end)
end

function mini_menu:is_assigning_item()
  return self.item_assigned_sprite ~= nil
end

function mini_menu:finish_assigning_item()

  -- If the item to assign is already assigned to the other icon, switch both items.
  local slot = self.item_assigned_destination
  local current_item = self.game:get_item_assigned(slot)
  local other_item = self.game:get_item_assigned(3 - slot)

  if other_item == self.item_assigned then
    self.game:set_item_assigned(3 - slot, current_item)
  end
  self.game:set_item_assigned(slot, self.item_assigned)

  self.item_assigned_sprite:stop_movement()
  self.item_assigned_sprite = nil
  self.item_assigned = nil
end


function mini_menu:on_command_pressed(command)
  for i = 1, 2 do
	if command == "item_" .. i then
	  if self:is_item_selected() then
	    self:assign_item(i)
	  end
	end
  end

  if command == "attack" then
    sol.menu.stop(self)
	
  elseif command == "action" then
	self:show_info_message()
	
  elseif command == "right" then
    self:set_cursor_position(self.cursor_row, (self.cursor_column + 1) % 4)
	sol.audio.play_sound("menu/cursor")
	
  elseif command == "up" then
     self:set_cursor_position((self.cursor_row - 1) % 3, self.cursor_column)
    sol.audio.play_sound("menu/cursor")
	
  elseif command == "left" then
    self:set_cursor_position(self.cursor_row, (self.cursor_column - 1) % 4)
	sol.audio.play_sound("menu/cursor")
	
  elseif command == "down" then
    self:set_cursor_position((self.cursor_row + 1) % 3, self.cursor_column)
    sol.audio.play_sound("menu/cursor")
	
  elseif command == "pause" or self.game:is_dialog_enabled() then
	return false
  end
 
  return true
end

function mini_menu:on_draw(dst)
  local width, height = dst:get_size()
  local initial_x = width / 2 - 51
  local initial_y = height / 2 - 25
  local y = initial_y
  local k = 0
  
  dst:fill_color({0, 0, 0, 150})
  self.background_surface:draw(dst, 81, 59)
  self.name_box:draw(dst, 88, 197)
  self:draw_caption(dst)
  
  -- Draw the cursor.
  self.cursor_sprite:draw(dst, 109 + (34 * self.cursor_column), 90 + (34 * self.cursor_row))
  

  for i = 0, 3 do
    local x = initial_x

    for j = 0, 3 do
      k = k + 1
      if item_names[k] ~= nil then
        local item = self.game:get_item(item_names[k])
        if item ~= nil and item:get_variant() > 0 then
          -- The player has this item: draw it.
          self.sprites[k]:draw(dst, x, y)
          if self.counters[k] ~= nil then
            self.counters[k]:draw(dst, x + 6, y) -- 8
          end
        end
      end
      x = x + 34
    end
    y = y + 34
  end
  
  -- Draw the item being assigned if any.
  if self:is_assigning_item() then
    self.item_assigned_sprite:draw(dst)
  end
end

return mini_menu