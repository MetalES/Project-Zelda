local game = ...

-- item that was reworked and that need extra input check goes here

--[[ dunno how that work, need tuto
function game:get_item_slot(item)
for i = 1, 2 do
  if game:get_item_assigned(i) == item then
  return i
  end  
return nil
end
end ]]

function game:on_key_pressed(key)
local map = game:get_map()
local hero = map:get_hero()
-- get the item state
-- can_fire is used by the bow, hookshot, megaton hammer, rods and boomerang
local can_fire = game:get_value("can_shoot")

local bow_state = game:get_value("bow_state")
local lamp_state = game:get_value("lamp_state")           --WIP
local boomerang_state = game:get_value("boomerang_state") --WIP
local hookshot_state = game:get_value("hookshot_state")   --WIP
local m_hammer_state = game:get_value("megaton_state")    --WIP
local somaria_state = game:get_value("somaria_state")     --WIP
local fire_rod_state = game:get_value("fire_rod_state")   --WIP
local ice_rod_state = game:get_value("ice_rod_state")     --WIP
local ocarina_state = game:get_value("ocarina_state")     --WIP
local lenstruth_state = game:get_value("lens_of_truth_state")--WIP

-- Bow and Arrow
if key == "c" and bow_state == 1 and can_fire == false and not game:is_suspended() then -- this one don't need key_press, it just check if the sword button is pressed and then end the bow
    hero:freeze()
	sol.audio.play_sound("common/item_show")
	hero:set_tunic_sprite_id("hero/item/bow_shoot_tunic1")
      sol.timer.start(100, function()
	    hero:set_walking_speed(88)
		hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
        game:set_ability("tunic", game:get_value("item_saved_tunic"))
        game:set_ability("sword", game:get_value("item_saved_sword"))
        game:set_ability("shield", game:get_value("item_saved_shield"))
		game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
		game:set_value("bow_state", 0)
		hero:unfreeze()
		game:get_item("bow"):set_finished()
	  end)
	  
elseif key == "x" and game:get_item("bow"):get_amount() == 0 and bow_state == 1 and not game:is_suspended() then -- Link don't have arrow
	    game:set_pause_allowed(false)
    	hero:set_tunic_sprite_id("hero/item/bow_arming_no_arrow_tunic1")
		  sol.timer.start(50, function()
    	    sol.audio.play_sound("/items/bow/arming")
		    hero:set_tunic_sprite_id("hero/item/bow_moving_no_arrow_tunic1")
		    hero:unfreeze()
		    game:set_value("can_shoot", true)
		    hero:set_walking_speed(28)
		  end)
elseif key == "x" and game:get_item("bow"):get_amount() > 0 and bow_state == 1 and not game:is_suspended() then -- Link have arrows
    game:set_pause_allowed(false)
	hero:set_tunic_sprite_id("hero/item/bow_arming_arrow_tunic1")
	  sol.timer.start(50, function()
		sol.audio.play_sound("/items/bow/arming")
		hero:set_tunic_sprite_id("hero/item/bow_moving_with_arrow_tunic1")
		hero:unfreeze()
		game:set_value("can_shoot", true)
		hero:set_walking_speed(28)
	  end)
-- Lantern
elseif key == "v" and lamp_state == 1 and not game:is_suspended() then
    hero:freeze()
	sol.audio.play_sound("common/item_show")
	hero:set_animation("hammer")
      sol.timer.start(100, function()
		game:set_value("lamp_state", 1)
		hero:unfreeze()
	  end) 
elseif key == "c" and lamp_state == 1 and not game:is_suspended() then
    hero:freeze()
	sol.audio.play_sound("common/item_show")
	hero:set_animation("hammer")
      sol.timer.start(220, function()
	    hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
        game:set_ability("tunic", game:get_value("item_saved_tunic"))
        game:set_ability("sword", game:get_value("item_saved_sword"))
        game:set_ability("shield", game:get_value("item_saved_shield"))
	    hero:set_walking_speed(88)
		game:set_value("lamp_state", 0)
		hero:unfreeze()
	  end)	  
end
end


function game:on_key_released(key)
local map = game:get_map()
local hero = map:get_hero()

local bow_state = game:get_value("bow_state")
local can_fire = game:get_value("can_shoot")

-- Bow and Arrows
if key == "x" and bow_state == 1 and game:get_item("bow"):get_amount() == 0 and can_fire == true and not game:is_suspended() then
 hero:set_tunic_sprite_id("hero/item/bow_shoot_tunic1")
 sol.audio.play_sound("/items/bow/no_arrows_shoot")
 hero:freeze()
	-- can't shoot arrows, but reset to state 1
	sol.timer.start(100, function()
	    game:set_value("bow_state", 1)
		game:set_value("can_shoot", false)
		hero:set_tunic_sprite_id("hero/item/bow_moving_free_tunic1")
		hero:unfreeze()
		game:set_pause_allowed(true)
		end)
elseif key == "x" and bow_state == 1 and game:get_item("bow"):get_amount() > 0 and can_fire == true and not game:is_suspended() then
 hero:set_tunic_sprite_id("hero/item/bow_shoot_tunic1")
		shoot_arrow()
		hero:freeze()
		sol.timer.start(100, function()
		game:set_value("bow_state", 1)
		game:set_value("can_shoot", false)
		hero:unfreeze()
		hero:set_walking_speed(40)
		hero:set_tunic_sprite_id("hero/item/bow_moving_free_tunic1")
		game:set_pause_allowed(true)
		end)
-- Boomerang
end
end