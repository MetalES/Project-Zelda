local item = ...
local game = item:get_game()

local item_name = "hookshot"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

local volume_bgm = game:get_value("old_volume")

-- Extra item config bellow

local distance = 220 -- 222
local speed = 220
local catchable_entity_types = { "pickable" }
local hook_entity_types = {}

-- Hookshot 

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value("item_"..item_name.."_state", 0)
end

function item:on_obtaining() 
  sol.audio.set_music_volume(0)
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
if show_bars == true and not starting_cutscene then game:hide_bars() end
end

function item:on_map_changed()
game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
if game:get_value("item_"..item_name.."_state") > 0 then 
-- freeze the hero reset it to frame 0 so it avoid the frame error
game:get_hero():freeze()
game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
game:set_ability("sword", game:get_value("item_saved_sword"))
game:get_hero():set_walking_speed(88)
if show_bars == true and not starting_cutscene then game:hide_bars() end
if not starting_cutscene then game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
game:get_hero():unfreeze()
self:set_finished()
end
end

function item:store_equipment()
    local kb_action_key = game:get_command_keyboard_binding("action")
	local kb_item_1_key = game:get_command_keyboard_binding("item_1")
	local kb_item_2_key = game:get_command_keyboard_binding("item_2")
	local jp_action_key = game:get_command_joypad_binding("action")
	local jp_item_1_key = game:get_command_joypad_binding("item_1")
	local jp_item_2_key = game:get_command_joypad_binding("item_2")
	
    game:set_ability("sword", 0)
    game:set_ability("shield", 0)
	
    game:set_command_keyboard_binding("action", nil)
	game:set_command_joypad_binding("action", nil)
	
	if game:get_value("_item_slot_1") ~= item_name then game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil) end
	if game:get_value("_item_slot_2") ~= item_name then game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil) end

    game:set_value("item_saved_kb_action", kb_action_key)
	game:set_value("item_1_kb_slot", kb_item_1_key)
	game:set_value("item_2_kb_slot", kb_item_2_key)
	game:set_value("item_saved_jp_action", jp_action_key)
	game:set_value("item_1_jp_slot", jp_item_1_key)
	game:set_value("item_2_jp_slot", jp_item_2_key)
	
	game:set_pause_allowed(false)
end

function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

if hookshot_timer ~= nil then hookshot_timer:stop(); hookshot_timer = nil end
if hookshot_sync ~= nil then hookshot_sync:stop(); hookshot_sync = nil end
        
game:set_custom_command_effect("attack", nil)

hero:freeze()
hero:set_walking_speed(88)

sol.audio.play_sound("common/item_show")

hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))

if show_bars == true and not starting_cutscene then game:hide_bars() end

hero:set_animation("hookshot_intro", function() 
hero:unfreeze(); 
hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))
game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_ability("sword", game:get_value("item_saved_sword")); 
item:set_finished(); 
game:set_pause_allowed(true)
end)
end

function item:on_using()  
  local hero = game:get_hero()
  local tunic = game:get_value("item_saved_tunic")
  
  local function end_by_collision() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if show_bars == true and not starting_cutscene then game:hide_bars() end; item:set_finished(); game:set_pause_allowed(true) end
  local function end_by_pickable() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); item:set_finished(); game:set_pause_allowed(true) end

  -- read the 2 item slot.
  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end
  game:using_item() -- notify the game we're using the item
  
if game:get_value("item_"..item_name.."_state") == 0 then
	item:store_equipment()
	
	if not show_bars then game:show_bars() end

	sol.audio.play_sound("common/bars_dungeon")
	sol.audio.play_sound("common/item_show")
	hero:set_animation("hookshot_intro", function()	
      -- sol.timer.start(40, function()
	    hero:set_walking_speed(40)
		hero:unfreeze()
		game:set_value("item_"..item_name.."_state", 1)
		hero:set_tunic_sprite_id("hero/item/hookshot/hookshot_moving_free_tunic"..tunic)
		
           hookshot_sync = sol.timer.start(10, function()
			local lx, ly, layer = hero:get_position()
			game:set_custom_command_effect("attack", "return")
			game:set_custom_command_effect("action", nil)
		
--systeme d : when you collide with water or jumper, the hero is send 1 pixel away so the game had enough time to destroy the item and restore everything
--Todo : when hero:on_direction_changed() will be back, delete this, and replace the whole thing by input checking and values instead of direction checking
-- this is just a placeholder until the function will be back

			if hero:get_direction() == 0 then new_x = -1; new_y = 0 
			elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
			elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
			elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
			end
 
			if hero:get_state() == "hurt" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
			if hero:get_state() == "swimming" or hero:get_state() == "jumping" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
			if hero:get_state() == "falling" or hero:get_state() == "stairs" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
			if hero:get_state() == "treasure" then hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
			
			if game:is_command_pressed("attack") and game:get_value("item_"..item_name.."_avoid_return") ~= true then
			if hookshot_timer ~= nil then hookshot_timer:stop(); hookshot_timer = nil; item:transit_to_finish() end
			if hookshot_sync ~= nil then hookshot_sync:stop(); hookshot_sync = nil; item:transit_to_finish() end

			end
		   return true
		   end)
	    end)
		
  elseif game:get_value("item_"..item_name.."_state") == 1 then
  
  if game:is_command_pressed(slot) and not starting_cutscene then
   hero:freeze()
   game:set_value("item_"..item_name.."_avoid_return", true)
   sol.audio.play_sound(sound_dir.."arming")
   hero:set_tunic_sprite_id("hero/item/hookshot/hookshot_moving_concentrate_tunic"..tunic)
   hero:set_walking_speed(25)
   hero:unfreeze()
   game:set_value("item_"..item_name.."_can_shoot", true)
   game:set_value("item_"..item_name.."_avoid_return", false)
  end
  
  
hookshot_timer = sol.timer.start(10, function()
	if not game:is_command_pressed(slot) and game:get_value("item_"..item_name.."_can_shoot") == true and not starting_cutscene then
		hero:set_tunic_sprite_id("hero/tunic"..tunic)
		hero:set_animation("hookshot_shoot")
		if hookshot_timer ~= nil then hookshot_timer:stop(); hookshot_timer = nil; self:start_hookshot(); game:using_item() end
	end
	return true 
	end)
end

end

function item:set_finished()
		if hookshot_timer ~= nil then hookshot_timer:stop(); hookshot_timer = nil end
		if hookshot_sync ~= nil then hookshot_sync:stop(); hookshot_sync = nil end
		game:item_finished() -- todo all item
		
		game:set_value("item_"..item_name.."_can_shoot", false)
		game:set_value("item_"..item_name.."_state", 0)
		game:set_value("item_"..item_name.."_avoid_return", false)

		game:set_custom_command_effect("attack", nil)
		game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
		game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
		game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))
		game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
		game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
		game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
end

function item:start_hookshot()
local going_back = false
  local sound_timer
  local direction
  local map = item:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  local hookshot 
  local hookshot_sprite
  local link_sprite
  local entities_caught = {}
  local hooked_entity
  local hooked
  local leader
  local go
  local go_back
  local hook_to_entity
  local stop
  local tunic = game:get_value("item_saved_tunic")
  local hookshot_hook_timer
  local hookshot_sprite_x, hookshot_sprite_y = x, y
  
  game:set_value("item_"..item_name.."_avoid_return", true)
  game:set_pause_allowed(false)

  -- Sets what can be traversed by the hookshot.
  -- Also used for the invisible leader entity used when hooked.
  local function set_can_traverse_rules(entity)
    entity:set_can_traverse("crystal", true)
    entity:set_can_traverse("crystal_block", true)
    entity:set_can_traverse("hero", true)
    entity:set_can_traverse("jumper", true)
    entity:set_can_traverse("stairs", false)  -- TODO only inner stairs should be obstacle and only when on their lowest layer.
    entity:set_can_traverse("stream", true)
    entity:set_can_traverse("switch", true)
    entity:set_can_traverse("teletransporter", true)
    entity:set_can_traverse_ground("deep_water", true)
    entity:set_can_traverse_ground("shallow_water", true)
    entity:set_can_traverse_ground("hole", true)
    entity:set_can_traverse_ground("lava", true)
    entity:set_can_traverse_ground("prickles", true)
    entity:set_can_traverse_ground("low_wall", true)  -- Needed for cliffs.
    entity.apply_cliffs = true
  end

  -- Returns if the hero would land on an obstacle at the specified coordinates.
  -- This is similar to entity:test_obstacles() but also checks layers below
  -- in case the ground is empty (because the hero will fall there).
  local function test_hero_obstacle_layers(candidate_x, candidate_y, candidate_layer)
    local hero_x, hero_y, hero_layer = hero:get_position()
    candidate_layer = candidate_layer or hero_layer
    if hero:test_obstacles(candidate_x - hero_x, candidate_y - hero_y, candidate_layer) then
      return true       -- Found an obstacle.
    end

    if candidate_layer == 0 then
      return false      -- Cannot go deeper and no obstacle was found.
    end

    -- Test if we are on empty ground.
    local origin_x, origin_y = hero:get_origin()
    local top_left_x, top_left_y = candidate_x - origin_x, candidate_y - origin_y
    local width, height = hero:get_size()
    if map:get_ground(top_left_x, top_left_y, candidate_layer) == "empty" and
        map:get_ground(top_left_x + width - 1, top_left_y, candidate_layer) == "empty" and
        map:get_ground(top_left_x, top_left_y + height - 1, candidate_layer) == "empty" and
        map:get_ground(top_left_x + width - 1, top_left_y + height - 1, candidate_layer) == "empty" then
      -- We are on empty ground: the hero will fall one layer down.
      return test_hero_obstacle_layers(candidate_x, candidate_y, candidate_layer - 1)
    end
  end

  -- Starts the hookshot movement from the hero.
  function go()
    local movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    movement:set_speed(speed)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(distance)
    movement:start(hookshot)

    function movement:on_obstacle_reached()
	if hookshot_hook_timer ~= nil then hookshot_hook_timer:stop(); hookshot_hook_timer = nil end
	local link_hook_x, link_hook_y
	
	if hero:get_direction() == 0 then link_hook_x = 10; link_hook_y = -5 
	elseif hero:get_direction() == 1 then link_hook_x = 0; link_hook_y = -15
    elseif hero:get_direction() == 2 then link_hook_x = -10; link_hook_y = -5
	elseif hero:get_direction() == 3 then link_hook_x = 0; link_hook_y = 5
    else link_hook_x, link_hook_y = 0	end
	
	local collision_effect = map:create_custom_entity({
      x = hookshot_sprite_x + link_hook_x,
      y = hookshot_sprite_y + link_hook_y,
      layer = layer,
      direction = 0,
      sprite = "entities/item.collision",
    })
    sol.timer.start(300,function() collision_effect:remove() end)
      sol.audio.play_sound("items/item_metal_collision_wall")
      go_back()
    end

    function movement:on_finished()
      go_back()
    end

    -- Play a repeated sound.
    sound_timer = sol.timer.start(map, 62, function() --150 
      sol.audio.play_sound(sound_dir.."firing_loop")
      return true  -- Repeat the timer.
    end)
    sol.audio.play_sound(sound_dir.."firing_start")
  end

  -- Makes the hookshot come back to the hero.
  -- Does nothing if the hookshot is already going back.
  function go_back()
    if going_back then
      return
    end

    local movement = sol.movement.create("target") -- straight
    local angle = (direction + 2) * math.pi / 2
    movement:set_speed(speed)
	movement:set_target(hero)
    -- movement:set_angle(angle)
    movement:set_smooth(false)
    -- movement:set_max_distance(hookshot:get_distance(hero))
    movement:set_ignore_obstacles(true)
    movement:start(hookshot)
    going_back = true

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(hookshot:get_position())
      end
    end

    function movement:on_finished()
      stop()
    end
  end

  -- Attaches the hookshot to an entity and makes the hero fly there.
  function hook_to_entity(entity)
    if hooked then
      return      -- Already hooked.
    end

    hooked_entity = entity
    hooked = true
    hookshot:stop_movement()
    sol.audio.play_sound(sound_dir.."hit_valid_target")
	sol.audio.play_sound(sound_dir.."link_tracted")

    -- Create a new custom entity on the hero, move that entity towards the entity
    -- hooked and make the hero follow that custom entity.
    -- Using this intermediate custom entity rather than directly moving the hero
    -- allows better control on what can be traversed.
	
	local direction_fix_hook_y
	
	if hero:get_direction() == 1 then direction_fix_hook_y =  0.5 elseif hero:get_direction() == 3 then direction_fix_hook_y = - 0.5 else direction_fix_hook_y = 0 end
    leader = map:create_custom_entity({
      direction = direction,
      layer = layer,
      x = x,
      y = y + direction_fix_hook_y,
      width = 16,
      height = 16,
    })
    leader:set_origin(8, (12 + direction_fix_hook_y * -2))
    set_can_traverse_rules(leader)
    leader.apply_cliffs = true

    local movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    movement:set_speed(speed)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(hookshot:get_distance(hero) + (direction_fix_hook_y * -2))
    movement:start(leader)

    hero:start_jumping(0, 100, true)
    hero:get_movement():stop()
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
    hero:set_animation("hookshot_tracting")
    hero:set_direction(direction)

    local past_positions = {}
    past_positions[1] = { hero:get_position() }

    function movement:on_position_changed()
      -- Teletransporters, holes, etc. are avoided because the hero is jumping.
      hero:set_position(leader:get_position())
      -- Remember all intermediate positions to find a legal place
      -- for the hero later in case he ends up in a wall.
      past_positions[#past_positions + 1] = { leader:get_position() }
    end

    function movement:on_finished()
      stop_hooked()
      if hero:test_obstacles(0, 0) then
        -- The hero ended up in a wall.
        local fixed_position = past_positions[1]  -- Initial position in case none is legal.
        for i = #past_positions, 2, -1 do
          if not test_hero_obstacle_layers(unpack(past_positions[i])) then
            -- Found a legal position.
            fixed_position = past_positions[i]
            break
          end
        end
        hero:set_position(unpack(fixed_position))
        hero:set_invincible(true, 1000)
        hero:set_blinking(true, 1000)
      end
    end
  end

  -- Destroys the hookshot and restores control to the player.
  function stop()
    hero:unfreeze()
    if hookshot ~= nil then sound_timer:stop(); hookshot:remove() end
    if leader ~= nil then leader:remove() end
	if hookshot_hook_timer ~= nil then hookshot_hook_timer:stop(); hookshot_hook_timer = nil end
	hero:set_tunic_sprite_id("hero/item/hookshot/hookshot_moving_free_tunic"..tunic)
	hero:set_walking_speed(40)
	game:set_value("item_"..item_name.."_state", 1)
	game:set_value("item_"..item_name.."_avoid_return", false)
	game:item_finished()
  end
  
    function stop_hooked()
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
    if hookshot ~= nil then sound_timer:stop(); hookshot:remove() end
    if leader ~= nil then leader:remove() end
	if hookshot_sync ~= nil then hookshot_sync:stop(); hookshot_sync = nil end
	if hookshot_timer ~= nil then hookshot_timer:stop(); hookshot_timer = nil end
	if hookshot_hook_timer ~= nil then hookshot_hook_timer:stop(); hookshot_hook_timer = nil end
    game:item_finished()
	item:transit_to_finish()
  end

  hero:freeze()
  hero:set_tunic_sprite_id("hero/tunic"..tunic)
  hero:set_animation("hookshot_shoot")

 hookshot_hook_timer = sol.timer.start(10, function()
  hookshot_sprite_x, hookshot_sprite_y = hookshot:get_position()
  return true
  end)
  
 local correct_origin = 0
	
if hero:get_direction() == 1 then correct_origin = 1 end
  
  -- Create the hookshot.
  hookshot = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x,
    y = y - 1,
    width = 16,
    height = 16, -- 16
  })
  hookshot:set_origin(8, 12 - correct_origin)
  hookshot:set_drawn_in_y_order(true)

  -- Set up hookshot sprites.
  hookshot_sprite = hookshot:create_sprite("entities/hookshot")
  hookshot_sprite:set_direction(direction)
  link_sprite = sol.sprite.create("entities/hookshot")
  link_sprite:set_direction(direction)
  link_sprite:set_animation("link")

  function hookshot:on_pre_draw()
    -- Draw the links.
    local num_links = 24
    local dxy = {
      {  16,  -6 },
      {   0, -14 },
      { -16,  -6 },
      {   0,   6 }
    }
    local hero_x, hero_y = hero:get_position()
    local x1 = hero_x + dxy[direction + 1][1]
    local y1 = hero_y + dxy[direction + 1][2]
    local x2, y2 = hookshot:get_position()
    y2 = y2 - 5
    for i = 0, num_links - 1 do
      local link_x = x1 + (x2 - x1) * i / num_links
      local link_y = y1 + (y2 - y1) * i / num_links

      -- Skip the first one when going to the North because it overlaps
      -- the hero sprite and can be drawn above it sometimes.
      local skip = direction == 1 and link_x == hero_x and i == 0
      if not skip then
        map:draw_sprite(link_sprite, link_x, link_y)
      end
    end
  end

  -- Set what can be traversed by the hookshot.
  set_can_traverse_rules(hookshot)

  -- Set up collisions.
  hookshot:add_collision_test("overlapping", function(hookshot, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the hookshot.
      if going_back then
        stop()
      end
    elseif entity_type == "crystal" then
      -- Activate crystals.
      if not hooked and not going_back then
        sol.audio.play_sound("switch")
        map:change_crystal_state()
        go_back()
      end
    elseif entity_type == "switch" then
      -- Activate solid switches.
      local switch = entity
      local sprite = switch:get_sprite()
      if not hooked and
          not going_back and
          sprite ~= nil and
          sprite:get_animation_set() == "entities/solid_switch" then
        if switch:is_activated() then
          sol.audio.play_sound("sword_tapping")
        else
          sol.audio.play_sound("switch")
          switch:set_activated(true)
        end
        go_back()
      end
    elseif entity.is_hookshot_catchable ~= nil and entity:is_hookshot_catchable() then
      -- Catch the entity with the hookshot.
      if not hooked and not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(hookshot:get_position())
        hookshot:set_modified_ground("traversable")  -- Don't let the caught entity fall in holes.
        go_back()
      end
    end
  end)

  local hook_point_dxy = {
    {  8,  0 },
    {  0, -9 },
    { -9,  0 },
    {  0,  8 },
  }

  -- Custom collision test for hooks: there is a collision with a hook if
  -- the facing point of the hookshot overlaps the hook's bounding box.
  -- We cannot use the built-in "facing" collision mode because it would
  -- test the facing point of the hook, not the one of of the hookshot.
  -- And we cannot reverse the test because the hook is not necessarily a custom entity.
  local function test_hook_collision(hookshot, entity)
    if hooked or going_back then
      return      -- No need to check coordinates, we are already hooked.
    end

    if entity.is_hookshot_hook == nil or not entity:is_hookshot_hook() then
      return      -- Don't bother check coordinates, we don't care about this entity.
    end

    local facing_x, facing_y = hookshot:get_center_position()
    facing_x = facing_x + hook_point_dxy[direction + 1][1]
    facing_y = facing_y + hook_point_dxy[direction + 1][2]
    return entity:overlaps(facing_x, facing_y)
  end

  hookshot:add_collision_test(test_hook_collision, function(hookshot, entity)
    if hooked or going_back then
      return
    end

    if entity.is_hookshot_hook ~= nil and entity:is_hookshot_hook() then
      hook_to_entity(entity)      -- Hook to this entity.
    end
  end)

  -- Detect enemies.
  hookshot:add_collision_test("sprite", function(hookshot, entity, hookshot_sprite, enemy_sprite)
    local entity_type = entity:get_type()
    if entity_type == "enemy" then
      local enemy = entity
      if hooked then
        return
      end
      local reaction = enemy:get_attack_hookshot(enemy_sprite)
      enemy:receive_attack_consequence("hookshot", reaction)
      go_back()
    end
  end)

  -- Start the movement.
  go()
 end

-- Initialize the metatable of appropriate entities to work with the hookshot.
local function initialize_meta()

  -- Add Lua hookhost properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_attack_hookshot ~= nil then
    return    -- Already done.
  end

  enemy_meta.attack_hookshot = "immobilized"
  enemy_meta.attack_hookshot_sprite = {}
  function enemy_meta:get_attack_hookshot(sprite)
    if sprite ~= nil and self.attack_hookshot_sprite[sprite] ~= nil then
      return self.attack_hookshot_sprite[sprite]
    end
    return self.attack_hookshot
  end

  function enemy_meta:set_attack_hookshot(reaction, sprite)
    self.attack_hookshot = reaction
  end

  function enemy_meta:set_attack_hookshot_sprite(sprite, reaction)
    self.attack_hookshot_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also take into account the hookshot.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_attack_hookshot("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_attack_hookshot_sprite(sprite, "ignored")
  end

  -- Set up entity types catchable with the hookshot.
  for _, entity_type in ipairs(catchable_entity_types) do
    local meta = sol.main.get_metatable(entity_type)
    function meta:is_hookshot_catchable()
      return true
    end
  end

  -- Set up entity types hookable with the hookshot.
  for _, entity_type in ipairs(hook_entity_types) do
    local meta = sol.main.get_metatable(entity_type)
    function meta:is_hookshot_hook()
      return true
    end
  end
end

initialize_meta()