local map_metatable = sol.main.get_metatable("map")
local heat_timer, swim_timer

-- Auto start the field BGM
function map_metatable:start_field_bgm()
  local audio = require("scripts/gameplay/audio/hyrule_field_audio_mgr")
  sol.menu.start(self, audio)
end

function map_metatable:on_started()
  local game = self:get_game()
  	
	-- de-comment this when day/night system would be finished, this is to avoid any corruption / error while making the script.

    -- local function random_8(lower, upper)
      -- math.randomseed(os.time() - os.clock() * 1000)
      -- return math.random(math.ceil(lower/8), math.floor(upper/8))*8
    -- end

    -- Night time is more dangerous - add various enemies.
    -- if game:get_map():get_world() == "outside_world" and
    -- game:get_time_of_day() == "night" then
      -- local keese_random = math.random()
      -- if keese_random < 0.7 then
	-- local ex = random_8(1,1120)
	-- local ey = random_8(1,1120)
	-- self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	-- sol.timer.start(self, 1100, function()
	  -- local ex = random_8(1,1120)
	  -- local ey = random_8(1,1120)
	  -- self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	-- end)
      -- elseif keese_random >= 0.7 then
	-- local ex = random_8(1,1120)
	-- local ey = random_8(1,1120)
	-- self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	-- sol.timer.start(self, 1100, function()
	  -- local ex = random_8(1,1120)
	  -- local ey = random_8(1,1120)
	  -- self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	-- end)
	-- sol.timer.start(self, 1100, function()
	  -- local ex = random_8(1,1120)
	  -- local ey = random_8(1,1120)
	  -- self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	-- end)
      -- end
      -- local poe_random = math.random()
      -- if poe_random <= 0.5 then
	-- local ex = random_8(1,1120)
	-- local ey = random_8(1,1120)
	-- self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
      -- elseif keese_random <= 0.2 then
	-- local ex = random_8(1,1120)
	-- local ey = random_8(1,1120)
	-- self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
	-- sol.timer.start(self, 1100, function()
	  -- local ex = random_8(1,1120)
	  -- local ey = random_8(1,1120)
	  -- self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
	-- end)
      -- end
      -- local redead_random = math.random()
      -- if poe_random <= 0.1 then
	-- local ex = random_8(1,1120)
	-- local ey = random_8(1,1120)
	-- self:create_enemy({ breed="redead", x=ex, y=ey, layer=0, direction=1 })
      -- end
    -- end

end

function map_metatable:on_update()
  -- if hero doesn't have red tunic, slowly remove stamina in Subrosia.
  if self:get_game():get_map():get_world() == "outside_subrosia" and
  self:get_game():get_item("tunic"):get_variant() < 2 then
    if not heat_timer then
      heat_timer = sol.timer.start(self:get_game():get_map(), 5000, function()
        self:get_game():remove_stamina(5)
        return true
      end)
    end
  else
    if heat_timer then
      heat_timer:stop()
      heat_timer = nil
    end
  end
   -- Hero Clothes
  if self:get_game():get_hero():get_state() == "swimming" then -- port this to hero
   -- Fancy effect
	if not swimming_trail and self:get_game():get_value("item_cloak_darkness_state") == 0 then
  	  
	end
        -- Hero Clothes
	if self:get_game():get_item("tunic"):get_variant() == 1 then
	  if not swim_timer then
		swim_timer = sol.timer.start(self:get_game():get_map(), 75, function()
		  self:get_game():remove_stamina(4)
		return true
		end)
	  end
		
	-- Goron Tunic (fire ability, so it make sense that link is more vulnerable in water)
	elseif self:get_game():get_item("tunic"):get_variant() == 2 then
	  if not swim_timer then
		swim_timer = sol.timer.start(self:get_game():get_map(), 120, function()
		  self:get_game():remove_stamina(6)
		return true
		end)
	  end
	-- Zora Tunic
	elseif self:get_game():get_item("tunic"):get_variant() == 3 then
	  if not swim_timer then
		swim_timer = sol.timer.start(self:get_game():get_map(), 75, function()
		  self:get_game():remove_stamina(2)
		return true
		end)
	  end
	end
		
  else	  
    if swim_timer ~= nil then swim_timer:stop() swim_timer = nil end
    if swimming_trail ~= nil then swimming_trail:stop() swimming_trail = nil end
  end		
end
  
function map_metatable:spawn_chest(entity, sound_to_play, switch, after_combat, music_if_fade)
  local x, y, layer = entity:get_position()
  local game = self:get_game()
  self:get_hero():unfreeze()
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
		chest_effect:get_sprite():fade_out(10, function() m:stop() chest_effect:remove() entity:set_drawn_in_y_order(true) end) 
	  end)

	  sol.timer.start(7500, function()
		if music_if_fade ~= nil then
		  game:fade_audio(game:get_value("old_volume"), 10)
		  sol.audio.play_music(music_if_fade)
		end
		game:show_cutscene_bars(false)
        game:set_hud_enabled(true)
        game:set_clock_enabled(true)
	  end)
    end)
  end,1, 7500)
end
  
function map_metatable:on_finished()
  local game = self:get_game()
  game:clear_map_name()
  game:clear_fog()
end