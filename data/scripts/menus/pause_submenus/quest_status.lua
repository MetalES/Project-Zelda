local submenu = require("scripts/menus/pause_submenus/submenu_manager")
local quest_status_submenu = submenu:new()

local positions = {   
  { 183, 154 },
  { 209, 154 },
  { 235, 154 },
  { 175,  100 }, -- shadow 4
  { 186,  77 }, -- air 5
  { 209,  69 }, -- light 6
  { 232,  77 }, -- forest 7
  { 243,  100 }, -- fire 8 
  { 232, 123 }, -- earth 9
  { 209, 131 }, -- water 10 
  { 186, 123 }, -- spirit  11
}

local amount = {}

local item = {
  {"mail_bag", 63, 81, "unread_mail_amount", 0}, {"bomber_notebook", 92, 81, false, 2},
  {"gold_skulltula", 92, 109, "amount_of_skulltulas", 3},

  
  {"gerudo_membership_card", 157, 137, false, 41},
  {"aria_amulet", 160, 181, false, 42},
}

function quest_status_submenu:on_started()
  submenu.on_started(self)
  
  self.scroll = sol.surface.create(182, 48)
  self.scroll_img = sol.surface.create("/menus/quest_status_scroll_misc.png")
  
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.caption_text_keys = {}

  local item_sprite = self.item
  
  -- Draw the items on a surface.
  self.extra_surface:clear()
  
  local dialog_font, dialog_font_size = sol.language.get_dialog_font()
  local menu_font, menu_font_size = sol.language.get_menu_font()
  
  self.scroll_title = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {255, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  
  self.scroll_lines = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {0, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  
  for i = 1, #item do
    local obj = item[i]
	local items = self.game:get_item(obj[1])
  
    -- do we have the item, then draw it.
    if items ~= nil then
	  item_sprite:set_animation(obj[1])
	  item_sprite:set_direction(0)
	  item_sprite:draw(self.extra_surface, obj[2], obj[3])

	  if obj[4] ~= false  then
	    local amounts = self.game:get_value(obj[4]) or nil
		local maximum = obj[4] ~= "total_mail" and items:get_max_amount()
		
	    amount[i] = sol.text_surface.create{
		  horizontal_alignment = "center",
		  vertical_alignment = "top",
		  text = amounts,
		  font = amounts == maximum and "green_digits" or "white_digits",
		}
		
		if amount[i] ~= nil then
		  amount[i]:draw(self.extra_surface, obj[2] + 6, obj[3] - 1)
		end
	  end
	end
	self.caption_text_keys[obj[5]] = "quest_status.caption." .. obj[1]
  end
  

  -- Pieces of heart.
  local pieces_of_heart_img = sol.surface.create("menus/quest_status_pieces_of_heart.png")
  local x = 39 * (self.game:get_value("i1700") or 0)
  pieces_of_heart_img:draw_region(x, 0, 39, 50, self.extra_surface, 105, 72)
  self.caption_text_keys[4] = "quest_status.caption.pieces_of_heart"
  
  local misc_img = sol.surface.create("menus/quest_status_misc.png") -- used for skill disp, dungeon disp
  
  for i = 1, 16 do 
    -- Skills 
    if i < 8 then
	  if self.game:is_skill_learned(i) then
	    misc_img:draw_region(8 * (i - 1), 20, 8, 21, self.extra_surface, 60 + (10 * i), 118)
	    self.caption_text_keys[i + 15] = "quest_status.caption.skill_" .. i
	  end
	end
	
	-- Sage sprites
	if i < 9 then 
	  self:shift_target(i)
	end
	
	-- Songs
    if self.game:is_ocarina_song_learned(i) then
	  local x = i > 8 and 59 + (9 * (i - 8)) or 59 + (9 * i)
	  local y = i > 8 and 150 or 140
	  
	  misc_img:draw_region(56 + (8 * (i - 1)), 20, 8, 9, self.extra_surface, x, y)
	  self.caption_text_keys[i + 22] = "quest_status.caption.ocarina_song_" .. i
	end
  end
 
  for i, dst_position in ipairs(positions) do
    if self.game:is_dungeon_finished(i) then
	  misc_img:draw_region(20 * (i - 1), 0, 20, 20, self.extra_surface, dst_position[1], dst_position[2]) 
	  self.caption_text_keys[i + 4] = "quest_status.caption.medalions_" .. i
    end
  end

  -- Cursor.
  local index = self.game:get_value("quest_status_cursor_position") or 0
  self:set_cursor_position(index)
end

function quest_status_submenu:shift_target(i)
  local sprite = self.sage_sprite[i]
  sprite:set_xy(0, -2)
  sprite:set_frame(math.random(0, 11))
  local dy = 1
  local t = 0
  
  sol.timer.start(self, math.random(100, 250), function()
    local _, y = sprite:get_xy()
    if sprite then sprite:set_xy(0, y + dy) end
    -- Direction of movement is changed each second.
    t = (t + 1) % 5
    if t == 0 then dy = -dy end
    -- Restart timer.
    return true
  end)
end

function quest_status_submenu:on_finished()
  sol.timer.stop_all(self)
  self.displaying_scroll = false 
  
  if submenu.on_finished then
    submenu.on_finished(self)
  end
end

function quest_status_submenu:set_cursor_position(position)
--x
  if position ~= self.cursor_position then
    self.cursor_position = position
    if position <= 1 then
      self.cursor_sprite_x = 63
	elseif position >= 2 and position <= 3 then
	  self.cursor_sprite_x = 92
    elseif position == 4 then -- heart piece
      self.cursor_sprite_x = 124
    elseif position == 5 then -- stones
      self.cursor_sprite_x = 193
	elseif position == 6 or position == 10 or position == 14 then  -- fire crystal, light and water medalion
	  self.cursor_sprite_x = 219
	elseif position == 7 or position == 14 then
	  self.cursor_sprite_x = 245
	elseif position == 8 then --shadow
	  self.cursor_sprite_x = 185
	elseif position == 11 or position == 13 then -- forest & earth
	  self.cursor_sprite_x = 242
	elseif position == 12 then -- fire
	  self.cursor_sprite_x = 253
	elseif position == 9 or position == 15 then -- spirit & air
	  self.cursor_sprite_x = 196
	elseif position >= 23 and position <= 30 then --ocarina row 1
	  self.cursor_sprite_x = 63 + (9 * (position - 22))
	  self.cursor_sprite_y = 145
    elseif position >= 31 and position <= 38 then --ocarina row 1
	  self.cursor_sprite_x = 63 + (9 * (position - 30))
	  self.cursor_sprite_y = 155
	elseif position >= 16 and position <= 22 then -- skills
	  self.cursor_sprite_x = 64 + (10 * (position - 15))
	elseif position >= 39 and position <= 41 then
	  self.cursor_sprite_x = 157
	elseif position == 42 then 
	  self.cursor_sprite_x = 160
    end
--y
    if position == 0 or position == 2 or position == 39 then
      self.cursor_sprite_y = 77
    elseif position == 1 or position == 3 or position == 40 then
      self.cursor_sprite_y = 105
    elseif position == 4 then -- heart piece
      self.cursor_sprite_y = 90
    elseif position == 5 or position == 6 or position == 7 then -- stones 
      self.cursor_sprite_y = 164
	elseif position == 8 or position == 12 then
	  self.cursor_sprite_y = 110
	elseif position == 9 or position == 11 then 
	  self.cursor_sprite_y = 87
	elseif position == 10 then
	  self.cursor_sprite_y = 79
	elseif position == 14 then
	  self.cursor_sprite_y = 141
	elseif position == 15 or position == 13 or position == 41 then
	  self.cursor_sprite_y = 133
	elseif position >= 16 and position <= 22 then
	  self.cursor_sprite_y = 128
	elseif position == 42 then 
	  self.cursor_sprite_y = 177
    end
	
	local animation = self.cursor_sprite:get_animation()
    if position >= 16 and position <= 22 then
	  if animation ~= "skill" then
	    self.cursor_sprite:set_animation("skill")
	  end

    elseif position >= 23 and position <= 30 or position >= 31 and position <= 38 then
	  if animation ~= "ocarina" then
	    self.cursor_sprite:set_animation("ocarina")
	  end
	  self.song_surface = sol.surface.create("menus/ocarina_song/".. position - 22 ..".png")
	  
    elseif position == 42 then
  	  self.cursor_sprite:set_animation("42")
    else
	  if animation ~= "normal" then
	    self.cursor_sprite:set_animation("normal")
	  end
    end
  
    if (position >= 16 and position <= 22 or position == 0 or position == 2) and self.caption_text_keys[position] ~= nil then -- skill
      self.game:set_custom_command_effect("action", "open")
    elseif position >= 23 and position <= 38 and self.caption_text_keys[position] ~= nil then
      self.game:set_custom_command_effect("action", "play")
    elseif self.caption_text_keys[position] == nil then
      self.game:set_custom_command_effect("action", nil)
    else
      self.game:set_custom_command_effect("action", "info")
    end
  
    self.game:set_value("quest_status_cursor_position", position)
    self:set_caption(self.caption_text_keys[position])
  end
end

function quest_status_submenu:on_command_pressed(command) 
  if self.playing_song then
	return true
  end
 
  if (command == "action" or command == "attack") and self.displaying_scroll then
	self.game:set_custom_command_effect("action", "open")
    self.game:set_custom_command_effect("attack", "save")
	
	self.scroll:clear()
	self.scroll_lines:set_text(nil)

	self.cursor_sprite:set_animation("skill")
	sol.audio.play_sound("menu/scroll_close")
	self.displaying_scroll = false
  return true
  end

  local handled = submenu.on_command_pressed(self, command)
  local cursor = self.cursor_position
  
  if not handled and not self.displaying_scroll then
    if command == "left" then
      if cursor <= 1 or cursor == 16 or cursor == 23 or cursor == 31 then
        self:previous_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
        if cursor == 12 then
          self:set_cursor_position(cursor - 4)
        elseif cursor == 5 then
          self:set_cursor_position(42)
		elseif cursor <= 11 and cursor > 9 or cursor >= 5 and cursor <= 7 or cursor >= 16 and cursor <= 22 or cursor >= 23 and cursor <= 30 or cursor >= 31 and cursor <= 38 then
		  self:set_cursor_position(cursor - 1)
	    elseif cursor >= 2 and cursor <= 4 then
		  self:set_cursor_position(cursor - 2)
		elseif cursor == 8 then
		  self:set_cursor_position(40)
		elseif cursor == 9 then
		   self:set_cursor_position(39)
		elseif cursor == 15 then
		   self:set_cursor_position(41)
		elseif cursor >= 13 and cursor <= 15 then 
		  self:set_cursor_position(cursor + 1)
		elseif cursor == 39 or cursor == 40 then
		  self:set_cursor_position(4)
		elseif cursor == 41 then
		  self:set_cursor_position(22)
		elseif cursor == 42 then
		  self:set_cursor_position(38)
        end
      end
      handled = true

    elseif command == "right" then
      if cursor == 7 or cursor == 11 or cursor == 12 or cursor == 13 then
        self:next_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
        if cursor <= 2 then
          self:set_cursor_position(cursor + 2)
		elseif cursor == 22 or cursor == 30 then
		  self:set_cursor_position(41)
		elseif cursor == 38 or cursor == 42 then
		  self:set_cursor_position(5)
		elseif cursor == 2 or cursor == 3 then
		  self:set_cursor_position(4)
		elseif cursor == 0 then
		  self:set_cursor_position(2)
		elseif cursor == 4 then
		  self:set_cursor_position(39)
        elseif cursor == 39 then
		  self:set_cursor_position(9)
		elseif cursor == 40 then
		  self:set_cursor_position(8)
		elseif cursor == 41 then
		  self:set_cursor_position(15)
		elseif cursor == 8 then 
		  self:set_cursor_position(cursor + 4)
		elseif cursor >= 9 and cursor < 11 or cursor >= 5 and cursor <= 7 or cursor >= 16 and cursor <= 22 or cursor >= 23 and cursor <= 30 or cursor >= 31 and cursor <= 38 then
		  self:set_cursor_position(cursor + 1)
		elseif cursor <= 15 and cursor > 13 then
		  self:set_cursor_position(cursor - 1)	
        end
      end
      handled = true

    elseif command == "down" then
      sol.audio.play_sound("/menu/cursor")
	  if cursor == 15 then
	    self:set_cursor_position(5)
	  elseif cursor == 9 then
	    self:set_cursor_position(8)
	  elseif cursor == 1 then
	    self:set_cursor_position(16)
	  elseif cursor == 42 then 
	    self:set_cursor_position(39)
	  elseif cursor == 13 then
		self:set_cursor_position(7)
	  elseif cursor == 14 then
		self:set_cursor_position(6)
	  elseif cursor >= 23 and cursor <= 30 or cursor >= 20 and cursor <= 22 then
	    self:set_cursor_position(cursor + 8)
	  elseif cursor == 4 then
		self:set_cursor_position(21)
	  elseif cursor >= 16 and cursor <= 19 or cursor == 8 or cursor == 16 then
		self:set_cursor_position(cursor + 7)
	  elseif cursor == 31 then
		self:set_cursor_position(0) 
	  elseif cursor == 3 then
		self:set_cursor_position(18)
	  elseif cursor >= 32 and cursor <= 35 then
		self:set_cursor_position(2)
	  elseif cursor >= 36 and cursor <= 38 then
		self:set_cursor_position(4)
	  elseif cursor == 5 or cursor == 6 or cursor == 7 or cursor == 10 then
		self:set_cursor_position(cursor + 4)
	  elseif cursor >= 11 and cursor < 13 or cursor == 0 and cursor <= 1 or cursor == 2 or cursor >= 39 and cursor <= 42 then 
		self:set_cursor_position(cursor + 1)	
	  end
      handled = true

    elseif command == "up" then
      sol.audio.play_sound("/menu/cursor")
      if cursor == 0 then
	    self:set_cursor_position(31)
	  elseif cursor == 5 then 
	    self:set_cursor_position(15)
	  elseif cursor == 6 then 
		self:set_cursor_position(14)
	  elseif cursor == 7 then 
		self:set_cursor_position(13)
	  elseif cursor == 15 then 
		self:set_cursor_position(8)
	  elseif cursor == 2 then 
		self:set_cursor_position(33)
	  elseif cursor == 4 then 
		self:set_cursor_position(37)
	  elseif cursor >= 17 and cursor <= 18 then
		self:set_cursor_position(3)
	  elseif cursor == 8 then 
		self:set_cursor_position(9)
	  elseif cursor >= 19 and cursor <= 22 then
   		self:set_cursor_position(4)
	  elseif cursor == 16 then
		self:set_cursor_position(1)
	  elseif cursor == 39 then
		self:set_cursor_position(42)
	  elseif cursor == 9 or cursor == 10 or cursor == 11 or cursor == 14 then 
		self:set_cursor_position(cursor - 4)
	  elseif cursor >= 0 and cursor <= 1 or cursor <= 13 and cursor > 11 or cursor == 3 or cursor >= 39 and cursor <= 42 then
		self:set_cursor_position(cursor - 1)
	  elseif cursor >= 31 and cursor <= 38 or cursor >= 28 and cursor <= 30 then
		self:set_cursor_position(cursor - 8)
	  elseif cursor >= 23 and cursor <= 27 then
		self:set_cursor_position(cursor - 7)
	  end
    handled = true
  
    elseif command == "action" then
	  local c_action = self.game:get_custom_command_effect("action")
      if c_action == "info" then
        self:show_info_message()
        
	  elseif c_action == "play" then
        self:play_song()
        
	  elseif c_action == "open" then
	    if cursor == 0 or cursor == 2 then
		  self:start_quest_status_secondary_menu(cursor)

	    elseif cursor >= 15 and cursor <= 22 then
		  self.displaying_scroll = true
		  --draw the text_surface
		  self.game:set_custom_command_effect("action", "return")
          self.game:set_custom_command_effect("attack", "return")
		  
		  sol.audio.play_sound("menu/scroll_select_open")
		  sol.audio.play_sound("menu/scroll_open")
		  
		  -- Display the Text
		  local line = 0
		  local text = sol.language.get_string("quest_status.caption.skill_display_" .. (cursor - 15))
		  local tx = 26

		  self.scroll_title:set_text_key("quest_status.caption.skill_display_title_"..(cursor - 15))
		  self.scroll_lines:set_text(nil)

		  for text in text:gmatch("[^$]+") do
			line = line + 1
			if line ~= 1 then
			  tx = 0
			end
			self.scroll_lines:set_text(text)
			self.scroll_lines:draw(self.scroll, 6 + tx, 10 + ((line - 1) * 16))
		  end
		  self.cursor_sprite:set_animation("skill_dsp")
		  handled = true
		end
      end
    end
    return handled
  end
end
   
function quest_status_submenu:on_draw(dst_surface)
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.extra_surface:draw(dst_surface)

  if self.cursor_position > 22 and self.cursor_position <= 38 then
    if self.game:is_ocarina_song_learned(self.cursor_position - 22) then
      self.song_surface:draw(dst_surface, 62, 163)
    end
  end
  
  for i, dst_position in ipairs(positions) do
    if self.game:is_dungeon_finished(i) then
	  if i > 3 then
	    self.sage_sprite[i - 3]:draw(dst_surface, dst_position[1], dst_position[2] + 1)
      end
    end
  end

  local menu = self.game.pause.submenus
  if sol.menu.is_started(menu[6]) or sol.menu.is_started(menu[7]) or self.displaying_scroll then
    dst_surface:fill_color({0, 0, 0, 150})
  elseif not sol.menu.is_started(menu[6]) or not sol.menu.is_started(menu[7]) then
    self.cursor_sprite:draw(dst_surface, self.cursor_sprite_x, self.cursor_sprite_y)
  end

  if self.displaying_scroll then 
	self.scroll_img:draw_region(0, 98 * ((self.cursor_position - 15) - 1), 226, 98, dst_surface, 47, 71)
	self.scroll_title:draw(dst_surface, 105, 97)
	self.scroll:draw(dst_surface, 69, 105)
  end  

  self:draw_save_dialog_if_any(dst_surface)
  end
  
function quest_status_submenu:show_info_message()
  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", nil)
  -- get and start a dialog. The dialog depend on the cursor position (which is egal to the caption)
  -- heart piece position
  if self.cursor_position == 4 then 
    local heart_piece_value = self.game:get_value("i1700") or 0
    self.game:start_dialog("_quest_description." .. self.cursor_position.. "." ..heart_piece_value, function()
    self.game:set_custom_command_effect("action", "info")
    self.game:set_custom_command_effect("attack", "save")
    self.game:set_dialog_position("auto")  -- Back to automatic position.
    end)
  else -- the rest
    self.game:start_dialog("_quest_description." .. self.cursor_position, function()
      self.game:set_custom_command_effect("action", "info")
      self.game:set_custom_command_effect("attack", "save")
      self.game:set_dialog_position("auto")  -- Back to automatic position.
    end)
  end
end

function quest_status_submenu:play_song()
  local song = "/items/ocarina/demo_quest_menu/".. (self.cursor_position - 23)
  sol.audio.play_sound(song)
  sol.audio.set_music_volume(sol.audio.get_music_volume() / 4)
  self.playing_song = true
  sol.timer.start(5000, function()
    self.playing_song = false
    sol.audio.set_music_volume(sol.audio.get_music_volume() * 4)
  end)
end

function quest_status_submenu:start_quest_status_secondary_menu(menu)
  if menu == 0 then
    sol.menu.start(self, self.game.pause.submenus[6], false)
  elseif menu == 2 then
    sol.menu.start(self, self.game.pause.submenus[7], false)
  end
end

return quest_status_submenu