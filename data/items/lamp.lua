local item = ...
local game = item:get_game()
local volume_bgm = sol.audio.get_music_volume()

--local hero = self:get_map():get_entity("hero")

-- Script of the Lamp

item.temporary_lit_torches = {} -- List of torches that will be unlit by timers soon (FIFO).
item.was_dark_room = false

function item:on_created()
  self:set_savegame_variable("i1818")
  self:set_assignable(true)
  self:set_sound_when_picked(nil)
  self:set_sound_when_brandished("/common/big_item")
  game:set_value("lamp_state", 0)
end

function item:on_obtaining() 
  sol.audio.set_music_volume(0)
end

function item:on_started()
  game:set_value("lamp_state", 0)
end

function item:on_finished()
local map = game:get_map()
local hero = map:get_hero()
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  game:set_value("lamp_state", 0)
  self:set_finished()
end

function game:on_map_changed() -- if the lantern is on then keep updating it, even on map changement
local map = game:get_map()
local hero = map:get_hero()
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  game:set_value("lamp_state", 0)
  self:set_finished()
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_shield", shield)
end

-- Called when the hero uses the Lamp.
function item:on_using()
  local lamp_state = game:get_value("lamp_state")
  local hero = self:get_map():get_entity("hero")
  
 if lamp_state == 0 then

--TODO : freeze hero, play animation of him turning lamp on and then unfreeze
--TODO : Add light particle from the lantern

  hero:unfreeze()
  store_equipment()
  sol.audio.play_sound("items/lantern/on")
  hero:set_tunic_sprite_id("hero/item/lantern.tunic1")
  
-- fire_burst effect : effect played when starting the lamp
local x,y,layer = hero:get_position()
local ex = 0
local ey = 0
--extra fire_burst position
if     hero:get_direction() == 0 then ex = 2;     ey = - 5 -- right
elseif hero:get_direction() == 1 then ey = - 12;  ex = 2   -- up
elseif hero:get_direction() == 2 then ex = - 11;  ey = - 5 -- left
elseif hero:get_direction() == 3 then ey = - 3;   ex = - 9 end -- down

  local fire_burst = self:get_game():get_map():create_custom_entity({
      x = x + ex,
      y = y + ey,
      layer = layer,
      direction = 0,
      sprite = "entities/fire_burst",
    }) 
--remove it after 100 ms
fire_burst:set_drawn_in_y_order(true)
sol.timer.start(300, function() fire_burst:remove() end)
-- end fire_burst

  game:set_value("lamp_state", 1)
  check_timer = sol.timer.start(10, function()
  --self:create_fire()
  return true
  end)

  particle_timer = sol.timer.start(100,function()
  -- fire_burst effect : effect played when starting the lamp
  local x,y,layer = hero:get_position()
  local px = 0
  local py = 0
  --extra fire_burst position
  if     hero:get_direction() == 0 then px = 6;     py = - 2 -- right
  elseif hero:get_direction() == 1 then py = - 5;  px = 5   -- up
  elseif hero:get_direction() == 2 then px = - 6;  py = - 2 -- left
  elseif hero:get_direction() == 3 then py = - 3;   px = - 4 end -- down

  local particle = self:get_game():get_map():create_custom_entity({
      x = x + px,
      y = y + py,
      layer = layer + 1,
      direction = 0,
      sprite = "effects/item/lantern_effect",
    }) 
-- avoid multiple custom entity on the map causing lags.
sol.timer.start(200, function() particle:remove() end)

return true
end)

  local oil_need = 1
  item:get_game():remove_magic(oil_need)
  oil_timer = sol.timer.start(2500, function() item:get_game():remove_magic(oil_need); return true; end)

   -- the state is "on"
  elseif lamp_state == 1 then
  hero:unfreeze()
  sol.audio.play_sound("items/lantern/off")
  oil_timer:stop()
  check_timer:stop()
  particle_timer:stop()
  hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
  game:set_value("lamp_state", 0)
  end
end



-- Creates some fire on the map.
function item:create_fire()
  local hero = self:get_map():get_entity("hero")
  local direction = hero:get_direction()
  local dx, dy
  if direction == 0 then
    dx, dy = 8, -4
  elseif direction == 1 then
    dx, dy = 0, -14
  elseif direction == 2 then
    dx, dy = -12, -4
  else
    dx, dy = 0, 6
  end

  local x, y, layer = hero:get_position()
  self:get_map():create_fire{
    x = x + dx,
    y = y + dy,
    layer = layer
  }
end

-- Unlights the oldest torch still lit.
function item:unlight_oldest_torch()
  -- Remove the torch from the FIFO.
  local npc = table.remove(self.temporary_lit_torches, 1)
  if npc:exists() then
    -- Change its animation if it still exists on the map.
    npc:get_sprite():set_animation("unlit")
  end

  if #self.temporary_lit_torches == 0 and self.was_dark_room then
    -- make the room dark again
    self:get_map():set_light(0)
  end
end

-- Called when the player obtains the Lamp.
function item:on_obtained(variant, savegame_variable)

  sol.audio.set_music_volume(volume_bgm)

 -- Add Lamp Oil bar and variant TODO 

 -- problem : it add magic even if there's no command, weird, so let variant to 0

   local magic_bar = self:get_game():get_item("magic_bar")
   if not magic_bar:has_variant() then
    magic_bar:set_variant(0)
  end

 --
end

-- Called when the current map changes.
function item:on_map_changed()
  self.temporary_lit_torches = {}
  self.was_dark_room = false
end

-- Called when the hero presses the action key in front of an NPC
-- linked to the Lamp.
function item:on_npc_interaction(npc)
  if npc:get_name():find("^torch^") then
    npc:get_map():get_game():start_dialog("torch.need_lamp")
  end
end

-- Called when fire touches an NPC linked to the Lamp.
function item:on_npc_collision_fire(npc)
  if npc:get_name():find("^torch") then
    local torch_sprite = npc:get_sprite()
    if torch_sprite:get_animation() == "unlit" then
      -- Temporarily light the torch up.
      torch_sprite:set_animation("lit")
      sol.timer.start(10000, function()
        self:unlight_oldest_torch()
      end)
      table.insert(self.temporary_lit_torches, npc)

      local map = self:get_map()
      if map.get_light ~= nil and map:get_light() == 0 then
        -- Light the room.
        self.was_dark_room = true
        map:set_light(1)
      end
    end
  end
end
