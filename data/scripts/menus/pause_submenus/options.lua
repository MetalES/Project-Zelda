local submenu = require("scripts/menus/pause_submenus/submenu_manager")
local options_submenu = submenu:new()
local music_slider_x, sound_slider_x, old_volume

function options_submenu:on_started()
  submenu.on_started(self)

  local font, font_size = sol.language.get_menu_font()
  local width, height = sol.video.get_quest_size()
  local center_x, center_y = width / 2, height / 2
  
  self.volume_control_bar = sol.surface.create("menus/volume_control.png")
  self.volume_control_cursor = sol.surface.create("menus/volume_control_cursor.png")


  self.video_mode_label_text = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "selection_menu.options.video_mode",
  }
  self.video_mode_label_text:set_xy(center_x - 50, center_y - 58)

  self.video_mode_text = sol.text_surface.create{
    horizontal_alignment = "right",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text = sol.video.get_mode(),
  }
  self.video_mode_text:set_xy(center_x + 104, center_y - 58)

  self.command_column_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "options.commands_column",
  }
  self.command_column_text:set_xy(center_x - 76, center_y - 37)

  self.keyboard_column_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "options.keyboard_column",
  }
  self.keyboard_column_text:set_xy(center_x - 7, center_y - 37)

  self.joypad_column_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "options.joypad_column",
  }
  self.joypad_column_text:set_xy(center_x + 69, center_y - 37)
  
  self.volume_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "options.music",
  }
  
  self.sound_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    text_key = "options.sound",
  }

  self.commands_surface = sol.surface.create(215, 160)
  self.commands_surface:set_xy(center_x - 107, center_y - 18)
  self.commands_highest_visible = 1
  self.commands_visible_y = 0

  self.command_texts = {}
  self.keyboard_texts = {}
  self.joypad_texts = {}
  self.command_names = { "action", "attack", "item_1", "item_2", "pause", "left", "right", "up", "down" }
  
  for i = 1, #self.command_names + 1 do

    self.command_texts[i] = sol.text_surface.create{
      horizontal_alignment = "left",
      vertical_alignment = "top",
      font = font,
      font_size = font_size,
    }
	
	if i < 10 then
	  self.command_texts[i]:set_text_key("options.command." .. self.command_names[i])
	else
	  self.command_texts[i]:set_text_key("options.command.minimap")
	end

    self.keyboard_texts[i] = sol.text_surface.create{
      horizontal_alignment = "left",
      vertical_alignment = "top",
      font = font,
      font_size = font_size,
    }

    self.joypad_texts[i] = sol.text_surface.create{
      horizontal_alignment = "left",
      vertical_alignment = "top",
      font = font,
      font_size = font_size,
    }
  end
  
  old_volume = self.game:get_value("old_volume")
  
  function update_music_slider(self)
    local volume = old_volume
    self.game:set_value("old_volume", volume)
    old_volume = self.game:get_value("old_volume")
    music_slider_x = 128 + (volume * 128 / 100)
  end
  
  function update_sound_slider(self)
    local volume = sol.audio.get_sound_volume()
    sound_slider_x = 128 + (volume * 128 / 100)
    self.game:set_value("old_sound", volume)
  end
  
  update_music_slider(self)
  update_sound_slider(self)
  
  self:load_command_texts()

  self.up_arrow_sprite = sol.sprite.create("menus/arrow")
  self.up_arrow_sprite:set_direction(1)
  self.up_arrow_sprite:set_xy(center_x - 64, center_y - 24)
  self.down_arrow_sprite = sol.sprite.create("menus/arrow")
  self.down_arrow_sprite:set_direction(3)
  self.down_arrow_sprite:set_xy(center_x - 64, center_y + 32)
  self.cursor_sprite = sol.sprite.create("menus/options_cursor")
  self.cursor_position = nil
  self:set_cursor_position(self.game.option_memorized_position or 1)
  
  self.game:set_custom_command_effect("action", "change")
end

function options_submenu:increase_music_volume()
  local volume = old_volume

  if volume < 100 then
    volume = volume + 5
	old_volume = volume
    sol.audio.set_music_volume(volume)
	
	sol.audio.play_sound("menu/option_modifyvalue")
    update_music_slider(self)
  end
end

function options_submenu:decrease_music_volume()
  local volume = old_volume
  if volume > 0 then
    volume = volume - 5
    sol.audio.set_music_volume(volume)
	sol.audio.play_sound("menu/option_modifyvalue")
	old_volume = volume
    update_music_slider(self)
  end
end

function options_submenu:increase_sound_volume()
  local volume = sol.audio.get_sound_volume()
  if volume < 100 then
    volume = volume + 5
    sol.audio.set_sound_volume(volume)
	sol.audio.play_sound("menu/option_modifyvalue")
    update_sound_slider(self)
  end
end

function options_submenu:decrease_sound_volume()

  local volume = sol.audio.get_sound_volume()
  if volume > 0 then
    volume = volume - 5
    sol.audio.set_sound_volume(volume)
	sol.audio.play_sound("menu/option_modifyvalue")
    update_sound_slider(self)
  end
end


-- Loads the text displayed for each game command, for the
-- keyboard and the joypad.
function options_submenu:load_command_texts()

  self.commands_surface:clear()
  for i = 1, #self.command_names + 1 do
  
    if i < 10 then
	  local keyboard_binding = self.game:get_command_keyboard_binding(self.command_names[i])
      local joypad_binding = self.game:get_command_joypad_binding(self.command_names[i])
      self.keyboard_texts[i]:set_text(keyboard_binding:sub(1, 9))
      self.joypad_texts[i]:set_text(joypad_binding:sub(1, 9))
	else
	  self.joypad_texts[i]:set_text(self.game:get_value("joypad_minimap"))
	  self.keyboard_texts[i]:set_text(self.game:get_value("keyboard_minimap"))
	end
  
    local y = 16 * i - 13
    self.command_texts[i]:draw(self.commands_surface, 4, y)
    self.keyboard_texts[i]:draw(self.commands_surface, 74, y)
    self.joypad_texts[i]:draw(self.commands_surface, 143, y)
  end
end

function options_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then

    local width, height = sol.video.get_quest_size()

    self.cursor_position = position
    if position == 1 then  -- Video mode.
      self:set_caption("options.caption.press_action_change_mode")
      self.cursor_sprite.x = width / 2 - 58
      self.cursor_sprite.y = height / 2 - 59
      self.cursor_sprite:set_animation("big")
    elseif position >= 2 and position <= 11 then  -- Customization of a command.
      self:set_caption("options.caption.press_action_customize_key")

      -- Make sure the selected command is visible.
      while position <= self.commands_highest_visible do
        self.commands_highest_visible = self.commands_highest_visible - 1
        self.commands_visible_y = self.commands_visible_y - 16
      end

      while position > self.commands_highest_visible + 3 do
        self.commands_highest_visible = self.commands_highest_visible + 1
        self.commands_visible_y = self.commands_visible_y + 16
      end

      self.cursor_sprite.x = width / 2 - 105
      self.cursor_sprite.y = height / 2 - 32 + 16 * (position - self.commands_highest_visible)
      self.cursor_sprite:set_animation("small")
	  
	else
	  local y = position == 12 and 40 or 54
	  self.cursor_sprite.x = width / 2 - 104
      self.cursor_sprite.y = height / 2 + y
	  self.cursor_sprite:set_animation("small")
	  
	  self:set_caption("options.caption.press_action_change_mode")
    end
  end
  self.game.option_memorized_position = position
end

function options_submenu:on_draw(dst_surface)

  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)

  -- Cursor.
  self.cursor_sprite:draw(dst_surface, self.cursor_sprite.x, self.cursor_sprite.y)

  -- Text.
  self.video_mode_label_text:draw(dst_surface)
  self.video_mode_text:draw(dst_surface)
  self.command_column_text:draw(dst_surface)
  self.keyboard_column_text:draw(dst_surface)
  self.joypad_column_text:draw(dst_surface)
  self.commands_surface:draw_region(0, self.commands_visible_y, 215, 48, dst_surface) --84
  
  self.volume_text:draw(dst_surface, 87, 160)
  self.sound_text:draw(dst_surface, 86, 175)
  
  -- Volume Bar
  for i = 0, 1 do
    self.volume_control_bar:draw(dst_surface, 121, 164 + (i * 14))
	
	local x = i == 0 and music_slider_x or sound_slider_x
	local y = i == 0 and 161 or 175
	self.volume_control_cursor:draw(dst_surface, x, y)
  end

  -- Arrows.
  if self.commands_visible_y > 0 then
    self.up_arrow_sprite:draw(dst_surface)
    self.up_arrow_sprite:draw(dst_surface, 115, 0)
  end

  if self.commands_visible_y < 100 then
    self.down_arrow_sprite:draw(dst_surface)
    self.down_arrow_sprite:draw(dst_surface, 115, 0)
  end

  self:draw_save_dialog_if_any(dst_surface)
end

function options_submenu:on_command_pressed(command)
  local position = self.cursor_position
 
  if self.command_customizing ~= nil then
    -- We are customizing a command: any key pressed should have been handled before.
    error("options_submenu:on_command_pressed() should not called in this state")
  end

  local handled = submenu.on_command_pressed(self, command)
  
  if self.changing_volume then
    if command == "action" then
	  submenu.avoid_can_save_from_qsmenu = false
	  if position == 12 then sol.audio.set_music_volume(math.floor(old_volume / 3)) end
	  self:set_caption("options.caption.press_action_change_mode")
	  sol.audio.play_sound("menu/finished_custom_option")
	  self.changing_volume = false
	  self.cursor_sprite:set_animation("small")
	elseif command == "left" then
	  if position == 12 then
	    self:decrease_music_volume()
	  elseif position == 13  then
	    self:decrease_sound_volume()
	  end
	elseif command == "right" then
	  if position == 12 then
	    self:increase_music_volume()
	  elseif position == 13 then
	    self:increase_sound_volume()
	  end
	end
	return true
  end
  

  if not handled then
  
    if command == "left" then
	  self:previous_submenu()
      handled = true
    elseif command == "right" then
	  self:next_submenu()
      handled = true
    elseif command == "up" then
      sol.audio.play_sound("/menu/cursor")
      self:set_cursor_position((position + 11) % 13 + 1)
      handled = true
    elseif command == "down" then
      sol.audio.play_sound("/menu/cursor")
      self:set_cursor_position(position % 13 + 1)
      handled = true
    elseif command == "action" then
	  sol.audio.play_sound("/menu/start_custom_option")
      
	  if position >= 12 then
	    submenu.avoid_can_save_from_qsmenu = true
	    if position == 12 then sol.audio.set_music_volume(old_volume) end
		self.changing_volume = true
		self.cursor_sprite:set_animation("small_blink")
		self:set_caption("options.caption.press_arrow_change")
		return
		
  	  elseif position == 1 then
        -- Change the video mode.
        sol.video.switch_mode()
        self.video_mode_text:set_text(sol.video.get_mode())
		
      elseif position == 11 then
	    -- Customize minimap.
		self.old_value_joypad = self.game:get_value("joypad_minimap")
		self.old_value_keyboard = self.game:get_value("keyboard_minimap")
		
        self:set_caption("options.caption.press_key")
        self.cursor_sprite:set_animation("small_blink")
		self.customizing_command = true
		
	  else
        -- Customize a game command.
        self:set_caption("options.caption.press_key")
        self.cursor_sprite:set_animation("small_blink")
        local command_to_customize = self.command_names[position - 1]
        self.game:capture_command_binding(command_to_customize, function()
          sol.audio.play_sound("menu/finished_custom_option")
          self:set_caption("options.caption.press_action_customize_key")
          self.cursor_sprite:set_animation("small")
          self:load_command_texts()
        end)
      end
      handled = true
    end
  end

  return handled
end

function options_submenu:reload_minimap()
  -- if the command is already set by an engine button, swap it
  for i = 1, #self.command_names do
    if self.game:get_value("joypad_minimap") == self.game:get_command_joypad_binding(self.command_names[i]) then
	  -- get the command that have the same command
	  local same_command = self.game:get_command_joypad_binding(self.command_names[i]):match(self.game:get_value("joypad_minimap")) and i or nil

	  if same_command > 0 then
	    local command = self.game:get_command_joypad_binding(self.command_names[same_command])
		local joypad = self.old_value_joypad
		
	    self.game:set_command_joypad_binding(self.command_names[same_command], joypad)
		self.game:set_value("joypad_minimap", command)
		self.old_value_joypad = nil
	  end
	end
	
    if self.game:get_value("keyboard_minimap") == self.game:get_command_keyboard_binding(self.command_names[i]) then
	  local same_command = self.game:get_command_keyboard_binding(self.command_names[i]):match(self.game:get_value("keyboard_minimap")) and i or nil
	  
	  if same_command > 0 then
	    local command = self.game:get_command_keyboard_binding(self.command_names[same_command])
		local keyboard = self.old_value_keyboard
		
	    self.game:set_command_keyboard_binding(self.command_names[same_command], keyboard)
		self.game:set_value("keyboard_minimap", command)
		self.old_value_keyboard = nil
	  end
	end
  end
  
  self:load_command_texts()
  self.customizing_command = false
  self.cursor_sprite:set_animation("small")
  sol.audio.play_sound("menu/finished_custom_option")
end

function options_submenu:on_key_pressed(key)
  if not self.customizing_command then
    return false
  end

  self.game:set_value("keyboard_minimap", key)
  self:reload_minimap()
  return true
end

function options_submenu:on_joypad_button_pressed(button)

  if not self.customizing_command then
    return false
  end

  local joypad_action = "button " .. button
  self.game:set_value("joypad_minimap", joypad_action)
  self:reload_minimap()
  return true
end

return options_submenu