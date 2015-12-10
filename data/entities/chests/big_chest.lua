local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local x_coordinate, y_coordinate = entity:get_position()
local mx, my = map:get_size()
local big_chest_savegame = "big_chest_" .. entity:get_name() .. "_" .. map:get_world() .. "_" .. mx .. "_" .. my .. "_" .. x_coordinate .. "_" .. y_coordinate
local hero = entity:get_map():get_entity("hero")

local hero_facing_chest = false
local action_command_chest = false

-- Hud notification
entity:add_collision_test("facing", function(big_chest, other)
if other:get_type() == "hero" then 
   hero_facing_chest = true
   if game:get_value(big_chest_savegame) ~= true and hero:get_direction() == entity:get_direction() + 1 then
    game:set_custom_command_effect("action", "open")
	action_command_chest = true
   else
    game:set_custom_command_effect("action", nil)
   end
end
end)

function entity:on_created()
  self:set_size(32, 8)
  self:set_origin(16,16)
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
if game:get_value(big_chest_savegame) == true then
  self:get_sprite():set_animation("open")
end
end

function entity:is_hookshot_hook()
return true
end

function entity:on_update()
  if action_command_chest and not hero_facing_chest then
    game:set_custom_command_effect("action", nil)
    action_command_chest = false
  end
   hero_facing_chest = false
end

--movement manager
local function go_up()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(1)
  m:start(hero)
end
local function go_down()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(false)
  m:set_speed(32)
  m:set_angle(3 * math.pi / 2)
  m:set_max_distance(1)
  m:start(hero)
end
local function jump_finish()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(32)
  m:set_angle(3 * math.pi / 2)
  m:set_max_distance(8)
  m:start(hero)
end
local function jump()
  local m = sol.movement.create("straight")
  m:set_ignore_obstacles(true)
  m:set_speed(32)
  m:set_angle(math.pi / 2)
  m:set_max_distance(7)
  m:start(hero)
end
--end movement

function entity:on_interaction()
local volume = sol.audio.get_music_volume() -- used later
local x,y = entity:get_position()
local hero = entity:get_map():get_entity("hero")
local treasure = self:get_name():match("^(.*)_[0-9]+$") or self:get_name()

  if hero:get_direction() == 1 and game:get_value(big_chest_savegame) ~= true then
    hero:freeze()
	if not show_bars then game:show_bars() end
    game:set_pause_allowed(false)
    hero:set_position(x, y+5)
    --game:draw_bars()
    game:set_hud_enabled(false)
    sol.audio.set_music_volume(0)
    sol.audio.play_sound("/common/chest_opening")
    sol.audio.play_sound("/common/chest_open")
    hero:set_animation("drop")
    entity:get_sprite():set_animation("opening")
    entity:set_direction(1)
    sol.timer.start(1500, function()
        sol.audio.play_sound("/common/chest_creak")
        hero:set_animation("jumping")
        entity:set_direction(2)
    end)
    sol.timer.start(1530, function()
        hero:set_animation("stopped")
    end)
    sol.timer.start(1600, function()
        entity:set_direction(3)
    end)

    sol.timer.start(1800, function()
        hero:set_animation("walking")
        go_up()
    end)

    sol.timer.start(2000, function()
        hero:set_animation("hurt")
    end)

    sol.timer.start(2100, function()
        hero:set_direction(0)
        hero:set_animation("chest_sequence")
        jump()
        sol.audio.play_sound("/characters/link/voice/jump1")
    end) 

    sol.timer.start(2600, function()
        hero:set_direction(1)
    end) 

    sol.timer.start(3300, function()
        hero:set_direction(2)
    end) 

    sol.timer.start(4700, function()
        hero:set_direction(1)
    end) 

    sol.timer.start(5500, function() 
        hero:set_animation("chest_sequence")
        hero:set_direction(0)
        jump_finish()
    end) 

    sol.timer.start(5900, function()
        hero:set_direction(1)
        hero:set_animation("walking")
        go_down()
    end) 

    sol.timer.start(6400, function()
        hero:set_animation("stopped")
        go_down()
    end) 

    sol.timer.start(6900, function()
        game:set_hud_enabled(true)
        hero:set_direction(2)
    end)

        sol.timer.start(7000, function()
        hero:set_direction(3)
        hero:set_animation("chest_holding_before_brandish")
    end)


    sol.timer.start(8100, function()
        game:set_hud_enabled(true)
        hero:start_treasure(treasure)
        game:set_pause_allowed(true)
        game:set_value(big_chest_savegame, true)
    end)

    elseif game:get_value(big_chest_savegame) ~= true then
	  if not show_bars then game:show_bars(); sol.audio.play_sound("/common/bars_dungeon") end
         game:start_dialog("gameplay.logic._cant_open_chest_wrong_dir", function() 
		 if show_bars == true and not starting_cutscene then game:hide_bars() end 
		 end)
end
end

function entity:on_update()
  if action_command_chest and not hero_facing_chest then
    game:set_custom_command_effect("action", nil)
    action_command_chest = false
  end
   hero_facing_chest = false
end