local submenu = require("scripts/menus/pause_submenus/submenu_manager")
local bomber_submenu = submenu:new()

function bomber_submenu:on_started()
  submenu.on_started(self)
  
  self.game:set_custom_command_effect("attack", "return")
  self.game:set_custom_command_effect("action", "open")
  
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite:set_animation("letter")
  
  self.is_reading = false

  local font, font_size = sol.language.get_menu_font()
  local width, height = sol.video.get_quest_size()

  self.mail_name_surface = sol.surface.create(320,800)
  self.text_mail = sol.surface.create(222, 133)
  self.text_display_surface = sol.surface.create("menus/quest_status_mail_system.png")
  
  self.mail_highest_visible = 1
  self.mail_visible_y = 0
  
  self.mail_names = {} 
  
  self.total_mail_reward = 0
  self.mail_reward = {}
  
  -- This handle the whole mail page
  self.mail_content = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = "letter",
    font_size = 14,
    text = text_lines,
  }
  
  self.page_number = sol.text_surface.create({
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = "letter",
    font_size = 14,
  })
  
  for i = 1, 100 do
    if self.game:get_value("mail_" .. i .. "_obtained") then
      self.mail_names[i] = sol.text_surface.create{
        horizontal_alignment = "left",
        vertical_alignment = "top",
        font = "lttp",
        font_size = 14,
        text_key = "quest_status_mail.mail." .. self.game:get_value("mail_" .. i .. "_name"),
      }
	end
  end

  self.up_arrow_sprite = sol.sprite.create("menus/arrow")
  self.up_arrow_sprite:set_animation("blink")
  self.up_arrow_sprite:set_direction(1)
  self.up_arrow_sprite:set_xy(144, 40)
  self.down_arrow_sprite = sol.sprite.create("menus/arrow")
  self.down_arrow_sprite:set_direction(3)
  self.down_arrow_sprite:set_animation("blink")
  self.down_arrow_sprite:set_xy(144,212)

  self.cursor_position = nil
  self:set_cursor_position(1)
  
  self:load_extra()
end

function bomber_submenu:on_finished()
  if sol.menu.is_started(self.game.pause_submenus[3]) then
    self.game.pause_submenus[3]:on_started()
  end
end


function bomber_submenu:load_extra()
  self.mail_name_surface:clear()
  
  local misc_img = sol.surface.create("menus/quest_status_mail_system.png")
   
  for i = 1, 100 do
    local y = 7 + (i - 1) * 32
	local x = 18
	
	if self.game:get_value("mail_" .. i .. "_obtained") then
	  misc_img:draw_region(0, 22, 310, 32, self.mail_name_surface, 5, 0 + (33 * (i - 1)) - (i - 1))
	  self.mail_names[i]:draw(self.mail_name_surface, 47, y + 2)
	  
	  if self.game:get_value("mail_" .. i .. "_opened") then
	    misc_img:draw_region(0, 0, 27, 19, self.mail_name_surface, x, y - 1)
	  elseif self.game:get_value("mail_" .. i .. "_highlighted") then
	    misc_img:draw_region(26, 1, 27, 18, self.mail_name_surface, x, y)
	  else
	    misc_img:draw_region(52, 1, 27, 18, self.mail_name_surface, x, y)
	  end
	end
  end
end


function bomber_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then

    local width, height = sol.video.get_quest_size()

    self.cursor_position = position
    while position <= self.mail_highest_visible do
      self.mail_highest_visible = self.mail_highest_visible - 1
      self.mail_visible_y = self.mail_visible_y - 32
    end

    while position > self.mail_highest_visible + 5 do
      self.mail_highest_visible = self.mail_highest_visible + 1
      self.mail_visible_y = self.mail_visible_y + 32
    end

    self.cursor_sprite.x = 10
    self.cursor_sprite.y = 40 + 32 * (position - self.mail_highest_visible)
  end
end

function bomber_submenu:on_draw(dst_surface)
  -- Text.
  self.mail_name_surface:draw_region(0, self.mail_visible_y + 32, 320, 160, dst_surface, 0, 53)
  -- Arrows.
  if self.game:get_value("unread_mail_amount") > 5 then
    if self.mail_visible_y > -32 then
      self.up_arrow_sprite:draw(dst_surface)
    end

    if self.mail_visible_y < (-32 * (- math.floor(self.game:get_value("unread_mail_amount") / 5)) - 33) then
      self.down_arrow_sprite:draw(dst_surface)
    end
  end
  
  if self.is_reading then
    self.text_display_surface:draw_region(48, 55, 262, 172, dst_surface, 30, 51)
	self.text_display_surface:draw_region(0, 54, 48, 44, dst_surface, 225, 159)
	self.text_mail:draw(dst_surface, 51, 70)
	self.page_number:draw(dst_surface, 210, 220)
  else
    self.cursor_sprite:draw(dst_surface, self.cursor_sprite.x, self.cursor_sprite.y)
  end
end

function bomber_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)

  if not handled then
    if command == "left" then 
	  if self.is_reading then
	    if self.current_page > 0 then
		  self.current_page = self.current_page - 1
		  self.page_number:set_text(sol.language.get_string("page") ..  ": " .. self.current_page .. "/" .. self.max_page)
		  self:parse_text()
		end
 	  elseif self.cursor_position - 5 >= 1 then
		sol.audio.play_sound("menu/cursor")
		self:set_cursor_position(self.cursor_position - 5)
	  end
      handled = true
	  
    elseif command == "right" then	
	  if self.is_reading then 
	    if self.current_page < self.max_page then
		  self.current_page = self.current_page + 1
		  self.page_number:set_text(sol.language.get_string("page") ..  ": " .. self.current_page .. "/" .. self.max_page)
		  self:parse_text()
		end
	  elseif self.cursor_position + 5 <= self.game:get_value("unread_mail_amount") then
		sol.audio.play_sound("menu/cursor")
		self:set_cursor_position(self.cursor_position + 5)
		self:set_cursor_position(self.cursor_position + 5)
		self:set_cursor_position(self.cursor_position - 5)
	  end
      handled = true
	  
    elseif command == "up" then
	  if not self.is_reading then
	    if self.game:get_value("unread_mail_amount") > 1 then
	   	  sol.audio.play_sound("menu/cursor")
		  if self.cursor_position == 1 then
		    self:set_cursor_position(self.game:get_value("unread_mail_amount"))
		  else
		    self:set_cursor_position(self.cursor_position - 1)
		  end
	    end
	  end
      handled = true
	  
    elseif command == "down" then
	  if not self.is_reading then
	    if self.game:get_value("unread_mail_amount") > 1 then
	   	  sol.audio.play_sound("menu/cursor")
		  if self.cursor_position >= self.game:get_value("unread_mail_amount") then
		    self:set_cursor_position(1)
		  else
		    self:set_cursor_position(self.cursor_position + 1)
		  end
	    end
	  end
      handled = true
	  
	elseif command == "pause" then
	  if not self.is_reading then
	    submenu.avoid_can_save_from_qsmenu = false
	    self.is_reading = false
	    sol.menu.stop(self)
	  end
	  handled = true
	
    elseif command == "action" then
	  if self.is_reading then
	    self:start_treasure_if_reward()
	    self:display_mail(nil)
		self.is_reading = false
	  else 
	    self:display_mail(self.cursor_position)
	    self.is_reading = true
		if not self.game:get_value("mail_" .. self.cursor_position .. "_opened") then
		  self.game:set_value("mail_" .. self.cursor_position .. "_opened", true)
		  self.mail_reward = self.text["reward"]
		end
	  end
      sol.audio.play_sound("danger")
	  handled = true
	  
    elseif command == "attack" then
	  if not self.is_reading then
	    self.game:set_custom_command_effect("action", "open")
        self.game:set_custom_command_effect("attack", "save")
	    submenu.secondary_menu_started = false
        sol.timer.start(1, function()
	      submenu.avoid_can_save_from_qsmenu = false
	    end)
	    sol.menu.stop(self)
	  else
	    self.is_reading = false
		self:start_treasure_if_reward()
	  end
      handled = true
    end
  end
  
  if not self.game:get_value("mail_" .. self.cursor_position .. "_highlighted") then
    self.game:set_value("mail_" .. self.cursor_position .. "_highlighted", true)
  end
  
  self:load_extra()
  return handled
end

function bomber_submenu:start_treasure_if_reward()
  -- read the closed mail reward, if any.
  local mail = self.text["reward"]
  local savegame = mail[1]
  local reward = mail[2]
  local variant = mail[3]
  
  if mail ~= nil then
    if not self.game:get_value(savegame) then
	  self.game.got_treasure_from_mail = true
	  self.game:get_hero():start_treasure(reward, variant, savegame)
	  self.game:get_value(savegame, true)
	end
  end
end

function bomber_submenu:display_mail(index)
  local mail_text
  self.current_page = 0

  if index ~= nil then
    -- Load the target file
    mail_text = require("languages/".. sol.language.get_language() .. "/text/mail/" .. self.game:get_value("mail_".. index .. "_name"))
	-- Read the file, and store all of it's content in self.text.
    self.text = mail_text
	self.max_page = self.text:get_max_page()
	-- Parse the text.
	self.page_number:set_text(sol.language.get_string("page") ..  ": " .. self.current_page .. "/" .. self.max_page)
	self:parse_text()
  else
	-- The surface handling the text has been cleared, but not the text
	self.text_mail:clear()
	self.mail_content:set_text("")
    mail_text = nil
    self.text = nil
	self.max_page = nil
  end
end

function bomber_submenu:parse_text()
  local line = 0
  local texts = self.text[self.current_page]

  self.text_mail:clear()
  self.mail_content:set_text(nil)
  
  -- $ = pass line
  for text in texts:gmatch("[^$]+") do
    line = line + 1
	self.mail_content:set_text(text)
    self.mail_content:draw(self.text_mail, 0, 0 + ((line - 1) * 13))
  end
  
  
end

return bomber_submenu