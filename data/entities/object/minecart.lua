-- A minecart to be used by the hero on railroads.
-- from : Mercuri's Chest

local minecart = ...
local map = minecart:get_map()
local game = minecart:get_game()
local hero = map:get_hero()

-- Whether the hero is facing the minecart stopped.
local hero_facing_minecart = false
local action_command_minecart = false

minecart:set_drawn_in_y_order(true)

-- Don't let the hero traverse the minecart.
minecart:set_traversable_by("hero", false)

-- Hurt enemies hit by the minecart.
minecart:add_collision_test("sprite", function(minecart, other)
  if other:get_type() == "enemy" then
    other:hurt(4)
  end
end)

-- Detect minecart turns.
minecart:add_collision_test("containing", function(minecart, other)

  if other:get_type() == "custom_entity" then

    if other:get_model() == "object/minecart_turn" then
      local movement = hero:get_movement()
      if movement ~= nil then
        -- Simply change the hero's movement direction.
        local direction4 = other:get_direction()
        movement:set_angle(direction4 * math.pi / 2)
        hero:set_direction(other:get_direction())
      end
    end

    if other:get_model() == "object/minecart_turn_diagonal" then
      local movement = hero:get_movement()
      if movement ~= nil then
        -- Simply change the hero's movement direction.
        local direction8 = other:get_direction() * 2 + 1
        movement:set_angle(direction8 * math.pi / 4)
        local direction4 = (direction8 == 1 or direction == 7) and 0 or 2
        hero:set_direction(direction4)
      end
    end
	
	if other:get_model() == "object/minecart_end" then
      local movement = hero:get_movement()
	  local direction4 = hero:get_direction()
      if movement ~= nil then
	  game:set_ability("tunic", game:get_value("item_saved_tunic"))
	  hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
      game:set_ability("sword", game:get_value("item_saved_sword"))
      game:set_ability("shield", game:get_value("item_saved_shield"))
      game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
      game:set_pause_allowed(true)
	  movement:stop()
	  minecart:get_sprite():set_animation("stopped")
	  
	  sol.audio.play_sound("objects/minecart/landing")
	  sol.audio.play_sound("objects/minecart/preparing")
	  sol.audio.play_sound("objects/minecart/common")
	  
	if math.random(1) == 0 then 
	sol.audio.play_sound("characters/link/voice/fall_damage0")
    else
	sol.audio.play_sound("characters/link/voice/fall_damage1")
	end
	  
	  hero:start_jumping(direction4 * 2, 32, false)
	  sol.timer.start(200,function()
	  minecart:set_traversable_by("hero", false)
	  minecart:set_drawn_in_y_order(true)
	  -- oppose the direction
	  minecart:set_direction(hero:get_direction() % 2)
	  end)
      end
    end
	
	if other:get_model() == "object/minecart_dead_end" then
    minecart:get_sprite():set_animation("turning_over")
	
	game:set_ability("tunic", game:get_value("item_saved_tunic"))
	hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
    game:set_ability("sword", game:get_value("item_saved_sword"))
    game:set_ability("shield", game:get_value("item_saved_shield"))
    game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
    game:set_pause_allowed(true)
	movement:stop()
	
	  sol.audio.play_sound("objects/minecart/landing")
	  sol.audio.play_sound("objects/minecart/preparing")
	  sol.audio.play_sound("objects/minecart/common")
	  
	if math.random(1) == 0 then 
	sol.audio.play_sound("characters/link/voice/fall_damage0")
    else
	sol.audio.play_sound("characters/link/voice/fall_damage1")
	end
	  
	local explode_movement = sol.movement.create("straight")
	explode_movement:set_max_distance(128)
	explode_movement:set_speed(150)
	explode_movement:set_angle(minecart:get_direction() * math.pi / 2 )
	explode_movement:start(minecart)
	
    hero:start_jumping(direction4 % 2 * 2, 32, false)
	sol.timer.start(200,function()
	minecart:set_traversable_by("hero", false)
    minecart:set_drawn_in_y_order(true)
	end)

   sol.timer.start(800, function()
   --restart the same movement but oppose the direction
   minecart:set_direction(0)
   minecart:get_sprite():set_animation("destroy")

   minecart:remove()
end)

end
end

end)

-- Show an action icon when the player faces the minecart.
minecart:add_collision_test("facing", function(minecart, other)

  if other:get_type() == "hero" then

    hero_facing_minecart = true
    if minecart:get_movement() == nil
      and game:get_command_effect("action") == nil
      and game:get_custom_command_effect("action") == nil then
      action_command_minecart = true
      game:set_custom_command_effect("action", "action")
    end
  end

end)

-- Remove the action icon when stopping facing the minecart.
function minecart:on_update()

  if action_command_minecart and not hero_facing_minecart then
    game:set_custom_command_effect("action", nil)
    action_command_minecart = false
  end

  hero_facing_minecart = false
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    game:set_ability("tunic", 1)
    local sword = game:get_ability("sword")
    game:set_ability("sword", 0)
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
	local kb_action_key = game:get_command_keyboard_binding("action")
	game:set_command_keyboard_binding("action", nil)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
	game:set_value("item_saved_action", kb_action_key)
end

-- Called when the hero presses the action command near the minecart.
function minecart:on_interaction()

  if minecart:get_sprite():get_animation() == "stopped" then
  local x,y = minecart:get_position()
  local tunic = game:get_ability("tunic")
  local direction4 = hero:get_direction()
	
       if hero:get_direction() == 0 then --right
	       minecart:set_drawn_in_y_order(false)
           hero:set_position(x-16, y)
       elseif hero:get_direction() == 1 then --up
	       minecart:set_drawn_in_y_order(false)
           hero:set_position(x, y+16)
       elseif hero:get_direction() == 2 then --left
	       minecart:set_drawn_in_y_order(false)
           hero:set_position(x+16, y)
       elseif hero:get_direction() == 3 then --down
           hero:set_position(x, y-16)
       end
	   
    hero:freeze()
	  
	minecart:set_traversable_by("hero", true)
	minecart:set_drawn_in_y_order(false)    
	store_equipment()
	game:set_pause_allowed(false)
	

	if math.random(1) == 0 then 
	sol.audio.play_sound("characters/link/voice/jump0")
    else
	sol.audio.play_sound("characters/link/voice/jump1")
	end
	
	sol.audio.play_sound("characters/link/voice/jump")

	local jump_movement = sol.movement.create("jump")
	jump_movement:set_distance(16)
	jump_movement:set_direction8(direction4 * 2)
	jump_movement:start(hero)
	
	sol.timer.start(300, function()
	
	sol.audio.play_sound("objects/minecart/preparing")
	sol.audio.play_sound("objects/minecart/landing")
 
	hero:set_tunic_sprite_id("hero/action/minecart/minecarting.tunic_"..tunic)
	hero:set_animation("stopped")
	hero:set_direction(minecart:get_direction())	
	end)
	
	sol.timer.start(700, function()
    minecart:go()
	sol.audio.play_sound("characters/link/voice/fall1")
	end)
  end
end

-- Starts driving the minecart.
function minecart:go()

  hero:set_position(minecart:get_position())
  hero:set_animation("walking")
  minecart:get_sprite():set_animation("start")

  game:set_custom_command_effect("action", nil)
  action_command_minecart = false
  hero_facing_minecart = false

  -- Create a movement on the hero.
  local direction4 = minecart:get_direction()
  local movement = sol.movement.create("straight")
  movement:set_angle(direction4 * math.pi / 2)
  movement:set_speed(500)
  movement:set_smooth(false)

  function movement:on_position_changed()
    -- Put the minecart at the same position as the hero.
    minecart:set_position(hero:get_position())
	minecart:set_direction(hero:get_direction())
  end
  
  -- Destroy the minecart when reaching an obstacle.
  function movement:on_obstacle_reached()
    minecart:stop()
  end
  
  -- The hero must be allowed to traverse the minecart during the movement.
  minecart:set_traversable_by("hero", true)
  movement:start(hero)
end

-- Stops driving the minecart and destroys it.
function minecart:stop()

  local minecart_sprite = minecart:get_sprite()
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
  game:set_ability("sword", game:get_value("item_saved_sword"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
  game:set_pause_allowed(true)
  
  -- Break the minecart.
  local direction4 = hero:get_direction()
  
  minecart_sprite:set_direction(0)
  minecart_sprite:set_animation("destroy")

  function minecart_sprite:on_animation_finished()
    -- Remove it from the map when the animation is finished.
       minecart:remove()
  end

   -- Restore control to the player.
  -- map.on_command_pressed = nil
  hero:unfreeze()
end

