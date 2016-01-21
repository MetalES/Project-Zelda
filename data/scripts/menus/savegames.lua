-- Savegame selection screen.

local savegame_menu = {}
local cloud_width, cloud_height = 111, 88
local time_of_day = "night"
local cloud0_x, cloud1_x, cloud2_x, cloud3_x, cloud4_x, cloud5_x, cloud6_x = 211, 0, 16, 160, 296, 200, -23
local newfile_ret_value = false

function savegame_menu:on_started()  
self.can_control = true

  -- Create all graphic objects.
  self.surface = sol.surface.create(320, 240)
  self.background = sol.surface.create("menus/selection/background/"..time_of_day.."/background.png")
  self.background_img = sol.surface.create("menus/selection_menu_background.png")
  self.cloud_img = sol.surface.create("menus/selection_menu_cloud.png")
  self.save_container_img = sol.surface.create("menus/selection_menu_save_container.png")
  self.option_container_img = sol.surface.create("menus/selection_menu_option_container.png")
  
  self.draw_option_container = true
  
  self.bird_sprite = sol.sprite.create("menus/selection/background/"..time_of_day.."/bird")
  self.bird_sprite1 = sol.sprite.create("menus/selection/background/"..time_of_day.."/bird")
  
  self.bird_x, self.bird_y =  math.random(-60, -22), math.random(150, 0)
  self.bird1_x, self.bird1_y = math.random(-200, -22), math.random(70, 0)
  
  self.time_of_day = sol.surface.create("menus/selection/background/"..time_of_day.."/element.png")
  self.cloud0 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud0.png")
  self.cloud1 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud1.png")
  self.cloud2 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud2.png")
  self.cloud3 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud3.png")
  self.cloud4 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud4.png")
  self.cloud5 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud5.png")
  self.cloud6 = sol.surface.create("menus/selection/background/"..time_of_day.."/cloud6.png")
  self.hill_right = sol.surface.create("menus/selection/background/"..time_of_day.."/hill_right.png")
  self.hill_left = sol.surface.create("menus/selection/background/"..time_of_day.."/hill_left.png")
  self.night_fog = sol.surface.create("menus/selection/background/night/mountain_fog.png")
  self.mountain_top = sol.surface.create("menus/selection/background/"..time_of_day.."/mountain_top.png")
  self.curent_menu_container_box = sol.surface.create("menus/selection/background/common/fileselect.png")
  self.player_name_graphic = sol.surface.create("menus/selection/background/common/fileselect.png")
  self.file_box_graphic = sol.surface.create("menus/selection/background/common/fileselect.png")
  self.file_box_option = sol.surface.create("menus/selection/background/common/fileselect.png")
  self.file_box_erase = sol.surface.create("menus/selection/background/common/fileselect.png")
  self.menu_name_box_graphic = sol.surface.create("menus/selection/background/common/fileselect.png")
  
  local menu_font, menu_font_size = sol.language.get_menu_font()
  self.option1_text = sol.text_surface.create{
    font = menu_font,
    font_size = "7",
  }
  self.option2_text = sol.text_surface.create{
    font = menu_font,
    font_size = "7",
  }
  
  self.option3_text = sol.text_surface.create{
    font = menu_font,
    font_size = "7",
  }
  
  self.title_text = sol.text_surface.create{
    horizontal_alignment = "center",
    font = menu_font,
    font_size = "7",
  }
  
  self.cursor_position = 1
  self.cursor_sprite = sol.sprite.create("menus/arrow")
  self.cursor_sprite:set_animation("blink")
  self.allow_cursor_move = true
  self.finished = false
  self.phase = nil

  self:repeat_move_clouds()
  self:repeat_move_clouds_slow()
  self:repeat_move_bird()

  -- Run the menu.
  self:read_savegames()
  sol.audio.play_music("/menu/file_selection")
  self:init_phase_select_file()

  -- Show an opening transition.
  self.surface:fade_in()
end

function savegame_menu:on_key_pressed(key)

  local handled = false
  if key == "escape" then
    -- Stop the program.
    handled = true
    sol.main.exit()
  elseif key == "right" then
    handled = self:direction_pressed(0)
  elseif key == "up" then
    handled = self:direction_pressed(2)
  elseif key == "left" then
    handled = self:direction_pressed(4)
  elseif key == "down" then
    handled = self:direction_pressed(6)
  elseif not self.finished then

    -- Phase-specific direction_pressed method.
    local method_name = "key_pressed_phase_" .. self.phase
    handled = self[method_name](self, key)
  end

  return handled
end

function savegame_menu:on_joypad_button_pressed(button)

  local handled = true
  if not self.finished then
    -- Phase-specific joypad_button_pressed method.
    local method_name = "joypad_button_pressed_phase_" .. self.phase
    handled = self[method_name](self, button)
  else
    handled = false
  end

  return handled
end

function savegame_menu:on_joypad_axis_moved(axis, state)

  if axis % 2 == 0 then  -- Horizontal axis.
    if state > 0 then
      self:direction_pressed(0)
    elseif state < 0 then
      self:direction_pressed(4)
    end
  else  -- Vertical axis.
    if state > 0 then
      self:direction_pressed(2)
    else
      self:direction_pressed(6)
    end
  end
end

function savegame_menu:on_joypad_hat_moved(hat, direction8)

  if direction8 ~= -1 then
    self:direction_pressed(direction8)
  end
end

function savegame_menu:direction_pressed(direction8)

  local handled = true
  if self.allow_cursor_move and not self.finished then

    -- The cursor moves too much when using a joypad axis.
    self.allow_cursor_move = false
    sol.timer.start(self, 100, function()
      self.allow_cursor_move = true
    end)

    -- Phase-specific direction_pressed method.
    local method_name = "direction_pressed_phase_" .. self.phase
    handled = self[method_name](self, direction8)
  else
    handled = false
  end
end

function savegame_menu:on_draw(dst_surface)
  local width, height = self.surface:get_size()
  self.background:draw(self.surface, 0, 0)

  -- Clouds.
  self.time_of_day:draw(self.surface, self.time_of_day_x, self.time_of_day_y)
  self.cloud0:draw(self.surface, 211, 180)-- V
  self.cloud1:draw(self.surface, 0, 179)-- V
  self.cloud2:draw(self.surface, 16, 166) -- V
  self.cloud3:draw(self.surface, 160, 167)
  self.cloud4:draw(self.surface, 296, 168)  -- V
  self.cloud5:draw(self.surface, 200, 142)  -- V
  self.cloud6:draw(self.surface, -23, 145) -- V
  self.mountain_top:draw(self.surface, 0, 179)
  self.night_fog:draw(self.surface, -430, 180)
  self.hill_left:draw(self.surface, 0, 198)
  self.hill_right:draw(self.surface, 248, 198)
  self.bird_sprite:draw(self.surface, self.bird_x, self.bird_y)
  self.bird_sprite1:draw(self.surface, self.bird1_x, self.bird1_y)
  
  self.menu_name_box_graphic:draw_region(0, 104, 146, 20, self.surface, 47, 45)
  
  -- Savegames container.
  self.background_img:draw(self.surface, 45, 38)
  self.title_text:draw(self.surface, 120, 54)

  -- Phase-specific draw method.
  local method_name = "draw_phase_" .. self.phase
  self[method_name](self)

  -- The menu makes 320*240 pixels, but dst_surface may be larger.
  local width, height = dst_surface:get_size()
  self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

function savegame_menu:draw_savegame(slot_index)

  local slot = self.slots[slot_index]
  slot.file:draw(self.surface, 73, 65 + slot_index * 17)
   
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 75)
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 92)
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 109)
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 133)
  if not self.is_copy_erase then
    self.file_box_erase:draw_region(0, 0, 64, 16, self.surface, 63, 150)
  end
  if self.draw_option_container then
    self.file_box_option:draw_region(0, 0, 64, 16, self.surface, 63, 174)
  end
  
   if sol.game.exists("save"..slot_index..".dat") then
     self.player_name_graphic:draw_region(0, 16, 108, 16, self.surface, 129, 75 + (17 *(slot_index - 1)))
   end
 slot.player_name_text:draw(self.surface, 136, 65 + slot_index * 17)
end

function savegame_menu:draw_savegame_cursor()
  local x, y
  x = 52
  if self.cursor_position < 4 then
    y = 58 + self.cursor_position * 17
  elseif self.cursor_position < 6 then
    if self.is_option_menu then
	y = 85 + self.cursor_position * 17
	else
    y = 65 + self.cursor_position * 17
	end
  elseif self.cursor_position == 6 then
    y = 175
  end
  self.cursor_sprite:draw(self.surface, x, y)
end

function savegame_menu:draw_savegame_number(slot_index)
  local slot = self.slots[slot_index]
  slot.file:draw(self.surface, 73, 65 + slot_index * 17)
  slot.number_img:set_text(slot_index)
  slot.number_img:draw(self.surface, 113, 65 + slot_index * 17)
end

function savegame_menu:draw_bottom_buttons()

  local x
  local y = 158
  if self.option1_text:get_text():len() > 0 then
    x = 57
	if self.is_option_menu then
	  self.option1_text:draw(self.surface, 71, 160)
	else
      self.option1_text:draw(self.surface, 77, 140)
	end
  end
  if self.option2_text:get_text():len() > 0 then
    x = 165
    self.option2_text:draw(self.surface, 77, 157)
  end
  if self.option3_text:get_text():len() > 0 then
    x = 165
    self.option3_text:draw(self.surface, 77, 181)
  end
end

function savegame_menu:read_savegames()

  self.slots = {}
  local font, font_size = sol.language.get_menu_font()
  for i = 1, 3 do
    local slot = {}
    slot.file_name = "save" .. i .. ".dat"
    slot.savegame = sol.game.load(slot.file_name)
    slot.number_img = sol.text_surface.create{
      font = font,
      font_size = 7,
    }
	
	slot.file = sol.text_surface.create{
      font = font,
      font_size = 7,
	  vertical_aligmenent = "center",
	  text_key = "selection_menu.file"
    }

    slot.player_name_text = sol.text_surface.create{
      font = font,
      font_size = 7,
    }
    if sol.game.exists(slot.file_name) then
      slot.player_name_text:set_text(slot.savegame:get_value("player_name"))

      -- Completion Percentage.
      if slot.savegame:get_value("b1699") then
        slot.percent_complete = sol.text_surface.create{ font = font, font_size = 10 }
        slot.percent_complete:set_text("["..self:calculate_percent_complete(slot.savegame).."%]")
      end
    end
    self.slots[i] = slot
  end
end

function savegame_menu:set_bottom_buttons(key1, key2, key3)

  if key1 ~= nil then
    self.option1_text:set_text_key(key1)
  else
    self.option1_text:set_text("")
  end

  if key2 ~= nil then
    self.option2_text:set_text_key(key2)
  else
    self.option2_text:set_text("")
  end
  
  if key3 ~= nil then
    self.option3_text:set_text_key(key3)
  else
    self.option3_text:set_text("")
  end
end

function savegame_menu:move_cursor_up()
  sol.audio.play_sound("menu/cursor_1")
  local cursor_position = self.cursor_position - 1
  if cursor_position == 0 and not self.is_copy_erase and self.draw_option_container then
    cursor_position = 6
  elseif cursor_position == 3 and ((self.phase == "confirm_copy" or self.phase == "confirm_erase" or self.phase == "display_quest") or not self.is_copy_erase and not self.draw_option_container) then
    cursor_position = 5 
  elseif cursor_position == 0 and (self.phase == "copy_file" or self.phase == "copy_which_file" or self.phase == "erase_file") then
    cursor_position = 4
  end
  self:set_cursor_position(cursor_position)
end

function savegame_menu:move_cursor_down()

  sol.audio.play_sound("menu/cursor_1")
  local cursor_position = self.cursor_position + 1
  
  if cursor_position == 7 then
    cursor_position = 1
  elseif cursor_position == 6 and ((self.phase == "confirm_copy" or self.phase == "confirm_erase" or self.phase == "display_quest") or not self.is_copy_erase and not self.draw_option_container) then
    cursor_position = 4
  elseif cursor_position == 5 and (self.phase == "copy_file" or self.phase == "copy_which_file" or self.phase == "erase_file") then
    cursor_position = 1
  end
  self:set_cursor_position(cursor_position)
end

function savegame_menu:set_cursor_position(cursor_position)

  self.cursor_position = cursor_position
  self.cursor_sprite:set_frame(0)  -- Restart the animation.
end

function savegame_menu:repeat_move_clouds()
  local width, height = self.surface:get_size()

  local c0 = self.cloud0:get_xy()
  local c1 = self.cloud1:get_xy()  
  local c2 = self.cloud2:get_xy()
  local c3 = self.cloud3:get_xy()
  local c4 = self.cloud4:get_xy()
  local c5 = self.cloud5:get_xy()
  local c6 = self.cloud6:get_xy()
  
  	self.cloud0:set_xy(self.cloud0:get_xy() + 1, 0)
    self.cloud1:set_xy(self.cloud1:get_xy() + 1, 0)
    self.cloud2:set_xy(self.cloud2:get_xy() + 1, 0)
    self.cloud3:set_xy(self.cloud3:get_xy() + 1, 0)
    self.cloud4:set_xy(self.cloud4:get_xy() + 1, 0)
    self.cloud5:set_xy(self.cloud5:get_xy() + 1, 0)
    self.cloud6:set_xy(self.cloud6:get_xy() + 1, 0)
	
  	if c0 >= 113 + math.random(10, 20) then
	  self.cloud0:set_xy(-260, 0)
	end
	if c1 >= 324 +  math.random(10, 30) then
	  self.cloud1:set_xy(-32, 0)
	end
	if c2 >= 314 then
	  self.cloud2:set_xy(-50, 0)
	end
	if c3 >= 160 + math.random(10, 20) then
	  self.cloud3:set_xy(-185, 0)
	end
	if c4 >= 30 + math.random(10, 20) then
	  self.cloud4:set_xy(-320, 0)
	end
	if c5 >= 120 then
	  self.cloud5:set_xy(-298, 0)
	end
	if c6 >= 335 + math.random(10, 20) then
	  self.cloud6:set_xy(-30, 0)
	end

  sol.timer.start(self, 100, function()
    self:repeat_move_clouds()
  end)
end

function savegame_menu:repeat_move_clouds_slow()
  local width, height = self.surface:get_size() 
  	
    local fog0 = self.night_fog:get_xy()
	self.night_fog:set_xy(self.night_fog:get_xy() + 1, 0)
	if fog0 >= 430 then
	  self.night_fog:set_xy(57, 0)
	end
  
  sol.timer.start(self, 300, function()
    self:repeat_move_clouds_slow()
  end)
end

function savegame_menu:repeat_move_bird()
  local width, height = self.surface:get_size()

  local b0 = self.bird_sprite:get_xy()
  local b1 = self.bird_sprite1:get_xy()

	self.bird_sprite:set_xy(self.bird_sprite:get_xy() + 1, 0)
	self.bird_sprite1:set_xy(self.bird_sprite:get_xy() + 1, 0)

	 if b0 >= 600 +  math.random(10, 30) then
	   self.bird_sprite:set_xy(math.random(-150, -100), math.random(-20, 40))
	   self.bird_x, self.bird_y =  math.random(-150, -100), math.random(-20, 20)
       
	 end
	 if b1 >= 700 +  math.random(10, 30) then
	   self.bird_sprite1:set_xy(math.random(-150, -100), math.random(-20, 40))
	   self.bird1_x, self.bird1_y = math.random(-200, -22), math.random(70, 0)
	 end

  sol.timer.start(self, 50, function()
    self:repeat_move_bird()
  end)
end

---------------------------
-- Phase "select a file" --
---------------------------
function savegame_menu:init_phase_select_file()
  self.draw_option_container = true
  self.phase = "select_file"
  self.title_text:set_text_key("selection_menu.phase.select_file")
  self:set_bottom_buttons("selection_menu.copy", "selection_menu.erase", "selection_menu.options")
end

function savegame_menu:key_pressed_phase_select_file(key)

  local handled = false
  if key == "space" or key == "return" then
    sol.audio.play_sound("menu/menu_open")
    if self.cursor_position == 6 then
      -- The user chooses "Options".
      self:init_phase_options()
    elseif self.cursor_position == 5 then
      -- The user chooses "Erase".
      self:init_phase_erase_file()
	elseif self.cursor_position == 4 then
      -- The user chooses "Erase".
      self:init_phase_copy_file()
    else
      -- The user chooses a savegame.
      local slot = self.slots[self.cursor_position]
      if sol.game.exists(slot.file_name) then
        -- The file exists: run it after a fade-out effect.
		self.selected_quest = self.cursor_position
        self:init_phase_display_quest()
      else
        -- It's a new savegame: choose the player's name.
        self:init_phase_choose_name()
      end
    end
    handled = true
  end

  return handled
end

function savegame_menu:joypad_button_pressed_phase_select_file(button)

  return self:key_pressed_phase_select_file("space")
end

function savegame_menu:direction_pressed_phase_select_file(direction8)

  local handled = true
  if direction8 == 6 then  -- Down.
    self:move_cursor_down()
  elseif direction8 == 2 then  -- Up.
    self:move_cursor_up()
  else
    handled = false
  end
  return handled
end

function savegame_menu:draw_phase_select_file()

  -- Savegame slots.
  for i = 1, 3 do
    self:draw_savegame(i)
  end

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()

  -- Save numbers.
  for i = 1, 3 do
    self:draw_savegame_number(i)
  end
end



-------------------------
-- Phase "copy a file" --
--------------------------
function savegame_menu:init_phase_copy_file()
  self.is_copy_erase = true
  self.draw_option_container = false
  self.phase = "copy_file"
  self.title_text:set_text_key("selection_menu.phase.copy_file")
  self:set_bottom_buttons("selection_menu.cancel", nil, nil)
end

function savegame_menu:key_pressed_phase_copy_file(key)

  local handled = true
  if key == "space" or key == "return" then
    if self.cursor_position == 4 then
      -- The user chooses "Cancel".
      sol.audio.play_sound("menu/letter_back")
	  self.is_copy_erase = false
	  self.draw_option_container = true
      self:init_phase_select_file()
    elseif self.cursor_position > 0 and self.cursor_position <= 3 then
      -- The user chooses a savegame to delete.
      local slot = self.slots[self.cursor_position]
      if not sol.game.exists(slot.file_name) then
        -- The savegame doesn't exist: error sound.
        sol.audio.play_sound("wrong")
      else
        sol.audio.play_sound("menu/menu_open")
		self.selected_file = self.cursor_position		
        self:init_phase_copy_which_file()
      end
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_copy_file(button)

  return self:key_pressed_phase_copy_file("space")
end

function savegame_menu:direction_pressed_phase_copy_file(direction8)

  local handled = true
  if direction8 == 6 then  -- Down.
    self:move_cursor_down()
  elseif direction8 == 2 then  -- Up.
    self:move_cursor_up()
  else
    handled = false
  end
  return handled
end

function savegame_menu:draw_phase_copy_file()

  -- Savegame slots.
  for i = 1, 3 do
    self:draw_savegame(i)
  end

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()

  -- Save numbers.
  for i = 1, 3 do
    self:draw_savegame_number(i)
  end
end

-------------------------
-- Phase "copy to which file" --
--------------------------
function savegame_menu:init_phase_copy_which_file()
  self.is_copy_erase = true
  self.draw_option_container = false
  self.phase = "copy_which_file"
  self.title_text:set_text_key("selection_menu.phase.copy_to")
  self:set_bottom_buttons("selection_menu.cancel", nil, nil)
end

function savegame_menu:key_pressed_phase_copy_which_file(key)

  local handled = true
  if key == "space" or key == "return" then
    if self.cursor_position == 4 then
      -- The user chooses "Cancel".
      sol.audio.play_sound("menu/letter_back")
	  self.is_copy_erase = false
	  self.draw_option_container = true
      self:init_phase_select_file()
    elseif self.cursor_position > 0 and self.cursor_position <= 3 then
      -- The user chooses a savegame to delete.
      local slot = self.slots[self.cursor_position]
      if not sol.game.exists(slot.file_name) then
        -- The savegame doesn't exist: error sound.
		self.is_copy_erase = false
		sol.audio.play_sound("menu/menu_open")
		self.target_file = self.cursor_position
        self:init_phase_confirm_copy()
      else
	    sol.audio.play_sound("error")
      end
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_copy_which_file(button)

  return self:key_pressed_phase_copy_file("space")
end

function savegame_menu:direction_pressed_phase_copy_which_file(direction8)

  local handled = true
  if direction8 == 6 then  -- Down.
    self:move_cursor_down()
  elseif direction8 == 2 then  -- Up.
    self:move_cursor_up()
  else
    handled = false
  end
  return handled
end

function savegame_menu:draw_phase_copy_which_file()

  -- Savegame slots.
  for i = 1, 3 do
    self:draw_savegame(i)
  end

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()

  -- Save numbers.
  for i = 1, 3 do
    self:draw_savegame_number(i)
  end
end

---------------------------
-- Phase "Are you sure?" --
---------------------------
function savegame_menu:init_phase_confirm_copy()
  self.is_copy_erase = false
  self.draw_option_container = false
  self.phase = "confirm_copy"
  self.title_text:set_text_key("selection_menu.phase.confirm_erase")
  self:set_bottom_buttons("selection_menu.big_no", "selection_menu.big_yes")
  self.save_number_to_erase = self.cursor_position
  self.cursor_position = 4  -- Select "no" by default.
end

function savegame_menu:key_pressed_phase_confirm_copy(key)

  local handled = true
  if (key == "space" or key == "return") and self.can_control then
   if self.cursor_position == 5 then
     local infile
	 local instr
	 local outfile
      -- The user chooses "yes".
	  --todo restore cursor position in option & erase
	  
	  sol.audio.play_sound("menu/fileselect_startcreating")
	  self.title_text:set_text_key("selection_menu.phase.copying_file")
	  self.can_control = false
	  infile = sol.file.open("save"..self.selected_file..".dat", "r")
      instr = infile:read("*a")
      infile:close()
	  
	  sol.timer.start(self, 2500, function()
      outfile = sol.file.open("save"..(self.target_file)..".dat", "w")
      outfile:write(instr)
      outfile:close()
	  
	  self:read_savegames()
	  
      sol.audio.play_sound("menu/fileselect_created")
	  self.title_text:set_text_key("selection_menu.phase.copying_file_done")
		
	  sol.timer.start(self, 2000, function()
  
	    self.is_copy_erase = false
		self.draw_option_container = true
		self.can_control = true
		self:set_cursor_position(4)
        self:init_phase_select_file()
		end)
	  end)
    elseif self.cursor_position == 4 then
      -- The user chooses "no".
      sol.audio.play_sound("menu/letter_back")
	  self.is_copy_erase = false
	  self.draw_option_container = true
      self:init_phase_select_file()
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_confirm_copy(button)

  return self:key_pressed_phase_confirm_erase("space")
end

function savegame_menu:direction_pressed_phase_confirm_copy(direction8)

  local handled = false
  if direction8 == 2 then
    self:move_cursor_up()
  elseif direction8 == 6 then
    self:move_cursor_down()
    handled = true
  end
  return handled
end

function savegame_menu:draw_phase_confirm_copy()

  -- Current savegame slot.
  self:draw_savegame(self.save_number_to_erase)
  self:draw_savegame_number(self.save_number_to_erase)

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()
end

--------------------------
-- Phase "erase a file" --
--------------------------
function savegame_menu:init_phase_erase_file()
  self.is_copy_erase = true
  self.draw_option_container = false
  self.phase = "erase_file"
  self.title_text:set_text_key("selection_menu.phase.erase_file")
  self:set_bottom_buttons("selection_menu.cancel", nil, nil)
  self:set_cursor_position(4)
end

function savegame_menu:key_pressed_phase_erase_file(key)

  local handled = true
  if key == "space" or key == "return" then
    if self.cursor_position == 4 then
      -- The user chooses "Cancel".
      sol.audio.play_sound("menu/letter_back")
	  self.is_copy_erase = false
	  self.draw_option_container = true
	  self:set_cursor_position(5)
      self:init_phase_select_file()
    elseif self.cursor_position > 0 and self.cursor_position <= 3 then
      -- The user chooses a savegame to delete.
      local slot = self.slots[self.cursor_position]
      if not sol.game.exists(slot.file_name) then
        -- The savegame doesn't exist: error sound.
        sol.audio.play_sound("wrong")
      else
        -- The savegame exists: confirm deletion.
        sol.audio.play_sound("menu/menu_open")
		self.is_copy_erase = false
        self:init_phase_confirm_erase()
      end
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_erase_file(button)

  return self:key_pressed_phase_copy_file("space")
end

function savegame_menu:direction_pressed_phase_erase_file(direction8)

  local handled = true
  if direction8 == 6 then  -- Down.
    self:move_cursor_down()
  elseif direction8 == 2 then  -- Up.
    self:move_cursor_up()
  else
    handled = false
  end
  return handled
end

function savegame_menu:draw_phase_erase_file()

  -- Savegame slots.
  for i = 1, 3 do
    self:draw_savegame(i)
  end

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()

  -- Save numbers.
  for i = 1, 3 do
    self:draw_savegame_number(i)
  end
end

---------------------------
-- Phase "Are you sure?" --
---------------------------
function savegame_menu:init_phase_confirm_erase()
  self.is_copy_erase = false
  self.draw_option_container = false
  self.phase = "confirm_erase"
  self.title_text:set_text_key("selection_menu.phase.confirm_erase")
  self:set_bottom_buttons("selection_menu.big_no", "selection_menu.big_yes")
  self.save_number_to_erase = self.cursor_position
  self.cursor_position = 4  -- Select "no" by default.
end

function savegame_menu:key_pressed_phase_confirm_erase(key)

  local handled = true
  if (key == "space" or key == "return") and self.can_control then
   if self.cursor_position == 5 then
      -- The user chooses "yes".
      sol.audio.play_sound("menu/fileselect_erase0")
	  self.title_text:set_text_key("selection_menu.phase.erasing_file")
	  self.can_control = false

	  sol.timer.start(self, 1500, function()
	    self.title_text:set_text_key("selection_menu.phase.erasing_file_done")
		sol.audio.play_sound("menu/fileselect_erase1")
		local slot = self.slots[self.save_number_to_erase]
        sol.game.delete(slot.file_name)
        self:read_savegames()
	    sol.timer.start(self, 2000, function()
		  self.can_control = true
		  self.cursor_position = 5
          self:init_phase_select_file()
	    end)
	  end)
    elseif self.cursor_position == 4 then
      -- The user chooses "no".
      sol.audio.play_sound("menu/letter_back")
	  self:set_cursor_position(5)
      self:init_phase_select_file()
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_confirm_erase(button)
  return self:key_pressed_phase_confirm_erase("space")
end

function savegame_menu:direction_pressed_phase_confirm_erase(direction8)

  local handled = false
  if direction8 == 2 and self.can_control then  
    self:move_cursor_up()
  elseif direction8 == 6 and self.can_control then
    self:move_cursor_down()
    handled = true
  end
  return handled
end

function savegame_menu:draw_phase_confirm_erase()

  -- Current savegame slot.
  self:draw_savegame(self.save_number_to_erase)
  self:draw_savegame_number(self.save_number_to_erase)

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()
end


---------------------------
-- Phase Display quest progression
---------------------------
function savegame_menu:init_phase_display_quest()
  local slot = self.slots[self.selected_quest]
  self.savegame = slot.savegame

  self.is_copy_erase = false
  self.draw_option_container = false
  self.phase = "display_quest"
  self.title_text:set_text_key("selection_menu.phase.start_this")
  self:set_bottom_buttons("selection_menu.no", "selection_menu.yes")
  self.cursor_position = 4  -- Select "no" by default.
  
  local font = sol.language.get_menu_font()
  self.hero_name = sol.text_surface.create({
    font = font,
	vertical_aligmenent = "left",
    font_size = "7",
	text = self.savegame:get_value("player_name"),
  })
  
  self.number_img = sol.text_surface.create{
      font = font,
      font_size = 7,
	  text = self.selected_quest,
  }
	
  self.file = sol.text_surface.create{
      font = font,
      font_size = 7,
	  vertical_aligmenent = "center",
	  text_key = "selection_menu.file"
  }
    
  local hearts_class = require("scripts/hud/hearts")
  self.hearts_view = hearts_class:new(self.savegame)
  
  self.hero_sprite = sol.sprite.create("hero/tunic"..self.savegame:get_ability("tunic") or 1)
  self.hero_sprite:set_animation("walking")
  self.hero_sprite:set_direction(3)
  
  if self.savegame:get_ability("shield") > 0 then
  self.shield_sprite = sol.sprite.create("hero/shield"..self.savegame:get_ability("shield") or 1)
  self.shield_sprite:set_animation("walking")
  self.shield_sprite:set_frame_delay(50)
  self.shield_sprite:set_direction(3)
  end
  
  self.item_sprite = sol.sprite.create("entities/items")
  
end

function savegame_menu:key_pressed_phase_display_quest(key)

  local handled = true
  if (key == "space" or key == "return") and self.can_control then
   if self.cursor_position == 5 then
      -- The user chooses "yes".
	    sol.audio.play_sound("menu/fileselect_start")
        self.finished = true
		self.can_control = false
		sol.timer.start(self, 800, function()
          self.surface:fade_out()
		  sol.audio.play_music(nil)
          sol.timer.start(self, 2000, function()
            sol.menu.stop(self)
			self.can_control = true
	        sol.main:start_savegame(self.savegame)
          end)
		end)
    elseif self.cursor_position == 4 then
      -- The user chooses "no".
      sol.audio.play_sound("menu/letter_back")
	  self:set_cursor_position(self.selected_quest)
      self:init_phase_select_file()
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_display_quest(button)

  return self:key_pressed_phase_display_quest("space")
end

function savegame_menu:direction_pressed_phase_display_quest(direction8)

  local handled = false
  if direction8 == 2 then  
    self:move_cursor_up()
  elseif direction8 == 6 then
    self:move_cursor_down()
    handled = true
  end
  return handled
end

function savegame_menu:draw_phase_display_quest()
  local y = 115
  -- Current savegame slot.
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 75)
  self.file_box_graphic:draw_region(0, 0, 64, 16, self.surface, 63, 133)
  self.file_box_erase:draw_region(0, 0, 64, 16, self.surface, 63, 150)
  
  self.file_box_graphic:draw_region(0, 32, 177, 56, self.surface, 62, 75)
  self.hero_name:draw(self.surface, 136, 82)
  self.hero_sprite:draw(self.surface, 81, 116)
  
  local dst_position = {
  {67, 13, 121},
  {80, 14, 134},
  {94, 15, 148},
  {187, 15, 76}, 
  {202, 15, 91},
  {217, 15, 106},
  {111, 16, 0},
  {127, 15, 16},
  {142, 15, 31},
  {157, 15, 46},
  {172, 15, 61},
  }
 
   for i, dst_positions in ipairs(dst_position) do
     if self.savegame:get_value("dungeon_"..i.."_finished") then
        self.file_box_graphic:draw_region(dst_positions[3], 88, dst_positions[2] , 16, self.surface, dst_positions[1], y)
     end
   end
  
  if self.savegame:get_ability("shield") > 0 then
    self.shield_sprite:draw(self.surface, 80, 116)
  end
  
  self.hearts_view:set_dst_position(117, 96)
  self.hearts_view:rebuild_surface()
  self.hearts_view:on_draw(self.surface)
   
 
 self.file:draw(self.surface, 73, 82)
 self.number_img:draw(self.surface, 113, 82)

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  self:draw_savegame_cursor()
end


----------------------
-- Phase "options" --
----------------------
function savegame_menu:init_phase_options(savegame)

  self.phase = "options"
  self.title_text:set_text_key("selection_menu.phase.options")
  self.modifying_option = false
  self.options_cursor_position = 1
  self.is_option_menu = true

  -- Option texts and values.
  self.options = {
    {
      name = "language",
      values = sol.language.get_languages(),
      initial_value = sol.language.get_language()
    },
    {
      name = "video_mode",
      values = sol.video.get_modes(),
      initial_value = sol.video.get_mode()
    },
    {
      name = "music_volume",
      values = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100},
      initial_value = math.floor((sol.audio.get_music_volume() + 5) / 10) * 10
    },
    {
      name = "sound_volume",
      values = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100},
      initial_value = math.floor((sol.audio.get_sound_volume() + 5) / 10) * 10
    }
  }

  local font, font_size = sol.language.get_menu_font()
  for _, option in ipairs(self.options) do

    option.current_index = nil

    -- Text surface of the label.
    option.label_text = sol.text_surface.create{
      font = font,
	  vertical_aligmenent = "center",
      font_size = font_size,
      text_key = "selection_menu.options." .. option.name
    }

    -- Text surface of the value.
    option.value_text = sol.text_surface.create{
      font = font,
      font_size = font_size,
      horizontal_alignment = "right"
    }
  end

  for _, option in ipairs(self.options) do
    -- Initial value.
    for i, value in ipairs(option.values) do
      if value == option.initial_value then
	self:set_option_value(option, i)
      end
    end
  end

  -- Sprites.
  self.left_arrow_sprite = sol.sprite.create("menus/arrow")
  self.left_arrow_sprite:set_animation("blink")
  self.left_arrow_sprite:set_direction(2)
  self.right_arrow_sprite = sol.sprite.create("menus/arrow")
  self.right_arrow_sprite:set_animation("blink")
  self.right_arrow_sprite:set_direction(0)

  self:set_bottom_buttons("selection_menu.back", nil, nil)
  self:set_options_cursor_position(1)
end

function savegame_menu:key_pressed_phase_options(key)

  local handled = true
  if key == "space" or key == "return" then
    if self.options_cursor_position > #self.options then
      -- Back.
      sol.audio.play_sound("menu/letter_back")
	  self.is_option_menu = false
	  self:set_cursor_position(6)
      self:init_phase_select_file()
    else
      -- Set an option.
      local option = self.options[self.options_cursor_position]
      if not self.modifying_option then
	sol.audio.play_sound("menu/letter_add")
	self.left_arrow_sprite:set_frame(0)
	self.right_arrow_sprite:set_frame(0)
	option.label_text:set_color{255, 255, 255}
	option.value_text:set_color{255, 255, 0}
	self.title_text:set_text_key("selection_menu.phase.options.changing")
	self.modifying_option = true
      else
	sol.audio.play_sound("/menu/modified")
	option.label_text:set_color{255, 255, 0}
	option.value_text:set_color{255, 255, 255}
	self.left_arrow_sprite:set_frame(0)
	self.right_arrow_sprite:set_frame(0)
	self.title_text:set_text_key("selection_menu.phase.options")
	self.modifying_option = false
      end
    end
  else
    handled = false
  end
  return handled
end

function savegame_menu:joypad_button_pressed_phase_options(button)
  return self:key_pressed_phase_options("space")
end

function savegame_menu:direction_pressed_phase_options(direction8)

  local handled = false
  if not self.modifying_option then
    -- Just moving the options cursor (not modifying any option).

    if direction8 == 2 then  -- Up.
      sol.audio.play_sound("menu/cursor_1")
      self.left_arrow_sprite:set_frame(0)
      local position = self.options_cursor_position - 1
      if position == 0 then
        position = #self.options + 1
      end
      self:set_options_cursor_position(position)
      handled = true

    elseif direction8 == 6 then  -- Down.
      sol.audio.play_sound("menu/cursor_1")
      self.left_arrow_sprite:set_frame(0)
      local position = self.options_cursor_position + 1
      if position > #self.options + 1 then
        position = 1
      end
      self:set_options_cursor_position(position)
      handled = true
    end

  else
    -- An option is currently being modified.

    if direction8 == 0 then  -- Right.
      local option = self.options[self.options_cursor_position]
      local index = (option.current_index % #option.values) + 1
      self:set_option_value(option, index)
      sol.audio.play_sound("menu/option_modifyvalue")
      self.left_arrow_sprite:set_frame(0)
      self.right_arrow_sprite:set_frame(0)
      handled = true

    elseif direction8 == 4 then  -- Left.
      local option = self.options[self.options_cursor_position]
      local index = (option.current_index + #option.values - 2) % #option.values + 1
      self:set_option_value(option, index)
      sol.audio.play_sound("menu/option_modifyvalue")
      self.left_arrow_sprite:set_frame(0)
      self.right_arrow_sprite:set_frame(0)
      handled = true

    end
  end
  return handled
end

function savegame_menu:draw_phase_options()

  -- All options.
  for i, option in ipairs(self.options) do
    local y = 65 + i * 17
    option.label_text:draw(self.surface, 70, y)
    option.value_text:draw(self.surface, 266, y)
  end

  -- Bottom buttons.
  self:draw_bottom_buttons()

  -- Cursor.
  if self.options_cursor_position > #self.options then
    -- The cursor is on the bottom button.
    self:draw_savegame_cursor()
  else
    -- The cursor is on an option line.
    local y = 59 + self.options_cursor_position * 17
    if self.modifying_option then
      local option = self.options[self.options_cursor_position]
      local width, _ = option.value_text:get_size()
      self.left_arrow_sprite:draw(self.surface, 256 - width, y)
      self.right_arrow_sprite:draw(self.surface, 268, y)
    else
      self.right_arrow_sprite:draw(self.surface, 54, y)
    end
  end
end

function savegame_menu:set_options_cursor_position(position)

  if self.options_cursor_position <= #self.options then
    -- An option line was previously selected.
    local option = self.options[self.options_cursor_position]
    option.label_text:set_color{255, 255, 255}
  end

  self.options_cursor_position = position
  if position > #self.options then
    self:set_cursor_position(4)
  end

  if position <= #self.options then
    -- An option line is now selected.
    local option = self.options[self.options_cursor_position]
    option.label_text:set_color{255, 255, 0}
  end
end

-- Sets the value of an option.
function savegame_menu:set_option_value(option, index)

  if option.current_index ~= index then
    option.current_index = index
    local value = option.values[index]

    if option.name == "language" then
      option.value_text:set_text(sol.language.get_language_name(value))
      if value ~= sol.language.get_language() then
	sol.language.set_language(value)
	self:reload_options_strings()
      end

    elseif option.name == "video_mode" then
      option.value_text:set_text(value)
      sol.video.set_mode(value)

    elseif option.name == "music_volume" then
      option.value_text:set_text(value)
      sol.audio.set_music_volume(value)

    elseif option.name == "sound_volume" then
      option.value_text:set_text(value)
      sol.audio.set_sound_volume(value)
    end
  end
end

-- Reloads all strings displayed on the menu.
-- This function is called when the language has just been changed.
function savegame_menu:reload_options_strings()

  local menu_font, menu_font_size = sol.language.get_menu_font()
  -- Update the label of each option.
  for _, option in ipairs(self.options) do

    option.label_text:set_font(menu_font)
    option.label_text:set_font_size(menu_font_size)
    option.value_text:set_font(menu_font)
    option.value_text:set_font_size(menu_font_size)
    option.label_text:set_text_key("selection_menu.options." .. option.name)

    -- And the value of the video mode.
    if option.name == "video_mode" and option.current_index ~= nil then
      local mode = option.values[option.current_index]
      option.value_text:set_text(mode)
    end
  end

  -- Other menu elements
  self.title_text:set_text_key("selection_menu.phase.options")
  self.title_text:set_font(menu_font)
  self.title_text:set_font_size(menu_font_size)
  self.option1_text:set_font(menu_font)
  self.option1_text:set_font_size(menu_font_size)
  self.option2_text:set_font(menu_font)
  self.option2_text:set_font_size(menu_font_size)
  self:set_bottom_buttons("selection_menu.back", nil, nil)
  self:read_savegames()  -- To update "- Empty -" mentions.
end

------------------------------
-- Phase "choose your name" --
------------------------------
function savegame_menu:init_phase_choose_name()

  self.phase = "choose_name"
  self.title_text:set_text_key("selection_menu.phase.choose_name")
  self.cursor_sprite:set_animation("letters")
  self.player_name = ""
  local font, font_size = sol.language.get_menu_font()
  self.player_name_text = sol.text_surface.create{
    font = font,
    font_size = font_size,
  }
  self.letter_cursor = { x = 0, y = 0 }
  self.letters_img = sol.surface.create("menus/selection_menu_letters.png")
  self.name_arrow_sprite = sol.sprite.create("menus/arrow")
  self.name_arrow_sprite:set_direction(0)
  self.can_add_letter_player_name = true
end

function savegame_menu:key_pressed_phase_choose_name(key)

  local handled = false
  local finished = false
  if key == "return" and self.can_control then
    -- Directly validate the name.
    finished = self:validate_player_name()
    handled = true

  elseif (key == "space" or key == "c") and self.can_control then

    if self.can_add_letter_player_name then
      -- Choose a letter
      finished = self:add_letter_player_name()
      self.player_name_text:set_text(self.player_name)
      self.can_add_letter_player_name = false
      sol.timer.start(self, 300, function()
        self.can_add_letter_player_name = true
      end)
      handled = true
    end
  end

  if finished then
    self:init_phase_select_file()
  end

  return handled
end

function savegame_menu:joypad_button_pressed_phase_choose_name(button)

  return self:key_pressed_phase_choose_name("space")
end

function savegame_menu:direction_pressed_phase_choose_name(direction8)

  local handled = true
  if direction8 == 0 and self.can_control then  -- Right.
    sol.audio.play_sound("menu/cursor_1")
    self.letter_cursor.x = (self.letter_cursor.x + 1) % 13

  elseif direction8 == 2 and self.can_control then  -- Up.
    sol.audio.play_sound("menu/cursor_1")
    self.letter_cursor.y = (self.letter_cursor.y + 4) % 5

  elseif direction8 == 4 and self.can_control then  -- Left.
    sol.audio.play_sound("menu/cursor_1")
    self.letter_cursor.x = (self.letter_cursor.x + 12) % 13

  elseif direction8 == 6 and self.can_control then  -- Down.
    sol.audio.play_sound("menu/cursor_1")
    self.letter_cursor.y = (self.letter_cursor.y + 1) % 5

  else
    handled = false
  end
  return handled
end

function savegame_menu:draw_phase_choose_name()

  -- Letter cursor.
  self.cursor_sprite:draw(self.surface,
      51 + 16 * self.letter_cursor.x,
      93 + 18 * self.letter_cursor.y)

  -- Name and letters.
  self.name_arrow_sprite:draw(self.surface, 57, 76)
  self.player_name_text:draw(self.surface, 67, 83)
  self.letters_img:draw(self.surface, 57, 98)
end

function savegame_menu:add_letter_player_name()

  local size = self.player_name:len()
  local letter_cursor = self.letter_cursor
  local letter_to_add = nil
  local finished = false

  if letter_cursor.y == 0 then  -- Uppercase letter from A to M.
    letter_to_add = string.char(string.byte("A") + letter_cursor.x)

  elseif letter_cursor.y == 1 then  -- Uppercase letter from N to Z.
    letter_to_add = string.char(string.byte("N") + letter_cursor.x)

  elseif letter_cursor.y == 2 then  -- Lowercase letter from a to m.
    letter_to_add = string.char(string.byte("a") + letter_cursor.x)

  elseif letter_cursor.y == 3 then  -- Lowercase letter from n to z.
    letter_to_add = string.char(string.byte("n") + letter_cursor.x)

  elseif letter_cursor.y == 4 then  -- Digit or special command.
    if letter_cursor.x <= 9 then
      -- Digit.
      letter_to_add = string.char(string.byte("0") + letter_cursor.x)
    else
      -- Special command.

      if letter_cursor.x == 10 then  -- Remove the last letter.
        if size == 0 then
          sol.audio.play_sound("menu/letter_back")
        else
          sol.audio.play_sound("menu/letter_back")
          self.player_name = self.player_name:sub(1, size - 1)
        end

      elseif letter_cursor.x == 11 then  -- Validate the choice.
	    self.can_control = false
        finished = self:validate_player_name()

      elseif letter_cursor.x == 12 then  -- Cancel.
        sol.audio.play_sound("menu/letter_back")
		self.cursor_sprite:set_animation("blink")
        finished = true
      end
    end
  end

  if letter_to_add ~= nil then
    -- A letter was selected.
    if size < 16 then
      sol.audio.play_sound("menu/letter_add")
      self.player_name = self.player_name .. letter_to_add
    else
      sol.audio.play_sound("menu/letter_back")
    end
  end

  return finished
end

function savegame_menu:validate_player_name()

  if self.player_name:len() == 0 then
    sol.audio.play_sound("menu/letter_back")
	self.can_control = true
    return false
  else
    self.can_control = false
  end
  
  sol.audio.play_sound("menu/fileselect_startcreating")
  self.title_text:set_text_key("selection_menu.phase.creating_file")
  
  sol.timer.start(self, 3500, function()
    sol.audio.play_sound("menu/fileselect_created")
	self.title_text:set_text_key("selection_menu.phase.created_file")
	local savegame = self.slots[self.cursor_position].savegame
	self:set_initial_values(savegame)
	savegame:save()
	self:read_savegames()
	sol.timer.start(self, 2000, function()
	  self.can_control = true
	  self.cursor_sprite:set_animation("blink")
	  self:init_phase_select_file()
	end)
  end)
  
end


function savegame_menu:set_initial_values(savegame)
  savegame:set_value("player_name", self.player_name)

  savegame:set_starting_location("cutscene/intro", "default")
  savegame:set_value("old_volume", sol.audio.get_music_volume())
  savegame:set_value("item_cloak_darkness_state", 0)
	
  savegame:set_value("item_saved_tunic", savegame:get_ability("tunic"))
  savegame:set_value("item_saved_sword", savegame:get_ability("sword"))
  savegame:set_value("item_saved_shield", savegame:get_ability("shield"))

  savegame:set_value("item_saved_kb_action", savegame:get_value("_keyboard_action"))
  savegame:set_value("item_1_kb_slot", savegame:get_value("_keyboard_item_1"))
  savegame:set_value("item_2_kb_slot", savegame:get_value("_keyboard_item_2"))

  savegame:set_value("item_saved_jp_action", savegame:get_value("_joypad_action"))
  savegame:set_value("item_1_jp_slot", savegame:get_value("_joypad_item_1"))
  savegame:set_value("item_2_jp_slot", savegame:get_value("_joypad_item_2"))	

  -- Initially give 3 hearts, the first tunic and the first wallet.
  savegame:set_max_life(12)
  savegame:set_life(savegame:get_max_life())
  savegame:set_value("i1025",0)
  savegame:set_value("i1024",0)
 
  savegame:get_item("tunic"):set_variant(1)
  savegame:set_ability("tunic", 1)
  savegame:get_item("rupee_bag"):set_variant(1)
end

return savegame_menu