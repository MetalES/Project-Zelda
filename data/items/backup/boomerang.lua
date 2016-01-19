local item = ...
local game = item:get_game()

--TODO 
--state


local item_name = "boomerang"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

local volume_bgm = game:get_value("old_volume")
local distance = 250
local speed = 200
local catchable_entity_types = { "pickable" }
local boom_entity_types = {}

local state = 0
local can_shoot = false
local avoid_return = false
local launched = false
local is_finished = false

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."possession")
  self:set_assignable(true)
  game:set_value("item_"..item_name.."_state", 0)
  game:set_value("item_"..item_name.."_can_shoot", false)
  game:set_value("item_"..item_name.."_avoid_return", false)
  game:set_value("item_"..item_name.."_launched", false)
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

function item:transit_to_finish()
local hero = game:get_hero()
hero:freeze()

hero:set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield"))
game:set_ability("shield", game:get_value("item_saved_shield"))
game:set_ability("sword", game:get_value("item_saved_sword")); 
item:set_finished(); 
game:set_pause_allowed(true)

if boomerang_timer ~= nil then boomerang_timer:stop(); boomerang_timer = nil end
if boomerang_sync ~= nil then boomerang_sync:stop(); boomerang_sync = nil end
        
game:set_custom_command_effect("attack", nil)

hero:freeze()
hero:set_walking_speed(88)

sol.audio.play_sound("common/item_show")

hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))

if show_bars == true and not starting_cutscene then game:hide_bars() end

hero:unfreeze(); 
game:set_value("is_finished", true)
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

function item:on_using()
  local hero = game:get_hero()
  local tunic = game:get_value("item_saved_tunic")
  
  local function end_by_collision() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if show_bars == true and not starting_cutscene then game:hide_bars() end; item:set_finished(); game:set_pause_allowed(true) end
  local function end_by_stairs() hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); if show_bars == true and not starting_cutscene then game:hide_bars() end; item:set_finished(); game:set_pause_allowed(true) end
  local function end_by_pickable() hero:set_animation("brandish"); hero:set_walking_speed(88); game:set_custom_command_effect("attack", nil); game:set_ability("sword", game:get_value("item_saved_sword")); game:set_ability("shield", game:get_value("item_saved_shield")); item:set_finished(); game:set_pause_allowed(true) end
  
    -- read the 2 item slot.
  if game:get_value("_item_slot_1") == item_name then slot = "item_1"
  elseif game:get_value("_item_slot_2") == item_name then slot = "item_2" end
  game:set_value("is_finished", false)
  
  if game:get_value("item_"..item_name.."_state") == 0 then 
  
	self:store_equipment()
	if not show_bars then game:show_bars() end
	sol.audio.play_sound("common/bars_dungeon")
	
	sol.timer.start(60, function()	
	    hero:set_walking_speed(40)
		hero:unfreeze()
		game:set_value("item_"..item_name.."_state", 1)
		-- hero:set_tunic_sprite_id("hero/item/hookshot/hookshot_moving_free_tunic"..tunic)
		boomerang_sync = sol.timer.start(10, function()
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
 
			if hero:get_state() == "hurt" then game:set_value("is_finished", true); hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:start_hurt(0,0,0); end_by_collision() end
			if hero:get_state() == "jumping" or hero:get_state() == "swimming" then game:set_value("is_finished", true); hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
			if hero:get_state() == "falling" then game:set_value("is_finished", true); hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_collision() end
			if hero:get_state() == "treasure" then game:set_value("is_finished", true); hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_pickable() end
			if hero:get_state() == "stairs" then game:set_value("is_finished", true); hero:unfreeze(); hero:set_tunic_sprite_id("hero/tunic"..tunic); end_by_stairs() end
			
			if game:is_command_pressed("attack") and game:get_value("item_"..item_name.."_avoid_return") ~= true then
			game:set_value("is_finished", true)
			if boomerang_timer ~= nil then boomerang_timer:stop(); boomerang_timer = nil; item:transit_to_finish() end
			if boomerang_sync ~= nil then boomerang_sync:stop(); boomerang_sync = nil; item:transit_to_finish() end
			end
			
		   return true
		   end)
	end)
	
elseif game:get_value("item_"..item_name.."_state") == 1 then
hero:unfreeze()
  
	if game:is_command_pressed(slot) and not starting_cutscene then 
	    hero:set_walking_speed(33)
		if game:get_value("item_"..item_name.."_launched") ~= true then
		game:set_value("item_"..item_name.."_can_shoot", true)
		game:set_value("item_"..item_name.."_avoid_return", true)
		hero:set_animation("boomerang_intro")
		sol.audio.play_sound("common/item_show")
		sol.timer.start(40, function()
		hero:unfreeze()
		hero:set_tunic_sprite_id("hero/item/boomerang/boomerang_moving_armed_tunic_"..tunic)
		game:set_value("item_"..item_name.."_avoid_return", false)
		end)
		end
	end
	
boomerang_timer = sol.timer.start(10, function()
	if not game:is_command_pressed(slot) and game:get_value("item_"..item_name.."_can_shoot") == true and not game:get_value("item_"..item_name.."_avoid_return") and not starting_cutscene then
		hero:set_walking_speed(50)
		if boomerang_timer ~= nil then boomerang_timer:stop() boomerang_timer = nil
			if game:get_value("item_"..item_name.."_launched") ~= true then
			hero:freeze()
			hero:set_tunic_sprite_id("hero/tunic"..tunic)
			hero:set_animation("boomerang_shoot")
			sol.timer.start(80, function()
				sol.audio.play_sound("characters/link/voice/throw0")
				sol.audio.play_sound(sound_dir.."firing_start0")
				item:shoot_boomerang()
			end)
			else 
			hero:unfreeze()
			end
		end
	end
return true
end)

end
end
    -- hero:start_boomerang(128, 160, "boomerang1", "entities/boomerang1"

function item:set_finished()
		if boomerang_sync ~= nil then boomerang_sync:stop(); boomerang_sync = nil end
		if boomerang_timer ~= nil then boomerang_timer:stop(); boomerang_timer = nil end

		game:set_value("item_"..item_name.."_can_shoot", false)
		game:set_value("item_"..item_name.."_state", 0)
		game:set_value("item_"..item_name.."_avoid_return", false)
		game:set_value("item_"..item_name.."_launched", false)
		game:set_value("is_finished", true)
		
		game:set_custom_command_effect("attack", nil)
		game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
		game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot"))
		game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot"))
		game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
		game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
		game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
end

function item:shoot_boomerang()
  local going_back = false
  local sound_timer
  local direction
  local map = item:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  local boomerang 
  local boomrang_sprite
  local entities_caught = {}
  local hooked_entity
  local go
  local go_back
  local stop
  local boomerang_hook_timer
  local boomerang_sprite_x, boomerang_sprite_y = x, y
  local boomerang_trail
  local tunic = game:get_value("item_saved_tunic")
  
  game:set_value("item_"..item_name.."_launched", true)
  game:set_pause_allowed(false)
  
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
  
  function go()
    local movement = sol.movement.create("straight")
    local angle = direction * math.pi / 2
    movement:set_speed(speed)
    movement:set_angle(angle)
    movement:set_smooth(false)
    movement:set_max_distance(distance)
    movement:start(boomerang)
	
	-- temporarly disable the item slot
	if game:get_value("_item_slot_1") == item_name then game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil) end
	if game:get_value("_item_slot_2") == item_name then game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil) end

    function movement:on_obstacle_reached()
	if boomerang_hook_timer ~= nil then boomerang_hook_timer:stop() end
	
	local link_boom_x, link_boom_y
	
	if hero:get_direction() == 0 then link_boom_x = 10; link_boom_y = -5 
	elseif hero:get_direction() == 1 then link_boom_x = 0; link_boom_y = -15
    elseif hero:get_direction() == 2 then link_boom_x = -10; link_boom_y = -5
	elseif hero:get_direction() == 3 then link_boom_x = 0; link_boom_y = 5
    else link_boom_x, link_boom_y = 0	end
	
	local collision_effect = map:create_custom_entity({
      x = boomerang_sprite_x + link_boom_x,
      y = boomerang_sprite_y + link_boom_y,
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
    sound_timer = sol.timer.start(map, 200, function() --150  62
      sol.audio.play_sound(sound_dir.."firing_loop")
      return true  -- Repeat the timer.
    end)
    sol.audio.play_sound(sound_dir.."firing_start")
	
	-- play a fancy trail animation 
	boomerang_trail = sol.timer.start(50, function()
		local lx, ly, llayer = boomerang:get_position()
			local trail = game:get_map():create_custom_entity({
				x = lx,
				y = ly,
				layer = llayer,
				direction = 0,
				sprite = "entities/boomerang1",
			    })
			trail:get_sprite():set_frame_delay(40)
			trail:get_sprite():fade_out(6, function() trail:remove() end)
		return true
		end)
  end
  
    function go_back()
    if going_back then
      return
    end
	
    local movement = sol.movement.create("target")
    movement:set_speed(speed)
	movement:set_target(hero)
    movement:set_smooth(false)
    movement:set_ignore_obstacles(true)
    movement:start(boomerang)
    going_back = true

    function movement:on_position_changed()
      for _, entity in ipairs(entities_caught) do
        entity:set_position(boomerang:get_position())
      end
    end

    function movement:on_finished()
      stop()
    end
  end
  
  
   function stop()
    if boomerang ~= nil then sound_timer:stop(); boomerang:remove() end
	if boomerang_hook_timer ~= nil then boomerang_hook_timer:stop(); boomerang_hook_timer = nil end
	if boomerang_trail ~= nil then boomerang_trail:stop(); boomerang_trail = nil end
		
		
--todo add 
if hero:get_state() ~= "swimming" and hero:get_state() ~= "hurt" and hero:get_state() ~= "jumping" and hero:get_state() ~= "falling" and hero:get_state() ~= "treasure" and hero:get_state() ~= "stairs" and game:get_value("starting_cutscene") ~= true and game:get_value("using_item") ~= true and hero:get_tunic_sprite_id() == "hero/tunic"..tunic and game:get_value("using_item") ~= true then hero:freeze(); hero:set_animation("boomerang_catch"); sol.audio.play_sound("characters/link/voice/catch_boomerang") end
	-- restore item binding
sol.timer.start(120, function()
	if game:get_value("is_finished") ~= true then 
		if game:get_value("_item_slot_1") == item_name then game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot")); game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot")) end
		if game:get_value("_item_slot_2") == item_name then game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot")); game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot")) end
		
		hero:set_walking_speed(50)
		game:set_value("item_"..item_name.."_state", 1)
		game:set_value("item_"..item_name.."_launched", false)
		game:set_value("item_"..item_name.."_can_shoot", false)
		game:set_value("item_"..item_name.."_avoid_return", false)
		hero:unfreeze()
		else
		game:set_value("item_"..item_name.."_state", 0)
		game:set_value("item_"..item_name.."_launched", false)
		game:set_value("item_"..item_name.."_can_shoot", false)
		game:set_value("item_"..item_name.."_avoid_return", false)
	    if hero:get_state() ~= "swimming" and hero:get_state() ~= "hurt" and hero:get_state() ~= "jumping" and hero:get_state() ~= "falling" and hero:get_state() ~= "treasure" and hero:get_state() ~= "stairs" and game:get_value("starting_cutscene") ~= true and game:get_value("using_item") ~= true and hero:get_tunic_sprite_id() == "hero/tunic"..tunic and game:get_value("using_item") ~= true then hero:unfreeze() end
		item:set_finished()
    end
sol.audio.play_sound("common/item_show")
end)
  end
   
  hero:freeze()
  hero:set_tunic_sprite_id("hero/tunic"..tunic)
  hero:set_animation("stopped")
  hero:unfreeze()
  
 boomerang_hook_timer = sol.timer.start(10, function()
  boomerang_sprite_x, boomerang_sprite_y = boomerang:get_position()
  return true
  end)
  
  -- Create the boomerang.
  
  	local link_boom_correct_x, link_boom_correct_y
	local correct_origin = 0
	
	if hero:get_direction() == 0 then link_boom_correct_x = 10; link_boom_correct_y = -5 
	elseif hero:get_direction() == 1 then link_boom_correct_x = 0; link_boom_correct_y = -15; correct_origin = 6
    elseif hero:get_direction() == 2 then link_boom_correct_x = -10; link_boom_correct_y = -5
	elseif hero:get_direction() == 3 then link_boom_correct_x = 0; link_boom_correct_y = 5
    else link_boom_correct_x, link_boom_correct_y = 0	end
	
	
  boomerang = map:create_custom_entity({
    direction = direction,
    layer = layer,
    x = x + link_boom_correct_x,
    y = y + link_boom_correct_y,
    width = 16,
    height = 16,
  })
  boomerang:set_origin(8, 8 + correct_origin)
  boomerang:set_drawn_in_y_order(true)

  -- Set up boomerang sprites.
  boomerang_sprite = boomerang:create_sprite("entities/boomerang1")
  boomerang_sprite:set_direction(0)
  
    -- Set what can be traversed by the boomerang.
  set_can_traverse_rules(boomerang)

  -- Set up collisions.
  boomerang:add_collision_test("overlapping", function(boomerang, entity)
    local entity_type = entity:get_type()
    if entity_type == "hero" then
      -- Reaching the hero while going back: stop the boomerang.
      if going_back then
        stop()
      end
    elseif entity_type == "crystal" then
      -- Activate crystals.
      if not hooked and not going_back then
        sol.audio.play_sound("switch") ------------------------ todo
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
    elseif entity.is_boomerang_catchable ~= nil and entity:is_boomerang_catchable() then
      -- Catch the entity with the boomerang.
      if not hooked and not going_back then
        entities_caught[#entities_caught + 1] = entity
        entity:set_position(boomerang:get_position())
        boomerang:set_modified_ground("traversable")  -- Don't let the caught entity fall in holes.
        go_back()
      end
    end
  end)
  
  -- Detect enemies.
  boomerang:add_collision_test("sprite", function(boomerang, entity, boomerang_sprite, enemy_sprite)
    local entity_type = entity:get_type()
    if entity_type == "enemy" then
      local enemy = entity
      if hooked then
        return
      end
      local reaction = enemy:get_attack_boomerang(enemy_sprite)
      enemy:receive_attack_consequence("boomerang", reaction)
      go_back()
    end
  end)

  -- Start the movement.
  go()
end


-- Initialize the metatable of appropriate entities to work with the boomerang.
local function initialize_meta()

  -- Add Lua boomerang properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_attack_boomerang ~= nil then
    return    -- Already done.
  end

  enemy_meta.attack_boomerang = "immobilized"
  enemy_meta.attack_boomerang_sprite = {}
  function enemy_meta:get_attack_boomerang(sprite)
    if sprite ~= nil and self.attack_boomerang_sprite[sprite] ~= nil then
      return self.attack_boomerang_sprite[sprite]
    end
    return self.attack_boomerang
  end

  function enemy_meta:set_attack_boomerang(reaction, sprite)
    self.attack_boomerang = reaction
  end

  function enemy_meta:set_attack_boomerang_sprite(sprite, reaction)
    self.attack_boomerang_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also take into account the hookshot.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_attack_boomerang("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_attack_boomerang_sprite(sprite, "ignored")
  end

  -- Set up entity types catchable with the hookshot.
  for _, entity_type in ipairs(catchable_entity_types) do
    local meta = sol.main.get_metatable(entity_type)
    function meta:is_boomerang_catchable()
      return true
    end
  end
end

initialize_meta()