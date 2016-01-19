local submenu = require("scripts/menus/pause_submenu")
local mail_submenu = submenu:new()

function mail_submenu:on_started()

  submenu.on_started(self)
  
  local kb_pause = self.game:get_command_keyboard_binding("pause")
  local jp_pause = self.game:get_command_joypad_binding("pause")
  self.game:set_value("kb_pause", kb_pause)
  self.game:set_value("jp_pause", jp_pause) 
  self.game:set_command_keyboard_binding("pause", nil)
  self.game:set_command_joypad_binding("pause", nil)  
  
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite:set_animation("letter")

  local font, font_size = sol.language.get_menu_font()
  local width, height = sol.video.get_quest_size()

  self.mail_name_surface = sol.surface.create(105,400)
  self.mail_surface = sol.surface.create(320,240)
  
  self.commands_highest_visible = 1
  self.commands_visible_y = 0
  
  self.image_src = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}

  self.command_texts = {}
  self.command_names = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}
    
  for i = 1, #self.command_names do
    self.command_texts[i] = sol.text_surface.create{
      horizontal_alignment = "left",
      vertical_alignment = "top",
      font = "lttp",
      font_size = 14,
      text_key = "quest_status_mail.mail." .. self.command_names[i],
    }
	
	self.image_src[i] = sol.surface.create("menus/quest_status_mail_system.png")
	
  end

  self:load_extra()

  self.up_arrow_sprite = sol.sprite.create("menus/arrow")
  self.up_arrow_sprite:set_direction(1)
  self.up_arrow_sprite:set_xy(58, 48)
  self.down_arrow_sprite = sol.sprite.create("menus/arrow")
  self.down_arrow_sprite:set_direction(3)
  self.down_arrow_sprite:set_xy(58,212)

  self.cursor_position = nil
  self:set_cursor_position(1)
end


function mail_submenu:load_extra()
  self.mail_name_surface:clear()
  
  local misc_img = sol.surface.create("menus/quest_status_mail_system.png")
  
  misc_img:draw_region(0, 37, 182, 172, self.mail_surface, 129, 55)
  
  local cursor_window_position = {
  { 5, 49},
  { 5, 83},
  { 5, 117},
  { 5, 151},
  { 5, 185},
  }
  
  for k, cursor_window_position in ipairs(cursor_window_position) do
    if self.game:get_value("mail_" .. k .. "_obtained") then
		misc_img:draw_region(85, 0, 124, 33, self.mail_surface, cursor_window_position[1], cursor_window_position[2])
    end
   end
   
  for i = 1, #self.command_names do
    local y = 34 * i - 32
	  if self.game:get_value("mail_" .. i .. "_obtained") then
		self.command_texts[i]:draw(self.mail_name_surface, 34, y)
	  end
	  
	  if self.game:get_value("mail_" .. i .. "_obtained") and self.game:get_value("mail_" .. i .. "_opened") ~= true then
	    self.image_src[i]:draw_region(55, 7, 27, 18, self.mail_name_surface, 2, y - 1) -- new letter
	  elseif self.game:get_value("mail_" .. i .. "_obtained") and self.game:get_value("mail_" .. i .. "_opened") ~= true and self.game:get_value("mail_" .. i .. "_highlighted") then
	    misc_img:draw_region(28, 7, 27, 18, self.mail_name_surface, 2, y - 1) -- white letter
	  elseif self.game:get_value("mail_" .. i .. "_obtained") and self.game:get_value("mail_" .. i .. "_opened") then
	    self.image_src[i]:draw_region(1, 2, 27, 23, self.mail_name_surface, 2, y - 1) -- opened
	  end
  end

  
end


function mail_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then

    local width, height = sol.video.get_quest_size()

    self.cursor_position = position
      while position <= self.commands_highest_visible do
        self.commands_highest_visible = self.commands_highest_visible - 1
        self.commands_visible_y = self.commands_visible_y - 34
      end

      while position > self.commands_highest_visible + 5 do
        self.commands_highest_visible = self.commands_highest_visible + 1
        self.commands_visible_y = self.commands_visible_y + 34  --32
      end

      self.cursor_sprite.x = 10
      self.cursor_sprite.y = 34 + 34 * (position - self.commands_highest_visible)
  end
end

function mail_submenu:on_draw(dst_surface)
  self.mail_surface:draw(dst_surface, x, y)
  -- Text.
  self.mail_name_surface:draw_region(0, self.commands_visible_y + 27, 105, 169, dst_surface, 17, 49)

  -- Arrows.
 if self.game:get_value("total_mail") > 5 then
  if self.commands_visible_y > 0 then
    self.up_arrow_sprite:draw(dst_surface)
  end

  if self.commands_visible_y < 60 then
    self.down_arrow_sprite:draw(dst_surface)
  end
 end
    -- Cursor.
  self.cursor_sprite:draw(dst_surface, self.cursor_sprite.x, self.cursor_sprite.y)
    self:draw_save_dialog_if_any(dst_surface)
end

function mail_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)

  if not handled then
    if command == "left" then
      handled = true
    elseif command == "right" then
      handled = true
    elseif command == "up" then
	  if self.game:get_value("total_mail") > 1 then
	      sol.audio.play_sound("menu/cursor")
		  self:set_cursor_position(self.cursor_position - 1)
		  if self.cursor_position <= 0 then
			self:set_cursor_position(9)
		  end
	  end
      handled = true
    elseif command == "down" then
	  if self.game:get_value("total_mail") > 1 then
		  sol.audio.play_sound("menu/cursor")
		  self:set_cursor_position(self.cursor_position + 1)
		  if self.cursor_position >= self.game:get_value("total_mail") then
			self:set_cursor_position(1)
		  end
	  end
      handled = true
    elseif command == "action" then
      sol.audio.play_sound("danger")
	  handled = true
    elseif command == "attack" then
	  if not displaying_mail then
	   self.game:set_custom_command_effect("action", "open")
       self.game:set_custom_command_effect("attack", "save")
	   self.game:set_command_keyboard_binding("pause", self.game:get_value("kb_pause"))
	   self.game:set_command_joypad_binding("pause",self.game:get_value("jp_pause"))
	   self.game:set_value("secondary_menu_started", false)
       sol.timer.start(1, function()
	     self.game:set_value("avoid_can_save_from_qsmenu", false)
	   end)
	   sol.menu.stop(self.game.pause_submenus[6])
	  else
	  -- if it is displaying a letter, just clear the message, it is very simple.
	  displaying_mail = false -- that's it.
	  end
      handled = true
    end
  end

  return handled
end

return mail_submenu