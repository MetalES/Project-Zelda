local item = ...
local volume_bgm = sol.audio.get_music_volume()

function item:on_created()
  self:set_assignable(true)
  self:set_savegame_variable("i1810")
  self:set_sound_when_brandished("/common/big_item")
end

function item:on_obtaining() 
  sol.audio.set_music_volume(0)
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
end

function item:on_using()
local variant = item:get_variant()
local game = item:get_game()
local map = item:get_map()
local hero = item:get_game():get_hero()
local tunic = game:get_ability("tunic")
  
  hero:freeze()
  game:set_pause_allowed(false)
  
 if variant == 1 then -- swing, detectors are here
 
  hero:set_tunic_sprite_id("hero/item/bottle/bottle.swing.tunic_"..tunic)
  hero:set_animation("stopped")
  
  if math.random(1) == 0 then 
  sol.audio.play_sound("items/bottle/swing0")
  else
  sol.audio.play_sound("items/bottle/swing1")
  end
 
  local x, y, layer = hero:get_position()
  local direction4 = hero:get_direction()
  
  if direction4 == 0 then x = x + 12
  elseif direction4 == 1 then y = y - 12
  elseif direction4 == 2 then x = x - 12
  else y = y + 12
  end
  
  local bottle = map:create_custom_entity{
    x = x,
    y = y,
    layer = layer,
    width = 8,
    height = 8,
    direction = direction4,
  }
  
  --bottle:set_origin(4, 5)
  
sol.timer.start(200,function()

bottle:add_collision_test("overlapping", function(bottle, other)
    if other:get_type()  ~= "pickable" then
      print("it's a pickable")
	  sol.audio.play_sound("items/bottle/close")
	  bottle:clear_collision_tests()
	  hero:set_tunic_sprite_id("hero/tunic"..tunic)
	  hero:unfreeze()
	  bottle:remove()
	  game:set_pause_allowed(true)
	  self:set_finished()
	  else
	  print("it's not a pickable")
	  end
  end)
  
end)

	sol.timer.start(300,function()
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
	hero:unfreeze()
	bottle:remove()
	game:set_pause_allowed(true)
    self:set_finished()
	end)

    --####################### water #######################--
  elseif variant == 2 then
    -- ask the hero to pour away the water
    game:start_dialog("use_bottle_with_water", function(answer)
      if answer == 1 then
	-- empty the water
	self:set_variant(1) -- make the bottle empty
	sol.audio.play_sound("item_in_water")
      end
      self:set_finished()
    end)

    --####################### red potion #######################--
  elseif variant == 3 then

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
	
  hero:set_tunic_sprite_id("hero/item/bottle/drinking.tunic_"..tunic)
  hero:set_animation("start")
  
  	-- algorythm that depend on the current life, it calculate the approximate delay value
	-- based on max_life, no need to be precise as it just calculate an approximate range
	-- between values
	
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
	
	
	sol.timer.start(70,function()
	hero:set_animation("start")
	end)
	
	sol.timer.start(200,function()
	hero:set_animation("stopped")
	potion_sprite:set_animation("drinking_full_" ..variant)
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
    hero:set_animation("end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_life()) + 1000, function() --delay + 90 (delay + (85 / game:get_max_life())) * game:get_max_life()
	hero:set_animation("stopped")
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
	hero:set_direction(3)
	hero:unfreeze()
	game:set_pause_allowed(true)
    self:set_finished()
	end)
	
    --####################### green potion #######################--
  elseif variant == 4 then	
  
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
	
  hero:set_tunic_sprite_id("hero/item/bottle/drinking.tunic_"..tunic)
  hero:set_animation("start")
  
  	-- algorythm that depend on the current life, it calculate the approximate delay value
	-- based on max_life, no need to be precise as it just calculate an approximate range
	-- between values
	
	local delay
	if game:get_max_magic() == 51 then -- demi
	delay = 60
	elseif game:get_max_magic() == 104 then -- full
	delay = 45
	end	
	
	sol.timer.start(70,function()	
	hero:set_animation("start")
	end)
	
	sol.timer.start(200,function()
	hero:set_animation("stopped")
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
    hero:set_animation("end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_magic()) + 1000, function() --delay + 90 (delay + (85 / game:get_max_life())) * game:get_max_life()
	hero:set_animation("stopped")
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
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
	
  hero:set_tunic_sprite_id("hero/item/bottle/drinking.tunic_"..tunic)
  hero:set_animation("start")
  
  	-- algorythm that depend on the current life, it calculate the approximate delay value
	-- based on max_life, no need to be precise as it just calculate an approximate range
	-- between values
	
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
	
	
	sol.timer.start(70,function()
	hero:set_animation("start")
	end)
	
	sol.timer.start(200,function()
	hero:set_animation("stopped")
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
    hero:set_animation("end") 
	drink_se:stop()
	sol.audio.play_sound("characters/link/voice/aah")
    end)
	
	sol.timer.start((delay * game:get_max_life()) + 1000, function() --delay + 90 (delay + (85 / game:get_max_life())) * game:get_max_life()
	hero:set_animation("stopped")
	hero:set_tunic_sprite_id("hero/tunic"..tunic)
	hero:set_direction(3)
	hero:unfreeze()
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