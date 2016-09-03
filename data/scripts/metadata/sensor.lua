local sensor_meta = sol.main.get_metatable("sensor")
local ladder = require("scripts/gameplay/hero/skills/climbing_manager")
local climbing = false

function sensor_meta:on_activated()
  local game = self:get_game()
  local map = self:get_map()
  local hero = map:get_hero()
  local name = self:get_name()
  local dungeon = game:get_dungeon()
	
	-- Sensors named "to_layer_X_sensor" move the hero on that layer.
  if name:match("^layer_up_sensor") then
    local x, y, layer = hero:get_position()
    if layer < 2 then hero:set_position(x, y, layer + 1) end
	if map.ladder_event ~= nil then map.ladder_event:set_position(hero:get_position()) end
  elseif name:match("^layer_down_sensor") then
    local x, y, layer = hero:get_position()
    if layer > 0 then hero:set_position(x, y, layer - 1) end
  end
  
  local hero_direction = hero:get_direction()
	
  -- Ladder System
  -- We activated the ladder, but we don't know it's state
  if name:match("^ladder_(%d+)") and (hero_direction == 1 or hero_direction == 3) then
    local type_of_ladder = string.sub(name, 8, 9)
    local x, y, l = hero:get_position()
	
	local function move_hero(direction)
	  local w = sol.movement.create("straight")
	  w:set_max_distance(4) -- 16
	  w:set_speed(10) -- 15
	  w:set_angle(direction * math.pi / 2)
	  w:start(hero)
 
  	  function w:on_position_changed()
	    local x, y, l = hero:get_position()
	    map.ladder_event:set_position(x, y, l)
	  end
	end
	
	-- Unknown state, the hero isn't climbing, but he's going to.
	if not climbing then
	  climbing = true
	
	  hero:set_invincible(true)
	  map.ladder_event = map:create_custom_entity({
		x = x,
		y = y,
		layer = l,
		width = 16,
		height = 16,
		direction = 0	  
	  })
	  map.ladder_event:set_modified_ground("traversable")
	
	  hero:set_position(map.ladder_event:get_position())
	  hero:freeze()
	  move_hero(hero:get_direction())
	  hero:set_fixed_animations("climbing_stopped", "climbing_walking")
	
	  hero:set_animation("climbing_start_up", function()
	    hero:unfreeze()
	    hero:set_animation("climbing_stopped")
		hero:set_walking_speed(25)
		sol.menu.start(map, ladder)
		ladder:climb(type_of_ladder, map.ladder_event)
	  end)
	else -- We are climbing but the hero activated the arrival event.
	  climbing = false
	  hero:freeze()
	  hero:set_fixed_animations(nil, nil)
	  move_hero(hero:get_direction())

	  hero:set_animation("climbing_start_up", function()
	    map.ladder_event:remove()
		hero:unfreeze()
		hero:set_walking_speed(88)
		sol.menu.stop(ladder)
		hero:set_invincible(false)
	  end) 
	end
  end

  -- Sensors prefixed by "dungeon_room_N_" save exploration state of room "N" of current dungeon floor.
  -- Optional treasure savegame value appended to end will play signal chime if value is false and hero has compass in inventory. "dungeon_room_N_bxxx"
  local room = name:match("^dungeon_room_(%d+)")
  local signal = name:match("(%U%d+)$")

  game:set_room(tonumber(room))  
  
  if room ~= nil then
    game:set_explored_dungeon_room(nil, nil, tonumber(room))
    if signal ~= nil and not game:get_value(signal) then
      if game:has_dungeon_compass(game:get_dungeon_index()) then
        sol.audio.play_sound("signal")
      end
    end
  end
end