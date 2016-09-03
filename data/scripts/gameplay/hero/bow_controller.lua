local bow_controller = {
  slot = "item_1",
  opposite_slot = "item_2",
  state = 0,
  item = nil
}

-- Set which build-in hero state can interrupt this item
local state = {"swimming", "jumping", "falling", "stairs" , "hurt", "plunging", "treasure"}
-- Set which item is compatible for the fast item switching feature
local items = {"boomerang", "hookshot", "dominion rod"}
-- Shoot the right arrow
local arrows = {"arrow", "fire_arrow", "ice_arrow", "light_arrow", "explosive_arrow"}

local force_stop, avoid_return, from_teleporter = false
local previous_ammo

local function set_aminations(hero, num, extra)
  local prefix = {"bow_free_", "bow_armed_" .. extra .. "arrow_"}
  hero:set_fixed_animations(prefix[num] .. "stopped", prefix[num] .. "walking")
end

function bow_controller:start_bow(game)
  self.game = game
  self.hero = game:get_hero()
  self.item = game:get_item("bow")
  
  game:set_item_on_use(true)
  
  local hero = self.hero
  
  if hero.shield == nil then
    hero.shield = game:get_ability("shield")
    game:set_ability("shield", 0)
  end
  
  if not self.game.is_going_to_another_item then 
    game:show_cutscene_bars(true) 
	sol.audio.play_sound("common/bars_dungeon")
  end
  
  hero:set_animation("bow_shoot", function()
    self.state = 1
    hero:set_walking_speed(40)
	hero:set_fixed_direction(self.hero:get_direction())
	set_aminations(hero, 1, "")
	hero:unfreeze()
	game:set_custom_command_effect("attack", "return") 
	game.is_going_to_another_item = false
	
	if game:get_value("item_bow_max_arrow_type") ~= nil then
	  game:set_custom_command_effect("action", "change")
	end
	sol.menu.start(game:get_map(), self)
  end)
  sol.audio.play_sound("common/item_show")
  
  self:check() 
end

function bow_controller:check()
  local hero = self.hero
  
  local function end_by_collision() 
    local state = hero:get_state()
    force_stop = true
    if state == "treasure" then ended_by_pickable = true end
	if state == "stairs" then
	  hero:restore_state_stairs()
	end
	sol.menu.stop(bow_controller)
  end

  sol.timer.start(self, 10, function()
    local item_name = self.game:get_item_assigned(2) or nil
    local item_opposite = item_name ~= nil and item_name:get_name() or nil
    local item = item_opposite == "bow" or nil
	
    for _, state in ipairs(state) do
	  if hero:get_state() == state then
		hero:cancel_direction_fix()
	    end_by_collision()
        return		
	  end
	end
	
	-- Check if the item has changed
	self.slot = item and "item_2" or "item_1"
	self.opposite_slot = item and "item_1" or "item_2"
	
	if (self.item:get_amount() ~= previous_ammo and previous_ammo == 0) and self.state > 0 then
	  self:restore_default_state()
	end
	previous_ammo = self.item:get_amount()

	if not self.game:is_suspended() then
	  local assigned_1 = self.game:get_item_assigned(1) ~= nil and self.game:get_item_assigned(1):get_name() or nil 
	  local assigned_2 = self.game:get_item_assigned(2) ~= nil and self.game:get_item_assigned(2):get_name() or nil
	
	  if (assigned_1 == nil or assigned_1 ~= "bow") and (assigned_2 == nil or assigned_2 ~= "bow") then  
	    sol.menu.stop(self)
	    return
	  end
	  
	  if not self.game:is_command_pressed(self.slot) and self.state == 2 then 
	    self.game:simulate_command_released(self.slot)
	  end
	end
		
  return true
  end)
end

function bow_controller:restore_default_state()
  self.state = 1
  set_aminations(self.hero, 1, "")
  self.hero:unfreeze()
end

function bow_controller:create_arrow()
  local hero = self.game:get_hero()
  local x, y = hero:get_center_position()
  local _, _, layer = hero:get_position()
  local ax, ay = 0, 0
  local arrow = arrows[self.game:get_value("item_bow_current_arrow_type") or 1]
	  
  if hero:get_direction() == 0 then  ay = - 1
  elseif hero:get_direction() == 1 then ax = - 3
  elseif hero:get_direction() == 2 then ay = - 1
  end
	  
  local arrow = self.game:get_map():create_custom_entity({
    x = x + ax,
    y = y + ay,
    layer = layer,
	width = 8,
	height = 8,
    direction = hero:get_direction(),
    model = "item/arrow/arrow",
  })
  
  arrow:set_force(self.item:get_force())
  arrow:set_sprite_id(self.item:get_arrow_sprite_id())
  arrow:go()
end

function bow_controller:on_command_pressed(command)
  local hero = self.hero
  local game = self.game
  local suspended = game:is_suspended()
  local amount = self.item:get_amount()
  
  local another_item = game.is_going_to_another_item
  local opposite = self.opposite_slot:sub(6, 7)
  local item_name = game:get_item_assigned(opposite) or nil
  local item_opposite = item_name ~= nil and item_name:get_name() or nil
  
  local has_arrow = amount == 0 and "" or "with_"
  
  -- Player can still pause.
  if command == "pause" then
    return false
  end
  
  if not suspended then
    if command == self.slot and not game.is_building_new_arrow then
      sol.audio.play_sound("items/bow/arming")
	  hero:freeze()
	  hero:set_animation("bow_arming_".. has_arrow .."arrow")
	  avoid_return = true
	  sol.timer.start(self, 50, function()
	    self.state = 2
		set_aminations(hero, 2, has_arrow)
	    hero:unfreeze() 
	    hero:set_walking_speed(28)
	    avoid_return = false
	    if not game:is_command_pressed(self.slot) then self.game:simulate_command_released(self.slot) end
	  end)
	  
    -- The player pressed Action, he can change the arrow type
    elseif command == "action" and not game.is_building_new_arrow then
	  avoid_return = true
	  game:change_arrow_type()
	  hero:unfreeze()
	  self.state = 1
	  sol.timer.start(self, 50, function()
	    set_aminations(hero, 1, "")
	    game:simulate_command_released(self.slot)
	    avoid_return = false
	  end)
	  
	-- The player pressed attack, decide if we can halt this item.
    elseif command == "attack" and not avoid_return and not another_item then
	  sol.audio.play_sound("common/item_show")
      sol.menu.stop(self)
	  
	-- Analyse the opposite slot
    elseif command == "item_" .. opposite and item_opposite ~= nil then
      for _, item in ipairs(items) do
	    if item_opposite == item then
		  hero:freeze()
	      game.is_going_to_another_item = true
		  force_stop = true
		  sol.menu.stop(self)
		  
		  game:get_item(item_opposite):set_state(0)
	      game:get_item(item_opposite):on_using()
	      game:set_custom_command_effect("action", nil)
	    end
	  end  
    end
  end

  return true
end  
 
function bow_controller:on_command_released(command)
  local hero = self.hero
  local game = self.game
  local item = self.item
  
  if command == self.slot and self.state == 2 and not game:is_suspended() then
	avoid_return = true
	if item:get_amount() > 0 then       
	  item:remove_amount(1)
	  self:create_arrow()
	  sol.audio.play_sound("items/bow/shoot")
	else
	  sol.audio.play_sound("items/bow/no_arrows_shoot")
	end
	
	hero:freeze()
	hero:set_animation("bow_shoot")
	self.state = 1
	
	sol.timer.start(self, 60, function()
      set_aminations(hero, 1, "")
	  hero:unfreeze()
	  hero:set_walking_speed(40)
	  avoid_return = false
    end)
  end
  return true
end

function bow_controller:on_finished()  
  local game = self.game
  local hero = self.hero

  game:set_ability("shield", hero.shield)
  hero.shield = nil
  
  game:set_item_on_use(false)
  
  self.state = 0
  game:set_custom_command_effect("attack", nil)
  game:set_custom_command_effect("action", nil)
  hero:set_walking_speed(88)
  
  if game:is_cutscene_bars_enabled() and not game:is_current_scene_cutscene() and not ended_by_pickable and not game.is_going_to_another_item then
    game:show_cutscene_bars(false)
  end
  
  if not force_stop then
    hero:freeze()
	hero:set_animation("bow_shoot", function()
      if not game:is_current_scene_cutscene() then
	    hero:unfreeze()
	  else
	    hero:unfreeze()
	    hero:set_animation("stopped" .. (game:get_ability("shield") > 0 and "_with_shield" or ""))
		hero:freeze()
  	  end
	end)
  end   
  
  force_stop = false
  avoid_return = false
  ended_by_pickable = false
  
  hero:cancel_direction_fix()
  
  if game.is_using_lantern then
    hero:set_fixed_animations("lantern_stopped", "lantern_walking")
  end
  
  sol.timer.stop_all(self)
end

return bow_controller