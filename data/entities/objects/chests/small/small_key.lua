local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local x_coordinate, y_coordinate, layer = entity:get_position()
local dungeon = game:get_dungeon_index()
local chest_savegame_variable = "chest_" .. dungeon .. "_" .. x_coordinate .. "_" .. y_coordinate
local hero = entity:get_map():get_entity("hero")
local sk_chest = game:get_value(chest_savegame_variable)

-- Hud notification (WORK IN PROGRESS)
entity:add_collision_test("touching", function()
   if sk_chest ~= 1 and hero:get_direction() == entity:get_direction() then
    game:set_custom_command_effect("action", "open")
   else
    game:set_custom_command_effect("action", nil)
   end
end)

function entity:on_created()
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
   if sk_chest == 1 then
    self:get_sprite():set_animation("open")
   end
end

function entity:on_interaction()

local volume = sol.audio.get_music_volume() -- used later
local x,y = entity:get_position()
local hero = entity:get_map():get_entity("hero")

  if hero:get_direction() == entity:get_direction() and sk_chest ~= 1 then
       if entity:get_direction() == 0 then --right
           hero:set_position(x-16, y)
       elseif entity:get_direction() == 1 then --up
           hero:set_position(x, y+16)
       elseif entity:get_direction() == 2 then --left
           hero:set_position(x+16, y)
       elseif entity:get_direction() == 3 then --down
           hero:set_position(x, y-16)
       end

hero:freeze()
game:set_pause_allowed(false)
 
    sol.timer.start(1,function()
            hero:set_animation("drop")
    end)

    sol.timer.start(200,function()
           if hero:get_direction() == 3 or hero:get_direction() == 1 then
            hero:set_animation("stopped")
           else
            hero:set_animation("grabbing")
           end
    end)

    sol.timer.start(300,function()
           if hero:get_direction() == 0 or hero:get_direction() == 2 then
            hero:set_animation("stopped")
           end
      self:get_sprite():set_animation("open")
      sol.audio.play_sound("/common/chest_open")
    end)
     
    sol.timer.start(600,function()
    hero:set_animation("stopped")
    if hero:get_direction() == entity:get_direction() then
       if entity:get_direction() == 0 then --right
           hero:set_direction(3)
       elseif entity:get_direction() == 1 then --up
           hero:set_direction(2)
       elseif entity:get_direction() == 2 then --left
           hero:set_direction(3)
       end
      end
     end)

    sol.timer.start(750,function()
    hero:set_animation("chest_holding_before_brandish")
    end)

    sol.timer.start(1500, function()
      hero:unfreeze()
      hero:start_treasure("small_key")
      hero:set_animation("brandish_alternate")
      game:set_pause_allowed(true) -- restore pause allowed
      hero:set_direction(entity:get_direction())
      game:set_value(chest_savegame_variable, 1)
    end)


    elseif sk_chest ~= 1 then
      game:start_dialog("gameplay.cannot_open_chest_side")
 end
end



