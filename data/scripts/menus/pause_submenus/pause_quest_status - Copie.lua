local submenu = require("scripts/menus/pause_submenus/submenu_manager")
local quest_status_submenu = submenu:new()
local displaying_scroll = false
local secondary_menu_started = false
local secondary_menu_closed = true


function quest_status_submenu:on_started()

  submenu.on_started(self)
  self.quest_items_surface = sol.surface.create(320, 240)

  self.color_layer_surface = sol.surface.create(320, 240)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.song_surface = nil
  self.scroll_img = nil
  self.caption_text_keys = {}

  local item_sprite = sol.sprite.create("entities/items")

  -- Draw the items on a surface.
  self.quest_items_surface:clear()
  self.color_layer_surface:clear()
  
  local dialog_font, dialog_font_size = sol.language.get_dialog_font()
  local menu_font, menu_font_size = sol.language.get_menu_font()

  self.scroll_title = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {255, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  
  self.scroll_line_1 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {0, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  
  self.scroll_line_2 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {0, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }
  
  self.scroll_line_3 = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    color = {0, 0, 0},
    font = dialog_font,
    font_size = dialog_font_size,
  }

  -- Mail bag.
  if self.game:get_item("mail_bag") ~= nil then
    if self.game:has_item("mail_bag") then
      item_sprite:set_animation("mail_bag")
      item_sprite:set_direction(0)
      item_sprite:draw(self.quest_items_surface, 63, 81)
	  self.mailbag_counter:draw(self.quest_items_surface, 69, 80)
      self.caption_text_keys[0] = "quest_status.caption.mail_bag"
    end
  end

   -- Bomber Notebook
  if self.game:has_item("bomber_notebook") then
      item_sprite:set_animation("bomber_notebook")
      item_sprite:set_direction(0)
      item_sprite:draw(self.quest_items_surface, 92, 81)
      self.caption_text_keys[2] = "quest_status.caption.bomber_notebook"
  end
  
   -- Gold Skulltula
  if self.game:has_item("gold_skulltula") then
     item_sprite:set_animation("gold_skulltula")
     item_sprite:set_direction(0)
     item_sprite:draw(self.quest_items_surface, 92, 109)
  	 self.gold_skulltula_counter:draw(self.quest_items_surface, 98, 108)
     self.caption_text_keys[3] = "quest_status.caption.gold_skulltula"
  end
  
   -- Gerudo Membership
  if self.game:has_item("gerudo_membership_card") then
     item_sprite:set_animation("gerudo_membership_card")
     item_sprite:set_direction(0)
     item_sprite:draw(self.quest_items_surface, 157, 137)
     self.caption_text_keys[41] = "quest_status.caption.gerudo_membership_card"
  end

   -- Aria Amulet
  if self.game:has_item("aria_amulet") then
    item_sprite:set_animation("aria_amulet")
    item_sprite:set_direction(0)
    item_sprite:draw(self.quest_items_surface, 160, 181)
    self.caption_text_keys[42] = "quest_status.caption.aria_amulet"
  end

  -- Pieces of heart.
  local pieces_of_heart_img = sol.surface.create("menus/quest_status_pieces_of_heart.png")
  local x = 39 * (self.game:get_value("i1700") or 0)
  pieces_of_heart_img:draw_region(x, 0, 39, 50, self.quest_items_surface, 105, 72)
  self.caption_text_keys[4] = "quest_status.caption.pieces_of_heart"
  
  local misc_img = sol.surface.create("menus/quest_status_misc.png") -- used for skill disp, dungeon disp
  -- Sword Skills
  local skill_position = {
  { 70, 118},
  { 80, 118},
  { 90, 118},
  { 100, 118},
  { 110, 118},
  { 120, 118},
  { 130, 118},
  }
  
  for s, skill_position in ipairs(skill_position) do
    if self.game:is_skill_learned(s) then
	    self.scroll_img = sol.surface.create("/menus/quest_status_scroll_misc.png")
		misc_img:draw_region(8 * (s - 1), 20, 8, 21,
        self.quest_items_surface, skill_position[1], skill_position[2])
		self.caption_text_keys[s + 15] = "quest_status.caption.skill_" ..s
    end
   end
   
  -- Ocarina Songs
  local song_position = {
  { 68, 140},
  { 77, 140},
  { 86, 140},
  { 95, 140},
  { 104, 140},
  { 113, 140},
  { 122, 140},
  { 131, 140},
  { 68, 150},
  { 77, 150},
  { 86, 150},
  { 95, 150},
  { 104, 150},
  { 113, 150},
  { 122, 150},
  { 131, 150},
  }
  
  for k, song_position in ipairs(song_position) do
    if self.game:is_ocarina_song_learned(k) then
		misc_img:draw_region(56 + (8 * (k - 1)), 20, 8, 9,
        self.quest_items_surface, song_position[1], song_position[2])
		self.caption_text_keys[k + 22] = "quest_status.caption.ocarina_song_" .. k
    end
   end

  -- Dungeons finished
  local dst_positions = {   
    { 183, 154 },
	{ 209, 154 },
	{ 235, 154 },
	{ 175,  100 }, -- shadow
	{ 186,  77 }, -- air
	{ 209,  69 }, -- light
    { 232,  77 }, -- forest
    { 243,  100 }, -- fire
    { 232, 123 }, -- earth
    { 209, 131 }, -- water
    { 186, 123 }, -- spirit
  }
  for i, dst_position in ipairs(dst_positions) do
    if self.game:is_dungeon_finished(i) then
          misc_img:draw_region(20 * (i - 1), 0, 20, 20,
          self.quest_items_surface, dst_position[1], dst_position[2])
		  self.caption_text_keys[i + 4] = "quest_status.caption.medalions_" .. i
    end
  end

  -- Cursor.
  local index = self.game:get_value("quest_status_cursor_position") or 0
  self:set_cursor_position(index)
  
end

function quest_status_submenu:on_finished()
displaying_scroll = false
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
	elseif position == 15 or position == 13 then
	  self.cursor_sprite_y = 133
	elseif position >= 16 and position <= 22 then
	  self.cursor_sprite_y = 128
	elseif position == 41 then
	  self.cursor_sprite_y = 133
	elseif position == 42 then 
	  self.cursor_sprite_y = 177
    end
	
  if self.cursor_position >= 16 and self.cursor_position <= 22 then
	self.cursor_sprite:set_animation("skill")
  elseif self.cursor_position >= 23 and self.cursor_position <= 30 or self.cursor_position >= 31 and self.cursor_position <= 38 then
	self.cursor_sprite:set_animation("ocarina")
	self.song_surface = sol.surface.create("menus/ocarina_song/"..(self.cursor_position - 22)..".png")
  elseif self.cursor_position== 42 then
  	self.cursor_sprite:set_animation("42")
  else
	self.cursor_sprite:set_animation("normal")
  end
  
   if (position >= 16 and position <= 22 or position == 0 or position == 2) and self.caption_text_keys[position] ~= nil then -- skill
    self.game:set_custom_command_effect("action", "open")
   elseif position >= 23 and position <= 38 and self.caption_text_keys[position] ~= nil then
    self.game:set_custom_command_effect("action", "play")
   elseif self.caption_text_keys[position] == nil then -- everything that don't have caption don't need any hud notifications)
    self.game:set_custom_command_effect("action", nil)
   else
    self.game:set_custom_command_effect("action", "info")
  end
  
    self.game:set_value("quest_status_cursor_position", position)
    self:set_caption(self.caption_text_keys[position])
  end
end

function quest_status_submenu:on_update()
  if (sol.menu.is_started(self.game.pause_submenus[6]) or sol.menu.is_started(self.game.pause_submenus[7])) and secondary_menu_closed then
  secondary_menu_started = true
  secondary_menu_closed = false
  self.cursor_sprite:set_animation("skill_dsp")
  elseif not (sol.menu.is_started(self.game.pause_submenus[6]) or sol.menu.is_started(self.game.pause_submenus[7])) and not secondary_menu_closed then
  secondary_menu_started = false
  secondary_menu_closed = true
  self.cursor_sprite:set_animation("normal")
  end
end

function quest_status_submenu:on_command_pressed(command)

  local handled = submenu.on_command_pressed(self, command)

  if not handled then
    if command == "left" and displaying_scroll ~= true and secondary_menu_started ~= true then -- DONE
      if self.cursor_position <= 1 or self.cursor_position == 16 or self.cursor_position == 23 or self.cursor_position == 31 then
        self:previous_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
        if self.cursor_position == 12 then
          self:set_cursor_position(self.cursor_position - 4)
        elseif self.cursor_position == 5 then
          self:set_cursor_position(42)
		elseif self.cursor_position <= 11 and self.cursor_position > 9 or self.cursor_position >= 5 and self.cursor_position <= 7 or self.cursor_position >= 16 and self.cursor_position <= 22 or self.cursor_position >= 23 and self.cursor_position <= 30 or self.cursor_position >= 31 and self.cursor_position <= 38 then
		  self:set_cursor_position(self.cursor_position - 1)
	    elseif self.cursor_position == 2 then
		  self:set_cursor_position(0)
		elseif self.cursor_position == 3 then
		  self:set_cursor_position(1)
		elseif self.cursor_position == 4 then
		  self:set_cursor_position(2)
		elseif self.cursor_position == 8  then -- air
		  self:set_cursor_position(40)
		elseif self.cursor_position == 9 then
		   self:set_cursor_position(39)
		elseif self.cursor_position == 15 then
		   self:set_cursor_position(41)
		elseif self.cursor_position >= 13 and self.cursor_position <= 15 then 
		  self:set_cursor_position(self.cursor_position + 1)
		elseif self.cursor_position == 39 or self.cursor_position == 40 then
		  self:set_cursor_position(4)
		elseif self.cursor_position == 41 then
		  self:set_cursor_position(22)
		elseif self.cursor_position == 42 then
		  self:set_cursor_position(38)
        end
      end
      handled = true

    elseif command == "right" and displaying_scroll ~= true and secondary_menu_started ~= true then
      if self.cursor_position == 7 or self.cursor_position == 11 or self.cursor_position == 12 or self.cursor_position == 13 then
        self:next_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
        if self.cursor_position <= 2 then
          self:set_cursor_position(self.cursor_position + 2)
		elseif self.cursor_position == 22 or self.cursor_position == 30 then
		  self:set_cursor_position(41)
		elseif self.cursor_position == 38 or self.cursor_position == 42 then
		  self:set_cursor_position(5)
		elseif self.cursor_position == 2 or self.cursor_position == 3 then
		  self:set_cursor_position(4)
		elseif self.cursor_position == 0 then
		  self:set_cursor_position(2)
		elseif self.cursor_position == 4 then
		  self:set_cursor_position(39)
        elseif self.cursor_position == 39 then
		  self:set_cursor_position(9)
		elseif self.cursor_position == 40 then
		  self:set_cursor_position(8)
		elseif self.cursor_position == 41 then
		  self:set_cursor_position(15)
		elseif self.cursor_position == 8 then 
		  self:set_cursor_position(self.cursor_position + 4)
		elseif self.cursor_position >= 9 and self.cursor_position < 11 or self.cursor_position >= 5 and self.cursor_position <= 7 or self.cursor_position >= 16 and self.cursor_position <= 22 or self.cursor_position >= 23 and self.cursor_position <= 30 or self.cursor_position >= 31 and self.cursor_position <= 38 then -- air, light & forest -- stones --
		  self:set_cursor_position(self.cursor_position + 1)
		elseif self.cursor_position <= 15 and self.cursor_position > 13 then
		  self:set_cursor_position(self.cursor_position - 1)	
        end
      end
      handled = true

    elseif command == "down" and displaying_scroll ~= true and secondary_menu_started ~= true then
      sol.audio.play_sound("/menu/cursor")
		if self.cursor_position == 15 then
		  self:set_cursor_position(5)
		elseif self.cursor_position == 9 then
		  self:set_cursor_position(8)
		elseif self.cursor_position == 1 then
		  self:set_cursor_position(16)
	    elseif self.cursor_position == 42 then 
		  self:set_cursor_position(39)
		elseif self.cursor_position == 13 then
		  self:set_cursor_position(7)
		elseif self.cursor_position == 14 then
		  self:set_cursor_position(6)
	    elseif self.cursor_position >= 23 and self.cursor_position <= 30 or self.cursor_position >= 20 and self.cursor_position <= 22 then -- oc1 to oc2
		 self:set_cursor_position(self.cursor_position + 8)
		elseif self.cursor_position == 4 then
		 self:set_cursor_position(21)
		elseif self.cursor_position >= 16 and self.cursor_position <= 19 or self.cursor_position == 8 or self.cursor_position == 16 then
		 self:set_cursor_position(self.cursor_position + 7)
		elseif self.cursor_position == 31 then
		 self:set_cursor_position(0) 
		elseif self.cursor_position == 3 then
		 self:set_cursor_position(18)
		elseif self.cursor_position >= 32 and self.cursor_position <= 35 then
		 self:set_cursor_position(2)
		elseif self.cursor_position >= 36 and self.cursor_position <= 38 then
		 self:set_cursor_position(4)
		elseif self.cursor_position == 5 or self.cursor_position == 6 or self.cursor_position == 7 or self.cursor_position == 10 then
		  self:set_cursor_position(self.cursor_position + 4)
		elseif self.cursor_position >= 11 and self.cursor_position < 13 or self.cursor_position == 0 and self.cursor_position <= 1 or self.cursor_position == 2 or self.cursor_position >= 39 and self.cursor_position <= 42 then 
		  self:set_cursor_position(self.cursor_position + 1)	
		end
      handled = true

   elseif command == "up" and displaying_scroll ~= true and secondary_menu_started ~= true then
   sol.audio.play_sound("/menu/cursor")
        if self.cursor_position == 0 then
		  self:set_cursor_position(31)
		elseif self.cursor_position == 5 then 
		  self:set_cursor_position(15)
	    elseif self.cursor_position == 6 then 
		  self:set_cursor_position(14)
		elseif self.cursor_position == 7 then 
		  self:set_cursor_position(13)
		elseif self.cursor_position == 15 then 
		  self:set_cursor_position(8)
		elseif self.cursor_position == 2 then 
		  self:set_cursor_position(33)
		elseif self.cursor_position == 4 then 
		  self:set_cursor_position(37)
		elseif self.cursor_position >= 17 and self.cursor_position <= 18 then
		 self:set_cursor_position(3)
		elseif self.cursor_position == 8 then 
		  self:set_cursor_position(9)
		elseif self.cursor_position >= 19 and self.cursor_position <= 22 then
   		  self:set_cursor_position(4)
		elseif self.cursor_position == 16 then
		  self:set_cursor_position(1)
		elseif self.cursor_position == 39 then
		 self:set_cursor_position(42)
		elseif self.cursor_position == 9 or self.cursor_position == 10 or self.cursor_position == 11 or self.cursor_position == 14 then 
		  self:set_cursor_position(self.cursor_position - 4)
		elseif self.cursor_position >= 0 and self.cursor_position <= 1 or self.cursor_position <= 13 and self.cursor_position > 11 or self.cursor_position == 3 or self.cursor_position >= 39 and self.cursor_position <= 42 then
		  self:set_cursor_position(self.cursor_position - 1)
		elseif self.cursor_position >= 31 and self.cursor_position <= 38 or self.cursor_position >= 28 and self.cursor_position <= 30 then
		 self:set_cursor_position(self.cursor_position - 8)
		elseif self.cursor_position >= 23 and self.cursor_position <= 27 then
		 self:set_cursor_position(self.cursor_position - 7)
		end
   handled = true
  
    elseif command == "action" and displaying_scroll ~= true and secondary_menu_started ~= true then
      if self.game:get_command_effect("action") == nil and self.game:get_custom_command_effect("action") == "info" then
        self:show_info_message()
        
	  elseif self.game:get_command_effect("action") == nil and self.game:get_custom_command_effect("action") == "play" and self.caption_text_keys[self.cursor_position] ~= nil then
        self:play_song()
        
	  elseif self.game:get_command_effect("action") == nil and self.game:get_custom_command_effect("action") == "open" then
	    if self.cursor_position == 0 or self.cursor_position == 2 then
		  self:start_quest_status_secondary_menu(self.cursor_position)
		  self.game.avoid_can_save_from_qsmenu = true

	    elseif self.cursor_position >= 15 and self.cursor_position <= 22 then
		  self.keyboard_up = self.game:get_command_keyboard_binding("up")
		  self.keyboard_down = self.game:get_command_keyboard_binding("down")
		  self.keyboard_left = self.game:get_command_keyboard_binding("left")
		  self.keyboard_right = self.game:get_command_keyboard_binding("right")
		  self.keyboard_attack = self.game:get_command_keyboard_binding("attack")
		  self.keyboard_pause = self.game:get_command_keyboard_binding("pause")
		  
		  self.joypad_up = self.game:get_command_joypad_binding("up")
		  self.joypad_down = self.game:get_command_joypad_binding("down")
		  self.joypad_left = self.game:get_command_joypad_binding("left")
		  self.joypad_right = self.game:get_command_joypad_binding("right")
		  self.joypad_attack = self.game:get_command_joypad_binding("attack")
		  self.joypad_pause = self.game:get_command_joypad_binding("pause")

		  self.game:set_command_keyboard_binding("up", nil) 
		  self.game:set_command_keyboard_binding("down", nil)  
		  self.game:set_command_keyboard_binding("left", nil)  
		  self.game:set_command_keyboard_binding("right", nil)  
		  self.game:set_command_keyboard_binding("attack", nil)  
		  self.game:set_command_keyboard_binding("pause", nil)  
		  
		  self.game:set_command_joypad_binding("up", nil)  
		  self.game:set_command_joypad_binding("down", nil)  
		  self.game:set_command_joypad_binding("left", nil)  
		  self.game:set_command_joypad_binding("right", nil) 
		  self.game:set_command_joypad_binding("pause", nil)  
		  self.game:set_command_joypad_binding("attack", nil)  
		  
		  displaying_scroll = true
		  --draw the text_surface
		  sol.audio.play_sound("menu/scroll_select_open")
		  sol.audio.play_sound("menu/scroll_open")
		  self.scroll_title:set_text_key("quest_status.caption.skill_display_title_"..(self.cursor_position - 15))
		  self.scroll_line_1:set_text_key("quest_status.caption.skill_display_"..(self.cursor_position - 15).."_line_1")
		  self.scroll_line_2:set_text_key("quest_status.caption.skill_display_"..(self.cursor_position - 15).."_line_2")
		  self.scroll_line_3:set_text_key("quest_status.caption.skill_display_"..(self.cursor_position - 15).."_line_3" or nil)
		  
		  self.cursor_sprite:set_animation("skill_dsp")
		  handled = true
		end
      end
	  
	elseif self.game:get_command_effect("action") == nil and displaying_scroll then		
		self.game:set_custom_command_effect("action", "open")
        self.game:set_custom_command_effect("attack", "save")

		self.game:set_command_keyboard_binding("up", self.keyboard_up) 
		self.game:set_command_keyboard_binding("down", self.keyboard_down)  
		self.game:set_command_keyboard_binding("left", self.keyboard_left)
		self.game:set_command_keyboard_binding("right", self.keyboard_right) 
		self.game:set_command_keyboard_binding("attack", self.keyboard_attack)
		self.game:set_command_keyboard_binding("pause", self.keyboard_pause)

		self.game:set_command_joypad_binding("up", self.joypad_up) 
		self.game:set_command_joypad_binding("down", self.joypad_down)  
		self.game:set_command_joypad_binding("left", self.joypad_left)
		self.game:set_command_joypad_binding("right", self.joypad_right) 
		self.game:set_command_joypad_binding("attack", self.joypad_attack)
		self.game:set_command_joypad_binding("pause", self.joypad_pause)	

		self.color_layer_surface:clear()
		self.cursor_sprite:set_animation("skill")
		sol.audio.play_sound("menu/scroll_close")
		displaying_scroll = false
	    handled = true
   end
   return handled
   end
 end
   
function quest_status_submenu:on_draw(dst_surface)
  local width, height = dst_surface:get_size()
  local x = width / 2 - 160
  local y = height / 2 - 120
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.quest_items_surface:draw(dst_surface, x, y)
  self.color_layer_surface:draw(dst_surface, x, y)

  if self.cursor_position > 22 and self.cursor_position <= 38 then
    if self.game:is_ocarina_song_learned(self.cursor_position - 22) then
     self.song_surface:draw(dst_surface, 62,163)
   end
  end
  
  if displaying_scroll then 
    self.game:set_custom_command_effect("action", "return")
    self.game:set_custom_command_effect("attack", nil)
	
    self.color_layer_surface:fill_color({0,0,0})
	self.color_layer_surface:set_opacity(150)
	self.scroll_img:draw_region(0, 98 * ((self.cursor_position - 15) - 1), 226, 98, dst_surface, 47, 71)
	--draw the text above the scroll gfx
	self.scroll_title:draw(dst_surface, 105, 97)
	self.scroll_line_1:draw(dst_surface, 100, 116)
	self.scroll_line_2:draw(dst_surface, 77, 132)
	self.scroll_line_3:draw(dst_surface, 77, 148)
  end
  
  self.cursor_sprite:draw(dst_surface, x + self.cursor_sprite_x, y + self.cursor_sprite_y)
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
  self.game:disable_all_input(true)
  sol.timer.start(5000, function()
  self.game:enable_all_input()
  sol.audio.set_music_volume(sol.audio.get_music_volume() * 4)
  end)
end

function quest_status_submenu:start_quest_status_secondary_menu(menu)
  if menu == 0 then
    sol.menu.start(self.game, self.game.pause_submenus[6], true)
	secondary_menu_started = true
  elseif menu == 2 then
    sol.menu.start(self.game, self.game.pause_submenus[7], true)
	secondary_menu_started = true
  end
end

return quest_status_submenu