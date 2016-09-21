local map_metatable = sol.main.get_metatable("map")

function map_metatable:check_night()
  local game = self:get_game()
  
  for entity in self:get_entities("night_") do
    entity:set_enabled(game:get_time_of_day() ~= "day")
  end
end

function map_metatable:create_collision(x, y, layer)
  local collision = self:create_custom_entity({ 
    x = x, 
	y = y, 
	layer = layer,
	width = 8,
	height = 8,
	direction = 0
  })
  local collision_sprite = collision:create_sprite("entities/item_collision")
  function collision_sprite:on_animation_finished()
	collision:remove()
  end
  sol.audio.play_sound("items/item_metal_collision_wall")
end

-- Move the camera
function map_metatable:move_camera(x, y, speed, callback, delay_before, delay_after, suspend)
  local camera = self:get_camera()
  local game = self:get_game()
  local hero = self:get_hero()

  delay_before = delay_before or 1000
  delay_after = delay_after or 1000

  local back_x, back_y = camera:get_position_to_track(hero)
  game:set_suspended(suspend or true)
  camera:start_manual()

  local movement = sol.movement.create("target")
  movement:set_target(camera:get_position_to_track(x, y))
  movement:set_ignore_obstacles(true)
  movement:set_speed(speed)
  movement:start(camera, function()
    local timer_1 = sol.timer.start(self, delay_before, function()
      callback()
      local timer_2 = sol.timer.start(self, delay_after, function()
        local movement = sol.movement.create("target")
        movement:set_target(back_x, back_y)
        movement:set_ignore_obstacles(true)
        movement:set_speed(speed)
        movement:start(camera, function()
          game:set_suspended(false)
          camera:start_tracking(hero)
          if self.on_camera_back ~= nil then
            self:on_camera_back()
          end
        end)
      end)
      timer_2:set_suspended_with_map(false)
    end)
    timer_1:set_suspended_with_map(false)
  end)


end

function map_metatable:spawn_chest(entity, sound_to_play, switch, after_combat, music_if_fade)
  local x, y, layer = entity:get_position()
  local game = self:get_game()
  local hero = self:get_hero()
  
  hero:unfreeze()
  
  self:move_camera(x, y, 100, function()
    entity:get_sprite():set_ignore_suspend(true)
	entity:set_drawn_in_y_order(false)
    sol.timer.start(100, function()
	  if sound_to_play ~= nil then
	    if switch then
	      sol.audio.play_sound(sound_to_play)
		end
	    if after_combat then
		  sol.timer.start(6500, function() sol.audio.play_sound(sound_to_play) end) 
		end
	  end
      local chest_effect = self:create_custom_entity({
        x = x,
        y = y - 5,
        layer = layer,
		width = 16,
		height = 16,
        direction = 0,
        sprite = "entities/dungeon/gameplay_sequence_chest_appearing",
      })
      chest_effect:set_drawn_in_y_order(true)
	  chest_effect:get_sprite():fade_in(30)
		
	  local m = sol.movement.create("straight")
      m:set_ignore_obstacles(true)
      m:set_speed(1)
      m:set_angle(math.pi / 2)
      m:start(chest_effect)

	  sol.audio.play_sound("/common/chest_appear")

      sol.timer.start(2900, function()
        entity:set_enabled(true)
        entity:get_sprite():fade_in(40) 
      end)

	  sol.timer.start(5000, function()
		chest_effect:get_sprite():fade_out(10, function() 
		  m:stop()
		  chest_effect:remove()
		  entity:set_drawn_in_y_order(true) 
		end) 
	  end)

	  sol.timer.start(7500, function()
	    if self.on_chest_spawned ~= nil then 
		  self:on_chest_spawned(entity:get_name()) 
		  return
		end
		if music_if_fade ~= nil then
		  game:fade_audio(game:get_value("old_volume"), 10)
		  sol.audio.play_music(music_if_fade)
		end
		if not game:is_using_item() then
		  game:show_cutscene_bars(false)
		end
        game:set_hud_enabled(true)
        game:set_clock_enabled(true)
	  end)
    end)
  end, 200, 7500, true)
end

function map_metatable:spawn_falling_chest(entity, switch)

  local sound 

end
  
function map_metatable:on_finished()
  local game = self:get_game()
  game:clear_map_name()
  game:clear_fog()
end
