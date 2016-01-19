local item = ...
local game = item:get_game()

local item_name = "bottle_1"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/bottle/" -- avoir duplicate between bottles

local volume_bgm = game:get_value("old_volume")

function item:on_created(variant, savegame_variable)
if variant == 1 then 
self:set_sound_when_brandished("/common/big_item")
else
self:set_sound_when_brandished("/common/minor_item")
end 
  self:set_assignable(true)
  self:set_savegame_variable("item_"..item_name.."_possession")
end

function item:on_obtaining(variant, savegame_variable)
 if variant > 1 then
 game:get_hero():set_animation("brandish_alternate")
 end
  sol.audio.set_music_volume(0)
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
if show_bars and not starting_cutscene then game:hide_bars() end
end

function item:on_using()
local variant = item:get_variant()
local map = item:get_map()
local hero = item:get_game():get_hero()
local tunic = game:get_ability("tunic")
local bottle_link_snd = math.random(1)
  
  hero:freeze()
  game:set_pause_allowed(false)
    
 if variant == 1 then -- swing, detectors are here
 
  hero:set_animation("bottle_swing", function()
  	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()
end)
  
  if bottle_link_snd == 0 then 
  sol.audio.play_sound("items/bottle/swing0")
  else
  sol.audio.play_sound("items/bottle/swing1")
  end
 

  local x, y, layer = hero:get_position()
  local direction4 = hero:get_direction()
  
  local bottle = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer,
    width = 8,
    height = 8,
    direction = direction4,
	model = "bottle"
  }

    --####################### water #######################--
  elseif variant == 2 then
    -- ask the hero to pour away the water
	  self:set_variant(1) -- make the bottle empty
	  sol.audio.play_sound("item_in_water")
	  sol.timer.start(10, function()
	  hero:unfreeze()
      self:set_finished() end)
  

    --####################### red potion #######################--
  elseif variant == 3 then
    if not show_bars then game:show_bars() end
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
  
  local potion_sprite = potion:create_sprite("entities/misc/item/bottle/drinking_potion")
  potion_sprite:set_direction(0)
  potion_sprite:set_animation("start_"..variant)
	
  hero:set_animation("bottle_drink_start")

	local delay
	if game:get_max_life() <= 20 then -- 5
	delay = 150
	elseif game:get_max_life() <= 40 then -- 10
	delay = 125
	elseif game:get_max_life() <= 60 then -- 15
	delay = 110
	elseif game:get_max_life() <= 96 then -- 10
	delay = 75
	end	
	
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
	game:add_life(game:get_max_life())   
	end)
	
	sol.timer.start((delay - 42) * game:get_max_life(), function()
	potion_sprite:set_animation("drinking_demi_" ..variant)
	end)
	
	sol.timer.start((delay - 8) * game:get_max_life(), function()
	potion:remove()
	self:set_variant(1)
    end)
	
	sol.timer.start(delay * game:get_max_life(), function()
    hero:set_animation("bottle_drink_end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_life()) + 1000, function()
	hero:set_animation("stopped")
	if show_bars == true and not starting_cutscene then game:hide_bars() end
	sol.audio.play_sound("common/item_show")
	hero:set_direction(3)
	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()
	end)
	
    --####################### green potion #######################--
  elseif variant == 4 then	
    if not show_bars then game:show_bars() end
  	local tunic = game:get_ability("tunic")
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
  
  local potion_sprite = potion:create_sprite("entities/misc/item/bottle/drinking_potion")
  potion_sprite:set_direction(0)
  potion_sprite:set_animation("start_"..variant)
	
  hero:set_animation("bottle_drink_start")

	local delay
	if game:get_max_magic() == 51 then -- demi
	delay = 60
	elseif game:get_max_magic() == 104 then -- full
	delay = 45
	end	
	
	sol.timer.start(200,function()
	hero:set_animation("bottle_drink_loop")
	potion_sprite:set_animation("drinking_full_" ..variant)
	sol.audio.play_sound("characters/link/voice/drinking")
	drink_se = sol.timer.start(1000, function()
    sol.audio.play_sound("characters/link/voice/drinking")
	return true
	end)
	end)
	
	sol.timer.start(1500,function()
	game:add_magic(game:get_max_magic())  
	end)
	
	sol.timer.start((delay - 24) * game:get_max_magic(), function()
	potion_sprite:set_animation("drinking_demi_" ..variant)
	end)
	
	sol.timer.start((delay - 8) * game:get_max_magic(), function()
	potion:remove()
	self:set_variant(1)
    end)
	
	sol.timer.start(delay * game:get_max_magic(), function()
    hero:set_animation("bottle_drink_end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_magic()) + 1000, function()
	hero:set_animation("stopped")
	if show_bars == true and not starting_cutscene then game:hide_bars() end
	sol.audio.play_sound("common/item_show")
	hero:set_direction(3)
	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()
	end)

    -- blue potion
  elseif variant == 5 then
    game:add_stamina(game:get_max_stamina())
    self:set_finished()

    --########################### revitalizing potion #############################
  elseif variant == 6 then
  if not show_bars then game:show_bars() end
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
  
  local potion_sprite = potion:create_sprite("entities/misc/item/bottle/drinking_potion")
  potion_sprite:set_direction(0)
  potion_sprite:set_animation("start_"..variant)

	local delay
	if game:get_max_life() <= 20 then -- 5
	delay = 150
	elseif game:get_max_life() <= 40 then -- 10
	delay = 125
	elseif game:get_max_life() <= 60 then -- 15
	delay = 110
	elseif game:get_max_life() <= 96 then -- 10
	delay = 75
	end	
	
hero:set_animation("bottle_drink_start") 
	
	sol.timer.start(200,function()
	hero:set_animation("bottle_drink_loop") 
	potion_sprite:set_animation("drinking_full_" ..variant)
	sol.audio.play_sound("characters/link/voice/drinking")
	drink_se = sol.timer.start(1000, function()
    sol.audio.play_sound("characters/link/voice/drinking")
	return true
	end)
	end)
	
	sol.timer.start(1500,function()
	game:add_life(game:get_max_life())   
	game:add_magic(game:get_max_magic())
	game:add_stamina(game:get_max_stamina())
	end)
	
	sol.timer.start((delay - 42) * game:get_max_life(), function()
	potion_sprite:set_animation("drinking_demi_" ..variant)
	end)
	
	sol.timer.start((delay - 8) * game:get_max_life(), function()
	potion:remove()
	self:set_variant(1)
    end)
	
	sol.timer.start(delay * game:get_max_life(), function()
    hero:set_animation("bottle_drink_end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_life()) + 1000, function()
	if show_bars == true and not starting_cutscene then game:hide_bars() end
	hero:set_animation("stopped")
	hero:set_direction(3)
	hero:unfreeze()
	sol.audio.play_sound("common/item_show")
	game:set_pause_allowed(true)
    self:set_finished()
	end)

    -- fairy
  elseif variant == 7 then
    -- release the fairy
    local x, y, layer = map:get_entity("hero"):get_position()
    local fairy = map:create_pickable{
      treasure_name = "fairy",
      treasure_variant = 1,
      x = x,
      y = y,
      layer = layer
    }
    self:set_variant(1) -- make the bottle empty
	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()

    -- poe soul
  elseif variant == 8 then
    -- release the poe soul
    local x, y, layer = map:get_entity("hero"):get_position()
    map:create_pickable{
      treasure_name = "poe_soul",
      treasure_variant = 1,
      x = x,
      y = y,
      layer = layer
    }
    self:set_variant(1) -- make the bottle empty
    self:set_finished()
  end
-- self:set_finished()
end