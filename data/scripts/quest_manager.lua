local quest_manager = {}
local is_stopped -- global to this script
local is_walking

-- This script handles global behavior of this quest,
-- that is, things not related to a particular savegame.

-- Initialize the behavior of destructible entities.
local function initialize_destructibles()
  local destructible_meta = sol.main.get_metatable("destructible")
  
  function destructible_meta:on_looked()
    -- Here, self is the destructible object.
    local game = self:get_game()
    if self:get_can_be_cut() and not self:get_can_explode() and not self:get_game():has_ability("sword") then
      -- The destructible can be cut, but the player no cut ability.
      game:start_dialog("gameplay.logic._cannot_lift_should_cut");
    elseif not game:has_ability("lift") then
      -- No lift ability at all.
      game:start_dialog("gameplay.logic._cannot_lift_too_heavy");
    else
      -- Not enough lift ability.
      game:start_dialog("gameplay.logic._cannot_lift_still_too_heavy");
    end
  end
end

-- Initialize sensor behavior specific to this quest.
local function initialize_sensors()
  local sensor_meta = sol.main.get_metatable("sensor")

  function sensor_meta:on_activated()
    local game = self:get_game()
    local hero = self:get_map():get_hero()
    local name = self:get_name()
    local dungeon = game:get_dungeon()
	
	-- Sensors named "to_layer_X_sensor" move the hero on that layer.
    if name:match("^layer_up_sensor") then
      local x, y, layer = hero:get_position()
      if layer < 2 then hero:set_position(x, y, layer + 1) end
    elseif name:match("^layer_down_sensor") then
      local x, y, layer = hero:get_position()
      if layer > 0 then hero:set_position(x, y, layer - 1) end
    end

    -- Sensors prefixed by "dungeon_room_N_" save exploration state of room "N" of current dungeon floor.
    -- Optional treasure savegame value appended to end will play signal chime if value is false and hero has compass in inventory. "dungeon_room_N_bxxx"
    local room = name:match("^dungeon_room_(%d+)")
    local signal = name:match("(%U%d+)$")
    if room ~= nil then
      game:set_explored_dungeon_room(nil, nil, tonumber(room))
      if signal ~= nil and not game:get_value(signal) then
        if game:has_dungeon_compass(game:get_dungeon_index()) then
          sol.audio.play_sound("signal")
        end
      end
    end
  end
end


-- Initialize the behavior of enemies.
local function initialize_enemies()
  local enemy_meta = sol.main.get_metatable("enemy")

  -- Enemies: redefine the damage of the hero's sword. (The default damages are less important.)
  function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)
    -- Here, self is the enemy.
    local game = self:get_game()
	local hero_mode = game:get_value("hero_mode")
    local sword = game:get_ability("sword")
	local damage_factors = { 1, 2, 4, 8 }  -- Damage factor of each sword.
    local damage_factor = damage_factors[sword]
	
	if hero:get_state() == "sword spin attack" then
	  if hero_mode then
	    damage_factor = damage_factor
	  else
	    damage_factor = damage_factor * 2  -- The spin attack is twice as powerful, but costs more stamina.
	  end
	end
	
	if hero:get_state() == "sword swinging" then
	  if hero_mode then
	    damage_factor =  damage_factor / 2 -- damage are ridiculous
	  else
	    damage_factor = damage_factor  -- Dafault damage value
	  end
	end
		
    local reaction = self:get_attack_consequence_sprite(enemy_sprite, "sword")
    self:remove_life(reaction * damage_factor)
  end

  -- Helper function to inflict an explicit reaction from a scripted weapon.
  function enemy_meta:receive_attack_consequence(attack, reaction)
    if type(reaction) == "number" then
      self:hurt(reaction)
    elseif reaction == "immobilized" then
      self:immobilize()
    elseif reaction == "protected" then
      sol.audio.play_sound("sword_tapping")
    elseif reaction == "custom" then
      if self.on_custom_attack_received ~= nil then
        self:on_custom_attack_received(attack)
      end
    end
  end
end

-- Initialize NPC behavior specific to this quest.
local function initialize_npcs()
  local npc_meta = sol.main.get_metatable("npc")

  -- Give default dialog styles to certain entities.
  function npc_meta:on_interaction()
    local name = self:get_name()
	local game = self:get_game()
    if name:match("^sign_") then game:set_dialog_style("wood")
    elseif name:match("^mailbox_") then game:set_dialog_style("wood")
    elseif name:match("^hint_") then game:set_dialog_style("stone")
    else game:set_dialog_style("default") end
  end

  -- Make certain entities automatic hooks for the hookshot.
  function npc_meta:is_hookshot_hook()
    if self:get_sprite() ~= nil then
      if self:get_sprite():get_animation_set() == "entities/sign" then return true
      elseif self:get_sprite():get_animation_set() == "entities/mailbox" then return true
      elseif self:get_sprite():get_animation_set() == "entities/pot" then return true
      elseif self:get_sprite():get_animation_set() == "entities/block" then return true
      elseif self:get_sprite():get_animation_set() == "entities/chest" then return true
      elseif self:get_sprite():get_animation_set() == "entities/chest_big" then return true
      elseif self:get_sprite():get_animation_set() == "entities/torch" then return true
      elseif self:get_sprite():get_animation_set() == "entities/torch_wood" then return true
      else return false end
    else return false end
  end
end

-- Initialize map entity related behaviors.
local function initialize_entities()
  initialize_destructibles()
  initialize_enemies()
  initialize_sensors()
  initialize_npcs()
end

local function initialize_timer()
  local timer_meta = sol.main.get_metatable("timer")
  local timer
  local timer2
  local timer3
  local timer4
  
  
  function timer_meta:set_with_sound_effect(boolean)  
    if boolean == true then
	
	-- if another switch is pressed, then stop the timer 1,  2 and 3.
	   if timer ~= nil then timer:stop() end 
	   if timer2 ~= nil then timer2:stop() end
	   if timer3 ~= nil then timer3:stop() end
	   if timer4 ~= nil then timer4:stop() end
		
	   sol.audio.play_sound("timer")
	   timer = sol.timer.start(self, 1525, function()
	     if self:get_remaining_time()  > 6100 and not sol.main.game:is_paused() then --7500
		  sol.audio.play_sound("timer")
		 end
		  return true
		end)
		
		timer2 = sol.timer.start(self, 755, function()
		  if self:get_remaining_time() <= 6100 and self:get_remaining_time() >= 3465 and not sol.main.game:is_paused() then
		     timer:stop()
		     sol.audio.play_sound("timer_hurry")
		  end
		return true
		end)
		
		timer3 = sol.timer.start(self, 380, function()
		  if self:get_remaining_time() <= 3080 and not sol.main.game:is_paused() then --3500
		     timer2:stop()
		     sol.audio.play_sound("timer_almost_end")
		  end
		return true
		end)
		
		timer4 = sol.timer.start(self, 30, function()
		 if self:get_remaining_time() <= 6100 and self:get_remaining_time() >= 3465 then timer:stop() end
		 if self:get_remaining_time() <= 3080 then timer2:stop() end
		  if self:get_remaining_time() == 0 and not sol.main.game:is_paused() then
		    timer3:stop()
			if sol.audio.get_music_volume() ~= sol.main.game:get_value("old_volume") then sol.audio.set_music_volume(sol.main.game:get_value("old_volume")) end
		    if timer ~= nil then timer:stop() end
			if timer2 ~= nil then timer2:stop() end
		    if timer3 ~= nil then timer3:stop() end
			if timer4 ~= nil then timer4:stop(); return false end
		  end
		return true
		end)
		
	  end
    end
end

local function initialize_maps()
  local map_metatable = sol.main.get_metatable("map")
  local heat_timer, swim_timer
  
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
    if self:get_game():get_hero():get_state() == "swimming" then
	-- Fancy effect
	if not swimming_trail and self:get_game():get_value("item_cloak_darkness_state") == 0 then
			swimming_trail = sol.timer.start(50, function()
				local lx, ly, llayer = self:get_game():get_hero():get_position()
				local trail = self:get_game():get_map():create_custom_entity({
						x = lx,
						y = ly,
						layer = llayer,
						direction = self:get_game():get_hero():get_direction(),
						sprite = "effects/hero/swimming_trails",
						})
					trail:get_sprite():set_animation(self:get_game():get_hero():get_animation())
					trail:get_sprite():fade_out(12, function() trail:remove() end)
			return true
		end)
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
  
  function map_metatable:on_finished()
	self:get_game():clear_map_name()
	self:get_game():clear_fog()
  end

end

local function initialize_hero()
local hero_meta = sol.main.get_metatable("hero")
local was_loading
local pushing_timer, pulling_timer
local pulling_snd_timer, pushing_snd_timer, low_life_snd_timer


function hero_meta:on_taking_damage(damage)
    local damage = damage
	local game = self:get_game()
	local hero_mode = game:get_value("hero_mode")
	
	print("taking damage")

    if self:is_condition_active('frozen') then
      damage = damage * 3
      self:stop_frozen(true)
    end

    if damage < 1 then
      damage = 1
    end
	
	local shield = game:get_ability("shield")
	
	if hero_mode then
	  if shield > 1 then
	    damage = math.floor(damage / (shield / 3))
		print(damage)
	  else 
	    damage = damage * 2
		print(damage)
	  end
	else 
	  if shield > 1 then
	    damage = math.floor(damage / shield)
		print(damage)
	  else
	    damage = damage
	  end
	end
	
	-- if hero_mode then
	-- damage = damage * 2
	-- else 
	  -- damage = damage
	-- end  
	-- game:remove_life(damage)

    game:remove_life(damage)

end

  -- Used for Pushing / Pulling state
local function stop_pushing_pulling()
  if pushing_timer ~= nil then pushing_timer:stop(); pushing_timer = nil end
  if pulling_timer ~= nil then pulling_timer:stop(); pulling_timer = nil end
  if pushing_snd_timer ~= nil then pushing_snd_timer:stop(); pushing_snd_timer = nil end
  if pulling_snd_timer ~= nil then pulling_snd_timer:stop(); pulling_snd_timer = nil end
end

  -- On state changed : Tell the game what to do if the state changed
function hero_meta:on_state_changed(state)
	local random_sword_snd = math.random(4)
	local random_sword_spin_snd = math.random(2)

	if state == "sword swinging" then 
	  --sword sound
	local game = self:get_game()
		if game:get_value("item_cloak_darkness_state") ~= 0 then
			  self:set_sword_sound_id("characters/link/voice/cloak_attack"..random_sword_snd)
		else
			  self:set_sword_sound_id("characters/link/voice/attack"..random_sword_snd)
		end
	  -- skill 3
    if game:get_life() <= game:get_max_life() / 4 and game:get_ability("sword") > 1 and game:get_value("skill_3_learned") == true then
		local direction = self:get_direction()
		local dx, dy
		local x, y, layer = self:get_position()
		if direction == 0 then
			 dx, dy = 8, -5
		elseif direction == 1 then
			 dx, dy = 0, -12
		elseif direction == 2 then
			dx, dy = -8, -5
		else dx, dy = 0, 0
		end
		local perish_beam = game:get_map():create_custom_entity({
			 model = "perish_beam",
			 x = x + dx,
			 y = y + dy,
			 layer = layer,
			 direction = direction,
			 })
		perish_beam:go()	 
	  --skill 4
	elseif game:get_life() == game:get_max_life() and game:get_ability("sword") > 1 and game:get_value("skill_4_learned") == true then
		local direction = self:get_direction()
		local dx, dy
		local x, y, layer = self:get_position()
	 	if direction == 0 then
			 dx, dy = 8, -5
	 	elseif direction == 1 then
			 dx, dy = 0, -12
		elseif direction == 2 then
		     dx, dy = -8, -5
		else dx, dy = 0, 0
		end
		local perish_beam = game:get_map():create_custom_entity({
			 model = "perish_beam",
			 x = x + dx,
			 y = y + dy,
			 layer = layer,
			 direction = direction,
			 })
		perish_beam:go()
	  end
	  
	elseif state == "sword loading" then
	    local game = self:get_game()
		stop_pushing_pulling()
		if not game:get_value("skill_1_learned") then
		   game:simulate_command_released("attack")
		else
			self:set_walking_speed(44)
			was_loading = true
		end
	  
	elseif state == "sword spin attack" then
	    local game = self:get_game()
		if game:get_value("item_cloak_darkness_state") ~= 0 then
		  sol.audio.play_sound("characters/link/voice/cloak_spin"..random_sword_spin_snd)
		else
		  sol.audio.play_sound("characters/link/voice/spin"..random_sword_spin_snd)
		end
		
	elseif state == "hurt" then
		sol.audio.play_sound("characters/link/voice/hurt"..random_sword_spin_snd)

	elseif state == "free" then	
		stop_pushing_pulling()
		if was_loading then self:set_walking_speed(88); was_loading = false end
		
    elseif state == "grabbing" then
		stop_pushing_pulling()
			
	elseif state == "pushing" then
	  if pulling_timer ~= nil then pulling_timer:stop(); pulling_timer = nil end
	  if pulling_snd_timer ~= nil then pulling_snd_timer:stop(); pulling_snd_timer = nil end
	  sol.audio.play_sound("characters/link/voice/push")
	  
	  sol.timer.start(50, function()
	    sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	  end)
	  pushing_timer = sol.timer.start(2500, function()
		self:set_animation("pushing_state2")
	   end)
	  pushing_snd_timer = sol.timer.start(500, function()
	    sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	    return true
	  end)	   
	  
	elseif state == "pulling" then
	  if pushing_timer ~= nil then pushing_timer:stop(); pushing_timer = nil end
	  if pushing_snd_timer ~= nil then pushing_snd_timer:stop(); pushing_snd_timer = nil end
	  
	  sol.timer.start(50, function()
	    sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	  end)
	  sol.audio.play_sound("characters/link/voice/push")
	  pulling_timer = sol.timer.start(2500, function()
		self:set_animation("pulling_state2")
	  end)	
	  pulling_snd_timer = sol.timer.start(500, function()
	     sol.audio.play_sound("characters/link/effect/push_pull_step_effect")
	     return true
	   end)
	   
	elseif state == "jumping" then
	    sol.audio.play_sound("characters/link/voice/jump")

	end	
  end 

-- Custom Functions  
-- Teleport_to, nothing more, it's just hero:teleport(), just with a function that check if we are in hero mode
  function hero_meta:teleport_to(map_id, destination, transition)
    local map_id = map_id
	local destination = destination
	local transition = transition or "fade"
	local dest_map

  	if sol.main.game:get_value("hero_mode") then
     dest_map = "mirror"
	else 
	 dest_map = "normal"
    end
    self:teleport(dest_map.."/"..map_id, destination, transition)
  end
end

local function initialize_sprite()
local sprite_meta = sol.main.get_metatable("sprite")

-- This part is reserved for later. Implementing rolling function depending on the animation.

-- the rolling animation should be enabled, no matter the frame of the animation, on animation changed is only called when the new animation start at frame 0
	-- function sprite_meta:on_frame_changed(animation, frame)
	   -- local game = sol.main.game
	   -- for frame = 0, 7 do
		   -- local game = sol.main.game
		   -- local hero = game:get_hero()
		   -- local x, y, layer = hero:get_position() --these are not necessary but custom entity need layer, x and y
			 -- if self:get_animation_set() == "hero/tunic1" or self:get_animation_set() == "hero/tunic2" or self:get_animation_set() == "hero/tunic3"  
			   -- and self:get_animation() == "walking" or self:get_animation() == "walking_with_shield"
			     -- and game:is_command_pressed("action") then
			   -- print("roll")
				-- local roll = game:get_map():create_custom_entity({
				-- x = x, 
				-- y = y,
				-- layer = layer,
				-- model = "/hero/roll", --TODO MAKE THE ROLLL USING PBEAM MOVEMENT
				-- })
				-- roll:start()
			 -- end
		-- end
	-- end
end
 
local function initialize_game()
  local game_metatable = sol.main.get_metatable("game")

  -- Stamina functions mirror magic and life functions.
  function game_metatable:get_stamina()
    return self:get_value("i1024")
  end

  function game_metatable:set_stamina(value)
    if value > self:get_max_stamina() then value = self:get_max_stamina() end
    return self:set_value("i1024", value)
  end

  function game_metatable:add_stamina(value)
    local stamina = self:get_value("i1024") + value
    if value >= 0 then
      if stamina > self:get_max_stamina() then stamina = self:get_max_stamina() end
      return self:set_value("i1024", stamina)
    end
  end

  function game_metatable:remove_stamina(value)
    local stamina = self:get_value("i1024") - value
    if value >= 0 then
      if stamina < 0 then stamina = 0 end
      return self:set_value("i1024", stamina)
    end
  end

  function game_metatable:get_max_stamina()
    return self:get_value("i1025")
  end

  function game_metatable:set_max_stamina(value)
    if value >= 20 then
      return self:set_value("i1025", value)
    end
  end

  function game_metatable:add_max_stamina(value)
    local stamina = self:get_value("i1025")
    if value > 0 then
      return self:set_value("i1025", stamina+value)
    end
  end

  function game_metatable:get_random_map_position()
    function random_8(lower, upper)
      math.randomseed(os.time())
      return math.random(math.ceil(lower/8), math.floor(upper/8))*8
    end
    function random_points()
      local x = random_8(1, 1120)
      local y = random_8(1, 1120)
      if self:get_map():get_ground(x,y,1) ~= "traversable" then
         random_points()
      else
        return x,y
      end
    end
  end  
end

-- Performs global initializations specific to this quest.
function quest_manager:initialize_quest()
  initialize_game()
  initialize_sprite()
  initialize_timer()
  initialize_maps()
  initialize_hero()
  initialize_entities()
end

return quest_manager