local quest_manager = {}

-- This script handles global behavior of this quest,
-- that is, things not related to a particular savegame.

-- Stamina replaced by plunging meter

-- Initialize the behavior of destructible entities.
local function initialize_destructibles()
  local destructible_meta = sol.main.get_metatable("destructible")

  function destructible_meta:on_looked()
    -- Here, self is the destructible object.
    local game = self:get_game()
    if self:get_can_be_cut()
        and not self:get_can_explode()
        and not self:get_game():has_ability("sword") then
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
    local sword = game:get_ability("sword")
    local damage_factors = { 1, 2, 4, 8 }  -- Damage factor of each sword.
    local damage_factor = damage_factors[sword]
    if hero:get_state() == "sword spin attack" then
      damage_factor = damage_factor * 2  -- The spin attack is twice as powerful, but costs more stamina.
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

local function initialize_maps()
  local map_metatable = sol.main.get_metatable("map")
  local night_overlay = nil
  local heat_timer, swim_timer

  function map_metatable:on_draw(dst_surface)
    -- Put the night overlay on any outdoor map if it's night time.
    if (self:get_game():is_in_outside_world() and self:get_game():get_time_of_day() == "night") or
	(self:get_world() == "dungeon_2" and self:get_id() == "20" and self:get_game():get_time_of_day() == "night") or
	(self:get_world() == "dungeon_2" and self:get_id() == "21" and self:get_game():get_time_of_day() == "night") or
	(self:get_world() == "dungeon_2" and self:get_id() == "22" and self:get_game():get_time_of_day() == "night") then
      if night_overlay == nil then
        night_overlay = sol.surface.create(320, 240)
        night_overlay:fill_color{0, 51, 102}
        night_overlay:set_opacity(0.45 * 255)
        night_overlay:draw(dst_surface)
      else
        night_overlay:draw(dst_surface)
      end
    end
  end

  function map_metatable:on_started(destination)
    local game = self:get_game()

    function random_8(lower, upper)
      math.randomseed(os.time() - os.clock() * 1000)
      return math.random(math.ceil(lower/8), math.floor(upper/8))*8
    end

    -- Night time is more dangerous - add various enemies.
    if game:get_map():get_world() == "outside_world" and
    game:get_time_of_day() == "night" then
      local keese_random = math.random()
      if keese_random < 0.7 then
	local ex = random_8(1,1120)
	local ey = random_8(1,1120)
	self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	sol.timer.start(self, 1100, function()
	  local ex = random_8(1,1120)
	  local ey = random_8(1,1120)
	  self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	end)
      elseif keese_random >= 0.7 then
	local ex = random_8(1,1120)
	local ey = random_8(1,1120)
	self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	sol.timer.start(self, 1100, function()
	  local ex = random_8(1,1120)
	  local ey = random_8(1,1120)
	  self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	end)
	sol.timer.start(self, 1100, function()
	  local ex = random_8(1,1120)
	  local ey = random_8(1,1120)
	  self:create_enemy({ breed="keese", x=ex, y=ey, layer=2, direction=1 })
	end)
      end
      local poe_random = math.random()
      if poe_random <= 0.5 then
	local ex = random_8(1,1120)
	local ey = random_8(1,1120)
	self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
      elseif keese_random <= 0.2 then
	local ex = random_8(1,1120)
	local ey = random_8(1,1120)
	self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
	sol.timer.start(self, 1100, function()
	  local ex = random_8(1,1120)
	  local ey = random_8(1,1120)
	  self:create_enemy({ breed="poe", x=ex, y=ey, layer=2, direction=1 })
	end)
      end
      local redead_random = math.random()
      if poe_random <= 0.1 then
	local ex = random_8(1,1120)
	local ey = random_8(1,1120)
	self:create_enemy({ breed="redead", x=ex, y=ey, layer=0, direction=1 })
      end
    end

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
	 
	local random_sword_snd = math.random(4)
	local random_sword_spin_snd = math.random(2)
	local random_hurt_snd = math.random(2)
	
	if self:get_game():get_value("item_cloak_darkness_state") ~= 0 then
	self:get_hero():set_sword_sound_id("characters/link/voice/cloak_attack"..random_sword_snd)
	else
    self:get_hero():set_sword_sound_id("characters/link/voice/attack"..random_sword_snd)
    end
	
	if self:get_hero():get_state() == "sword spin attack" then
	if not spin_attack_timer then
	    spin_attack_timer = sol.timer.start(10, function() 
		if self:get_game():get_value("item_cloak_darkness_state") ~= 0 then
		sol.audio.play_sound("characters/link/voice/cloak_spin"..random_sword_spin_snd)
		else
		sol.audio.play_sound("characters/link/voice/spin"..random_sword_spin_snd)
        end
		end)
		sol.timer.start(700, function() self:get_game():get_hero():set_walking_speed(88) spin_attack_timer:stop(); spin_attack_timer = nil end)
	end
    end
	
  if self:get_hero():get_state() == "sword loading" then
	if not loading_timer then
	    loading_timer = sol.timer.start(10, function() 
		if self:get_game():is_command_pressed("attack") then
		self:get_game():get_hero():set_walking_speed(44)
		else
		self:get_game():get_hero():set_walking_speed(88)
        sol.timer.start(10, function() if loading_timer ~= nil then loading_timer:stop(); loading_timer = nil end end)
		end
		return true
		end)
	end
    end
	
	if self:get_hero():get_state() == "hurt" then
	if not hurt_timer then
	    hurt_timer = sol.timer.start(10, function() sol.audio.play_sound("characters/link/voice/hurt"..random_hurt_snd) end)
		sol.timer.start(500, function() hurt_timer:stop(); hurt_timer = nil end)
	end
    end	
	end
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
    stamina = self:get_value("i1024") + value
    if value >= 0 then
      if stamina > self:get_max_stamina() then stamina = self:get_max_stamina() end
      return self:set_value("i1024", stamina)
    end
  end

  function game_metatable:remove_stamina(value)
    stamina = self:get_value("i1024") - value
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
    stamina = self:get_value("i1025")
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
  initialize_maps()
  initialize_entities()
end

return quest_manager