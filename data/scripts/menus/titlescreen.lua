local title_screen = {}
local savegame_menu = require("scripts/menus/savegames")

local sparkle_position_x = {
  [0] = 85,
  [1] = 121,
  [2] = 143,
  [3] = 166,
  [4] = 85,
  [5] = 185,
  [6] = 195,
  [7] = 140,
  [8] = 176,
  [9] = 179,
  [10] = 84,
  [11] = 184,
  [12] = 200,
  [13] = 203,
  [14] = 198,
  [15] = 122,
}

local sparkle_position_y = {
  [0] = 45,
  [1] = 77,
  [2] = 47,
  [3] = 65,
  [4] = 45,
  [5] = 40,
  [6] = 75,
  [7] = 55,
  [8] = 50,
  [9] = 75,
  [10] = 90,
  [11] = 72,
  [12] = 35,
  [13] = 60,
  [14] = 78,
  [15] = 36,
}


function title_screen:on_started()
  local number
  self.sprite_sparkle = sol.sprite.create("menus/title_screen/sparkle")
  self.sprite_sword = sol.surface.create("menus/title_screen/title_sword.png")
  self.title_border = sol.surface.create("menus/title_screen/title_borders.png")
  self.game_name = sol.surface.create("menus/title_screen/title_screen_zelda_name.png")
  self.game_name_effect = sol.surface.create("menus/title_screen/title_screen_zelda_name_ef0.png")
  self.title_screen_logo_img = sol.surface.create("menus/title_screen/title_logo.png")
  
  local function generate_random()
    number = math.random(0, 14)
  end
  generate_random()
  
  self.surface = sol.surface.create(320, 240)
  self.surface:fill_color({0, 0, 0})
  self.surface:fade_out(80, function() self.can_press_key = true end)
  self.sprite_sparkle:set_xy(sparkle_position_x[number], sparkle_position_y[number])
  
  self.draw_title_name = false
  self.draw_press_space = false
  self.draw_copyright = false
  self.can_press_key = false
  self.draw_game_name = false
  self.draw_game_name_ef0 = false
  self.state = 0
  self.sparkle_state = 0
  
  self.website_img = sol.text_surface.create{
    font = "lttp",
    font_size = 14,
    text_key = "title_screen.website",
    horizontal_alignment = "center"
  }

  self.press_space_img = sol.text_surface.create{
    font = "lttp",
    font_size = 14,
    text_key = "title_screen.press_space",
    horizontal_alignment = "center",
	color = {255, 50, 50}
  }
  
  self.sprite_sword:set_xy(149, -128)
  
  function title_screen.sprite_sparkle:on_animation_finished()
    if sol.menu.is_started(title_screen) then
      generate_random()
      self:set_xy(sparkle_position_x[number], sparkle_position_y[number])
	  self:set_animation("0")
	end
  end
end

function title_screen:move_sword()
  local movement = sol.movement.create("target")
  movement:set_speed(500)
  movement:set_target(85, 0)
  movement:start(self.sprite_sword, function()
    sol.audio.play_sound("menu/title_screen_sword_placed")
  end)
end

function title_screen:on_command_pressed(command)
  if command == "action" then
    if self.state == 0 and self.can_press_key then
     self:draw_parts(command_pressed)
    elseif self.state == 1 and self.can_press_key then
	 self.state = 2
     sol.audio.play_sound("scene/title/press_start_2")
     sol.main.game:fade_audio(0, 10)
	 sol.main.game:set_item_on_use(true)
     self.surface:fade_in(40, function()
	   sol.main.game:set_pause_allowed(false)
	   sol.main.game.building_file_select = true
       sol.menu.start(sol.main, savegame_menu)
       sol.audio.set_music_volume(90)
	   sol.menu.stop(self)
       sol.timer.stop_all(self)
     end)
    end
  end 
return true
end

function title_screen:switch_press_space()
  self.press_space_img:fade_in(40, function()
    self.press_space_img:fade_out(40, function()
      self:switch_press_space()
    end)
  end)
end

function title_screen:wait_time_before_keypress() 
  self.can_press_key = false
  sol.timer.start(self, 500, function()
    self.can_press_key = true
  end)
end

sol.timer.start(title_screen, 8000, function()
  if not title_screen.draw_title_name then
    title_screen.draw_title_name = true       
	title_screen.sprite_sparkle:fade_in(60)
    title_screen.title_screen_logo_img:fade_in(60, function()
      title_screen:move_sword()
	  if not title_screen.draw_game_name_ef0 then
        title_screen.draw_game_name_ef0 = true
	    title_screen.game_name_effect:fade_in(50, function()
		  if not title_screen.draw_game_name then
		    title_screen.draw_game_name = true
		    title_screen.game_name:fade_in(20)
		  end
		end)
	  end
      if not title_screen.draw_copyright then
        title_screen.draw_copyright = true
        title_screen.website_img:fade_in(60, function()
          if not title_screen.draw_press_space then
            title_screen.draw_press_space = true
            title_screen:switch_press_space()
            title_screen.state = 1
          end
        end)
      end
    end)
   end
end)

function title_screen:draw_parts(typeof)
  self.state = 1
  self:wait_time_before_keypress() 
  if not self.draw_title_name then
    self.draw_title_name = true
    self:move_sword()
	title_screen.sprite_sparkle:fade_in(10)
    self.title_screen_logo_img:fade_in(10)
  end
  if not self.draw_copyright then
    self.draw_copyright = true
    self.website_img:fade_in(10)
  end
  if not self.draw_press_space then
    self.draw_press_space = true
    self:switch_press_space()
  end
  if not self.draw_game_name then
    self.draw_game_name = true
	self.game_name:fade_in(10)
  end
end

function title_screen:on_draw(dst_surface)
  self.title_border:draw(dst_surface, 0, 0)
  if self.draw_title_name then
    self.sprite_sword:draw(dst_surface, 0, 0)
    self.title_screen_logo_img:draw(dst_surface, 88, 30)
    self.sprite_sparkle:draw(dst_surface, 0, 0)
    if self.draw_copyright then
      self.website_img:draw(dst_surface, 160, 226) 
    end
    if self.draw_press_space then
      self.press_space_img:draw(dst_surface, 160, 200)
    end
	if self.draw_game_name_ef0 then
	  self.game_name_effect:draw(dst_surface, 124, 89)
	end
	if self.draw_game_name then
	  self.game_name:draw(dst_surface, 124, 89)
	end
  end
  self.surface:draw(dst_surface, 0, 0)
end

return title_screen