local bottle_manager = {
  btl = nil,
}

local delay
local divider = 1
local pouring_obj_table = {2, 7}

--[[
 Bottle System Script
 

Variables allowed:
  1 - Swinging, catching objects
  2 - Water
  3 - Red Potion
  4 - Green Potion
  5
  6
  7 - Fairy


]]

function bottle_manager:use_bottle(bottle_id, variant, game)
  self.game = game
  self.map = game:get_map()
  self.hero = game:get_hero()
  self.btl = game:get_item("bottle_" .. bottle_id)
  self.var = variant
  
  local var = self.var
   
  -- Swinging
  if var == 1 then 
    sol.audio.play_sound("items/bottle/swing" .. math.random(0, 1))
	
    self.hero:set_animation("bottle_swing", function()
      self.btl:set_finished()
    end)
	
    local x, y, layer = self.hero:get_position()
    local direction4 = self.hero:get_direction()
    local bottle = self.map:create_custom_entity{
      x = x,
      y = y,
      layer = layer,
      width = 8,
      height = 8,
      direction = direction4,
      model = "bottle"
    }
    bottle.slot = bottle_id
	
  elseif var == 2  then
    self:pour_object(var)
	
  -- Red Potion
  elseif var == 3 then
    self:drink(game:get_max_life(), 0, "life")
	
  -- Fairy
  elseif var == 7 then
    self:pour_object(var)
	
 
  
  end
end

function bottle_manager:pour_object(object)
  local game = self.game
  local map = self.map
  local hero = self.hero
  game:show_cutscene_bars(true)
  
  local x, y, layer = hero:get_position()
  local direction4 = hero:get_direction()
  local bottle = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer,
    width = 8,
    height = 8,
    direction = direction4,
    model = "object/bottle/" .. object
  }
  
  hero:set_animation("bottle_pouring_start", function()
    hero:set_animation("bottle_pouring_sequence", function()
      hero:set_animation("bottle_pouring_waiting_event")
	  sol.timer.start(1000, function()
	    self.btl:set_variant(1)
	    game:show_cutscene_bars(false)
		hero:unfreeze()
	  end)
    end)
  end)
end

function bottle_manager:drink(target_life, target_magic, target)
  local game = self.game
  local map = self.map
  local hero = self.hero
  local variant = self.var
  local target_obj
  
  game:set_pause_allowed(false)
  
  if target == "life" or target == "grandma_soup" or target == "revitalizing" then 
    target_obj = game:get_max_life()
  elseif target == "magic" then
    target_obj = game:get_max_magic()
  end

  local hero_x, hero_y, hero_layer = hero:get_position()
  local potion = map:create_custom_entity({
    direction = 0,
    x = hero_x,
    y = hero_y,
    layer = hero_layer,
    width = 16,
    height = 16,
  })
  potion:set_drawn_in_y_order(true)
  game:show_cutscene_bars(true)
  
  local potion_sprite = potion:create_sprite("entities/misc/item/bottle/drinking_potion")
  potion_sprite:set_animation("start_" .. variant)
  hero:set_animation("bottle_drink_start")

  self:retrieve_delay_time(target)
	
  sol.timer.start(200,function()
	hero:set_animation("bottle_drink_loop")
	potion_sprite:set_animation("drinking_full_"..variant)
	sol.audio.play_sound("characters/link/voice/drinking")
	drink_se = sol.timer.start(1000, function()
      sol.audio.play_sound("characters/link/voice/drinking")
	return true
	end)
  end)
	
  sol.timer.start(1500,function()
    if target == "life" then
	  game:add_life(target_life)   
	elseif target == "magic" then
	  game:add_magic(target_magic)
	elseif target == "grandma_soup" or target == "revitalizing" then
      game:add_life(target_life)   
	  game:add_magic(target_magic)
	end
  end)
	
  sol.timer.start((delay - 42) * target_obj / divider, function()
    potion_sprite:set_animation("drinking_demi_" ..variant)
  end)
	
  sol.timer.start((delay - 8) * target_obj / divider, function()
    potion:remove()
    self.btl:set_variant(1)
  end)
	
  sol.timer.start(delay * target_obj / divider, function()
    hero:set_animation("bottle_drink_end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
  end)
	
  sol.timer.start((delay * target_obj / divider) + 1000, function()
	hero:set_animation("stopped")
	game:show_cutscene_bars(false)
	sol.audio.play_sound("common/item_show")
	hero:set_direction(3)
	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()
  end)
end

function bottle_manager:retrieve_delay_time(target)
  local game = self.game

  if target == "life" or target == "grandma_soup" or target == "revitalizing" then
    if game:get_max_life() <= 20 then
	  delay = 150
    elseif game:get_max_life() <= 40 then
	  delay = 125
    elseif game:get_max_life() <= 60 then
	  delay = 110
    elseif game:get_max_life() <= 96 then
	  delay = 75
    end
  elseif target == "magic" then
    if game:get_max_magic() == 51 then
	  delay = 60
    elseif game:get_max_magic() == 104 then
	  delay = 45
    end	
  end
end

return bottle_manager