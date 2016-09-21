local music
local background_img, hero_was_visible, hero_dead_sprite, hero_dead_x, hero_dead_y, fairy_sprite, cursor_position, state, tunic, hero, map

local draw_game_over, draw_game_over_ef = false, false

local game_over_ef = sol.surface.create("menus/game_over.png")
local game_over_bitmap = sol.surface.create("menus/game_over.png")

return function(game)
  local game_over = {}
  -- Declare the function here
  function game:on_game_over_started()
    tunic = self:get_ability("tunic")
    hero = self:get_hero()
    map = self:get_map()
	
    sol.menu.start(self:get_map(), game_over)
  end
    
  function game_over:on_started()
    self.surface = sol.surface.create(320, 240)
	self.surface:fill_color({0, 0, 0})
	
    game.hud:set_enabled(false)
    game:show_cutscene_bars(true)
    game:fade_audio(0, 10)
    game:set_clock_enabled(false)
  
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
        -- sol.audio.play_sound("hero_dying")
        hero:get_sprite():set_paused(false)
        hero:set_animation("dying")

        local bottled_fairy = game:get_first_bottle_with(7) 
	    -- We have a fairy
        if bottled_fairy ~= nil then
          self:saved_by_fairy(bottled_fairy)
        else 
	      -- No fairy: game over.
	      self:game_over()
        end
      end
    end)
  end

  -- Restores the Music
  function game_over:restore_music()
    local map = game:get_map()
	sol.audio.set_music_volume(game:get_value("old_volume"))
    if map:get_world() == "field" then
	  game.is_in_field = false
      game:start_field_audio()
    else
      sol.audio.play_music(music)
    end
	
	music = nil
  end
  
  function game_over:game_over()
    sol.timer.start(self, 4500, function() 
	  sol.timer.start(500, function()
	    self:spawn_letter()
	  end)

	  sol.timer.start(1500, function()
	    state = "fade_screen"
	    self.surface:fade_in(200)
	  end)
	
	  sol.audio.set_music_volume(game:get_value("old_volume"))

	  sol.audio.play_music("menu_game_over", false)
        state = "choose_1"
        fairy_sprite:set_xy(76, 112)  -- Cursor.
        cursor_position = 0
	  end)
	end

  -- Todo
  function game_over:saved_by_fairy(item)
    -- Has a fairy.
    game.hud:set_enabled(true)
    state = "saved_by_fairy"
    -- Make the bottle empty.
    item:set_variant(1)
    fairy_sprite:set_xy(hero_dead_x + 12, hero_dead_y + 21)
    local movement = sol.movement.create("target")
    movement:set_target(240, 22)
    movement:set_speed(96)
    movement:start(fairy_sprite, function()
      state = "waiting_end"
      game:add_life(7 * 4)  -- Restore 7 hearts.
      sol.timer.start(self, 1000, function()
        state = "resume_game"
	    game:show_cutscene_bars(false)
        -- restore music
        game:stop_game_over()
        sol.menu.stop(self)
      end)
    end)
  end

  function game_over:spawn_letter()
    draw_game_over_ef = true
  
    game_over_ef:fade_in(120, function()
      game_over_ef:fade_out(120, function() 
	    draw_game_over_ef = false 
	  end)
  	  draw_game_over = true
	  game_over_bitmap:fade_in(120, function() 
	    sol.timer.start(1000, function()
		  game_over_bitmap:fade_out(120, function()
		    draw_game_over = false 
			sol.timer.start(1000, function() 
			  state = "choose_1" 
			end)
	      end)
		end) 
	  end)
    end)
  end



  function game_over:on_finished()
    local hero = game:get_hero()
    if hero ~= nil then
      hero:set_visible(hero_was_visible)
    end
    -- background_img = nil
    fairy_sprite = nil
    cursor_position = nil
    state = nil
	self:restore_music()
    sol.timer.stop_all(self)  
  end

  function game_over:on_draw(dst_surface)
    if state == "fade_screen" or state == "choose_1" or state == "choose_2" then
      self.surface:draw(dst_surface)
    end 

    if draw_game_over_ef then
      game_over_ef:draw_region(0, 16, 108, 16, dst_surface, 106, 96)
    end
  
    if draw_game_over then 
	  game_over_bitmap:draw_region(0, 0, 108, 16, dst_surface, 106, 96)
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

  function game_over:on_command_pressed(command)

    if state ~= "choose_1" or state ~= "choose_2" then
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
      game.hud:set_enabled(false)
      game:add_life(7 * 4)  -- Restore 7 hearts.
	
	-- First screen 
	
	--[[
	Would you like to save 
	  YES No
	
	2nd screen
	Continue playing ?
	  YES No
	
	]]

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
  
  return game_over
end