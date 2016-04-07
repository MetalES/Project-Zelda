local game = ...
local game_over_menu = {}  -- The game-over menu.

local clock_was_enabled

local music -- Music played before the game over
local background_img
local hero_was_visible
local hero_dead_sprite
local hero_dead_x, hero_dead_y
local fade_sprite
local fairy_sprite
local cursor_position
local state

local draw_game_over, draw_game_over_ef = false
local game_over_ef = sol.surface.create("menus/game_over.png")
local game_over = sol.surface.create("menus/game_over.png")

-- state can be one of:
-- "waiting_start": The game-over scene will start soon.
-- "closing_game": Fade-out on the game screen.
-- "red_screen": Red screen during a small delay.
-- "opening_menu": Fade-in on the game-over menu.
-- "saved_by_fairy": The player is being saved by a fairy.
-- "waiting_end": The game will be resumed soon.
-- "resume_game": The game can be resumed.
-- "menu": The player can choose an option in the game-over menu.
-- "finished": An action was validated in the menu.

function game:on_game_over_started()
  sol.menu.start(game:get_map(), game_over_menu)
end

function game_over_menu:restore_music()
 local map = game:get_map()
 if map:get_world() == "field" then
   local audio = require("scripts/gameplay/audio/hyrule_field_audio_mgr")
   audio:determine_partition()
 else
   sol.audio.play_music(music)
 end
end

function game_over_menu:on_started()
  local tunic = game:get_ability("tunic")
  local hero = game:get_hero()
  local map = game:get_map()
  
  clock_was_enabled = game:was_clock_enabled()
  
  game:set_hud_enabled(false)
  game:show_cutscene_bars(true)
  game:fade_audio(0, 10) -- fade out the audio.
  
  if clock_was_enabled then
    game:set_clock_enabled(false)
  end
  
  state = "waiting_start"
  music = sol.audio.get_music()

  hero:set_animation("hurt")
  hero:get_sprite():set_ignore_suspend(true)
  hero:get_sprite():set_paused(true)
  
  fairy_sprite = sol.sprite.create("entities/items")
  fairy_sprite:set_animation("fairy")
 
  local camera_x, camera_y = map:get_camera_position()
  local hero_x, hero_y = hero:get_position()
  hero_dead_x = hero_x - camera_x
  hero_dead_y = hero_y - camera_y

  sol.timer.start(self, 1000, function()
    state = "closing_game"
    sol.audio.stop_music()

	if state == "closing_game" then
      sol.audio.play_sound("hero_dying")
      hero:get_sprite():set_paused(false)
      hero:set_animation("dying")

      local bottle_with_fairy = game:get_first_bottle_with(6)
      if bottle_with_fairy ~= nil then
        -- Has a fairy.
        game:set_hud_enabled(true)
        state = "saved_by_fairy"
        -- Make the bottle empty.
        bottle_with_fairy:set_variant(1)
        fairy_sprite:set_xy(hero_dead_x + 12, hero_dead_y + 21)
        local movement = sol.movement.create("target")
        movement:set_target(240, 22)
        movement:set_speed(96)
		movement:start(fairy_sprite, function()
          state = "waiting_end"
          game:add_life(7 * 4)  -- Restore 7 hearts.
          sol.timer.start(self, 1000, function()
            state = "resume_game"
            -- restore music
            game:stop_game_over()
            sol.menu.stop(self)
          end)
        end)
      else
        -- No fairy: game over.
	    
	    sol.timer.start(self, 4500, function() 

		  sol.timer.start(500, function()
		    self:spawn_letter()
		  end)

		  sol.timer.start(1500, function()
		    state = "fade_screen"
			self.surface = sol.surface.create(320, 240)
			self.surface:fill_color({0, 0, 0})
			self.surface:fade_in(200)
		  end)
		  sol.audio.set_music_volume(game:get_value("old_volume"))
	      sol.audio.play_music("menu_game_over", false)
          state = "menu"
          fairy_sprite:set_xy(76, 112)  -- Cursor.
          cursor_position = 0
	    end)
      end
    end
  end)
end

function game_over_menu:spawn_letter()
  draw_game_over_ef = true
  
  game_over_ef:fade_in(120, function()
    game_over_ef:fade_out(120, function() draw_game_over_ef = false end)
	draw_game_over = true
	game_over:fade_in(120, function() sol.timer.start(1000, function() game_over:fade_out(120, function() draw_game_over = false sol.timer.start(1000, function() state = "choose_1" end) end) end) end)
  end)

end

function game_over_menu:on_finished()

  local hero = game:get_hero()
  if hero ~= nil then
    hero:set_visible(hero_was_visible)
  end
  music = nil
  -- background_img = nil
  fairy_sprite = nil
  cursor_position = nil
  state = nil
  sol.timer.stop_all(self)
  
 
  
end

local black = {0, 0, 0}
local red = {224, 32, 32}

function game_over_menu:on_draw(dst_surface)

  if state == "fade_screen" or state == "choose_1" or state == "choose_2" then
    self.surface:draw(dst_surface, 0, 0)
  end  
  
  if draw_game_over_ef then
    game_over_ef:draw_region(0, 16, 108, 16, dst_surface, 106, 96)
  end
  
  if draw_game_over then 
	game_over:draw_region(0, 0, 108, 16, dst_surface, 106, 96)
  end

  if state == "menu" or state == "finished" then
    -- background_img:draw(dst_surface)
    -- fairy_sprite:draw(dst_surface)
  elseif state ~= "resume_game" then
    if state == "saved_by_fairy" then
      fairy_sprite:draw(dst_surface)
    end
  end
end

function game_over_menu:on_command_pressed(command)

  if state ~= "choose_1" then
    -- Commands are not available during the game-over opening animations.
    return
  end

  if command == "down" then
    sol.audio.play_sound("cursor")
    cursor_position = (cursor_position + 1) % 4

  elseif command == "up" then
    sol.audio.play_sound("cursor")
    cursor_position = (cursor_position + 3) % 4
    
  elseif command == "action" or command == "attack" then

    state = "finished"
    sol.audio.play_sound("danger")
    game:set_hud_enabled(false)
    game:add_life(7 * 4)  -- Restore 7 hearts.
	

    if cursor_position == 0 then
      -- Save and continue.
      game:save()
      game:start()
    elseif cursor_position == 1 then
      -- Save and quit.
      game:save()
      sol.main.reset()
    elseif cursor_position == 2 then
      -- Continue without saving.
      game:start()
    elseif cursor_position == 3 then
      -- Quit without saving.
      sol.main.reset()
    end
  end
  
  local fairy_x, fairy_y = fairy_sprite:get_xy()
  fairy_y = 112 + cursor_position * 16
  fairy_sprite:set_xy(fairy_x, fairy_y)
end