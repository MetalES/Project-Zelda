-- Base class of each submenu.

local submenu = {}

function submenu:new(game)
  local o = { game = game }
  setmetatable(o, self)
  self.__index = self
  return o
end

function submenu:on_started()  
  self.background_color = sol.surface.create("pause_background.png", true)
  self.background_color:set_opacity(216)
  
  self.background_surfaces = sol.surface.create("pause_submenus.png", true)
  
  self.color_layer_surface = sol.surface.create(320, 240) -- background color
  
  self.save_dialog_sprite = sol.sprite.create("menus/pause_save_dialog")
  self.save_dialog_state = 0

  local dialog_font, dialog_font_size = sol.language.get_dialog_font()
  local menu_font, menu_font_size = sol.language.get_menu_font()
  
  self.mailbag_counter = sol.text_surface.create{
     horizontal_alignment = "center",
     vertical_alignment = "top",
     text = self.game:get_value("unread_mail_amount") or nil,
     font = "white_digits",
  }
  
   local amount = self.game:get_item("gold_skulltula"):get_amount()
   local maximum = self.game:get_item("gold_skulltula"):get_max_amount()

   self.gold_skulltula_counter = sol.text_surface.create{
     horizontal_alignment = "center",
     vertical_alignment = "top",
     text = self.game:get_value("amount_of_skulltulas"),
     font = (amount == maximum) and "green_digits" or "white_digits",
   }

  self.question_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  self.question_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  self.answer_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    text_key = "save_dialog.yes",
    font = dialog_font,
    font_size = dialog_font_size,
  }
  self.answer_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
    text_key = "save_dialog.no",
    font = dialog_font,
    font_size = dialog_font_size,
  }

  self.caption_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = "fixed",
    font = menu_font,
    font_size = menu_font_size,
  }

  self.caption_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = "fixed",
    font = menu_font,
    font_size = menu_font_size,
  }

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", "save")
end

-- Sets the caption text.
-- The caption text can have one or two lines, with 20 characters maximum for each line.
-- If the text you want to display has two lines, use the '$' character to separate them.
-- A value of nil removes the previous caption if any.
function submenu:set_caption(text_key)

  if text_key == nil then
    self.caption_text_1:set_text(nil)
    self.caption_text_2:set_text(nil)
  else
    local text = sol.language.get_string(text_key)
    local line1, line2 = text:match("([^$]+)%$(.*)")
    if line1 == nil then
      -- Only one line.
      self.caption_text_1:set_text(text)
      self.caption_text_2:set_text(nil)
    else
      -- Two lines.
      self.caption_text_1:set_text(line1)
      self.caption_text_2:set_text(line2)
    end
  end
end

-- Draw the caption text previously set.
function submenu:draw_caption(dst_surface)

  local width, height = dst_surface:get_size()

  if self.caption_text_2:get_text():len() == 0 then
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 89)
  else
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 83)
    self.caption_text_2:draw(dst_surface, width / 2, height / 2 + 95)
  end
end

function submenu:next_submenu()

  sol.audio.play_sound("/menu/dir_right")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
 -- implementing a condition, we don't want the mail menu or the bomber notebook menu to be a part of the default menu, so to avoid to declare the menu in game_manager, we declared it here.
  if submenu_index > 4 then submenu_index = 1 else submenu_index = (submenu_index % #submenus) + 1 end
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game, submenus[submenu_index], false)
end

function submenu:previous_submenu()

  sol.audio.play_sound("/menu/dir_left")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  if submenu_index < 2 then submenu_index = 5 else submenu_index = (submenu_index + #submenus - 2) % #submenus + 1 end
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game, submenus[submenu_index], false)
end

function submenu:on_command_pressed(command)

  local handled = false

  if self.game:is_dialog_enabled() then
    -- Commands will be applied to the dialog box only.
    return false
  end

  if self.save_dialog_state == 0 then
    -- The save dialog is not shown
    if command == "attack" and not sol.menu.is_started(self.game.pause_submenus[6]) and not self.game:get_value("avoid_can_save_from_qsmenu") then
      sol.audio.play_sound("/common/dialog/message_end")
      self.save_dialog_state = 1
      self.save_dialog_choice = 0
      self.save_dialog_sprite:set_animation("left")
      self.question_text_1:set_text_key("save_dialog.save_question_0")
      self.question_text_2:set_text_key("save_dialog.save_question_1")
      self.action_command_effect_saved = self.game:get_custom_command_effect("action")
      self.game:set_custom_command_effect("action", "validate")
      self.attack_command_effect_saved = self.game:get_custom_command_effect("attack")
      self.game:set_custom_command_effect("attack", "validate")
      handled = true
    end
  else
    -- The save dialog is visible.
    if command ~= "pause" then
      handled = true  -- Block all commands on the submenu except pause.
    end

    if command == "left" or command == "right" then
      -- Move the cursor.
      sol.audio.play_sound("/menu/cursor")
      if self.save_dialog_choice == 0 then
        self.save_dialog_choice = 1
        self.save_dialog_sprite:set_animation("right")
      else
        self.save_dialog_choice = 0
        self.save_dialog_sprite:set_animation("left")
      end
    elseif command == "action" or command == "attack" then
      -- Validate a choice.
      if self.save_dialog_state == 1 then
        -- After "Do you want to save?".
        self.save_dialog_state = 2
        if self.save_dialog_choice == 0 then
          self.game:save()
          sol.audio.play_sound("/common/dialog/done") --heartpiece
        else
          sol.audio.play_sound("danger")
        end
        self.question_text_1:set_text_key("save_dialog.continue_question_0")
        self.question_text_2:set_text_key("save_dialog.continue_question_1")
        self.save_dialog_choice = 0
        self.save_dialog_sprite:set_animation("left")
      else
        -- After "Do you want to continue?".
        sol.audio.play_sound("danger")
        self.save_dialog_state = 0
        self.game:set_custom_command_effect("action", self.action_command_effect_saved)
        self.game:set_custom_command_effect("attack", self.attack_command_effect_saved)
        if self.save_dialog_choice == 1 then
          sol.main.reset()
        end
      end
    end
  end

  return handled
end

function submenu:draw_background(dst_surface)

  local submenu_index = self.game:get_value("pause_last_submenu")
  local width, height = dst_surface:get_size()

    self.background_color:draw_region(
      320 * (submenu_index - 1), 0, 320, 240,
      dst_surface, (width - 320) / 2, (height - 240) / 2)
	  
    self.background_surfaces:draw_region(
      320 * (submenu_index - 1), 0, 320, 240,
      dst_surface, (width - 320) / 2, (height - 240) / 2)
	  
	 self.color_layer_surface:draw_region(
	 0, 0, 320, 240, dst_surface, (width - 320) / 2, 
	 (height - 240) / 2)
	 
	 if sol.menu.is_started(self.game.pause_submenus[6]) or sol.menu.is_started(self.game.pause_submenus[7]) then
	 self.color_layer_surface:fill_color({0,0,0})
     self.color_layer_surface:set_opacity(150)
	 else
	 self.color_layer_surface:set_opacity(0)
	 end
	 
end

function submenu:draw_save_dialog_if_any(dst_surface)
  if self.save_dialog_state > 0 then
    local width, height = dst_surface:get_size()
    local x = width / 2
    local y = height / 2
    self.save_dialog_sprite:draw(dst_surface, x - 110, y - 33)
    self.question_text_1:draw(dst_surface, x, y - 8)
    self.question_text_2:draw(dst_surface, x, y + 8)
    self.answer_text_1:draw(dst_surface, x - 60, y + 28)
    self.answer_text_2:draw(dst_surface, x + 59, y + 28)
  end
end


return submenu
