local item = ...
local game = item:get_game()

local item_name = "lamp"
local slot
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

local volume_bgm = game:get_value("old_volume")
local lamp_active = false

-- Script of the Lamp

item.temporary_lit_torches = {} -- List of torches that will be unlit by timers soon (FIFO).
item.was_dark_room = false

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value("item_"..item_name.."_state", 0)
end

function item:on_finished()
local map = game:get_map()
local hero = map:get_hero()
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  game:set_value("item_"..item_name.."_state", 0)
  self:set_finished()
end

function item:on_map_changed() -- if the lantern is on then keep updating it, even on map changement
local hero = game:get_hero()

if particle_timer ~= nil then particle_timer:stop(); particle_timer = nil end
if lamp_check_timer ~= nil then lamp_check_timer:stop(); lamp_check_timer = nil end
if oil_timer ~= nil then oil_timer:stop(); oil_timer = nil end
if particle ~= nil then particle:remove() end
if fire_burst ~= nil then fire_burst:remove() end

lamp_active = false

if game:get_magic() > 0 then if game:get_value("item_"..item_name.."_state") ~= 0 then game:set_value("item_"..item_name.."_state", 3); self:on_using() end else self:set_finished() end

self.temporary_lit_torches = {}
self.was_dark_room = false
end

function item:store_equipment()
    game:set_ability("shield", 0)
end

function item:transit_to_finish()
local hero = game:get_hero()
sol.audio.play_sound("common/item_show")
sol.audio.play_sound(sound_dir.."/off")

if particle_timer ~= nil then particle_timer:stop(); particle_timer = nil end
if lamp_check_timer ~= nil then lamp_check_timer:stop(); lamp_check_timer = nil end
if oil_timer ~= nil then oil_timer:stop(); oil_timer = nil end
if particle ~= nil then particle:remove() end
if fire_burst ~= nil then fire_burst:remove() end
if lamp_check_magic_timer ~= nil then lamp_check_magic_timer:stop(); lamp_check_magic_timer = nil end

lamp_active = false

hero:set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
game:set_value("item_"..item_name.."_state", 0)

item:set_finished(); 
end

function item:set_finished()
if particle_timer ~= nil then particle_timer:stop(); particle_timer = nil end
if lamp_check_timer ~= nil then lamp_check_timer:stop(); lamp_check_timer = nil end
if oil_timer ~= nil then oil_timer:stop(); oil_timer = nil end
if particle ~= nil then particle:remove() end
if fire_burst ~= nil then fire_burst:remove() end
if lamp_check_magic_timer ~= nil then lamp_check_magic_timer:stop(); lamp_check_magic_timer = nil end

lamp_active = false
end

-- Called when the hero uses the Lamp.
function item:on_using()
  local hero = game:get_hero()
  local x,y,layer = hero:get_position()
  local tunic = game:get_value("item_saved_tunic")
  
 if game:get_value("item_"..item_name.."_state") == 0 then
  hero:unfreeze()
  item:store_equipment()
  lamp_check_magic_timer = sol.timer.start(100, function()
  if game:get_magic() > 0 then if not lamp_active then self:call_extra(); lamp_active = true end else if not show_bars then game:show_bars(); game:start_dialog("gameplay.logic._lantern_no_oil", function() if show_bars == true and not starting_cutscene then game:hide_bars() end; self:transit_to_finish() end) end end
  return true
  end)
  sol.audio.play_sound(sound_dir.."on")
  hero:set_tunic_sprite_id("hero/item/lantern.tunic"..tunic)

   -- the state is "on"
  elseif game:get_value("item_"..item_name.."_state") == 1 then
  hero:unfreeze()
  self:transit_to_finish()
  
  else 
  hero:set_tunic_sprite_id("hero/item/lantern.tunic"..tunic)
  lamp_check_magic_timer = sol.timer.start(100, function()
  if game:get_magic() > 0 then if not lamp_active then self:call_extra(); lamp_active = true end else if not show_bars then game:show_bars(); game:start_dialog("gameplay.logic._lantern_no_oil", function() if show_bars == true and not starting_cutscene then game:hide_bars() end; self:transit_to_finish() end) end end
  return true
  end)
  end
end

function item:call_extra()
local hero = game:get_hero()
local x,y,layer = hero:get_position()
local tunic = game:get_value("item_saved_tunic")

  local function end_by_collision() hero:set_walking_speed(88); item:transit_to_finish(); game:set_pause_allowed(true) end

		-- fire_burst effect : effect played when starting the lamp
			local ex = 0
			local ey = 0
			--extra fire_burst position
			if     hero:get_direction() == 0 then ex = 2;     ey = - 5 -- right
			elseif hero:get_direction() == 1 then ey = - 12;  ex = 2   -- up
			elseif hero:get_direction() == 2 then ex = - 11;  ey = - 5 -- left
			elseif hero:get_direction() == 3 then ey = - 3;   ex = - 9 end -- down

			local fire_burst = game:get_map():create_custom_entity({
				x = x + ex,
				y = y + ey,
				layer = layer,
				direction = 0,
				sprite = "entities/fire_burst",
			}) 
			--remove it after 100 ms
		    fire_burst:set_drawn_in_y_order(true)			
			sol.timer.start(300, function() fire_burst:remove() end)

			game:set_value("item_"..item_name.."_state", 1)
			
			lamp_check_timer = sol.timer.start(50, function()
			item:create_fire()
			local lx, ly, layer = hero:get_position()
				
				if hero:get_direction() == 0 then new_x = -1; new_y = 0 
				elseif hero:get_direction() == 1 then new_x = 0; new_y = 1 
				elseif hero:get_direction() == 2 then new_x = 1; new_y = 0 
				elseif hero:get_direction() == 3 then new_x = 0; new_y = -1
				end
				
				if hero:get_state() == "falling" then self:on_map_changed() end
				if hero:get_state() == "jumping" or hero:get_state() == "swimming" then hero:set_tunic_sprite_id("hero/tunic"..tunic); hero:set_position(lx + new_x, ly + new_y); end_by_collision() end
				return true
			end)

			particle_timer = sol.timer.start(100,function()
			-- fire_burst effect : effect played when starting the lamp
			local px = 0
			local py = 0
			--extra fire_burst position
			if     hero:get_direction() == 0 then px = 6;     py = - 2 -- right
			elseif hero:get_direction() == 1 then py = - 5;  px = 5   -- up
			elseif hero:get_direction() == 2 then px = - 6;  py = - 2 -- left
			elseif hero:get_direction() == 3 then py = - 3;   px = - 4 end -- down

			local particle = game:get_map():create_custom_entity({
			  x = x + px,
			  y = y + py,
			  layer = layer + 1,
			  direction = 0,
			  sprite = "effects/item/lantern_effect",
			}) 
			particle:set_position(hero:get_position())
			-- avoid multiple custom entity on the map causing lags.
			sol.timer.start(200, function() particle:remove() end)
			return true
			end)

			local oil_need = 1
			game:remove_magic(oil_need)
			oil_timer = sol.timer.start(2500, function() item:get_game():remove_magic(oil_need); return true; end)
end


-- Creates some fire on the map.
function item:create_fire()
  local hero = game:get_hero()
  local direction = hero:get_direction()
  local map = game:get_map()
  local dx, dy
  if direction == 0 then
    dx, dy = 18, 4
  elseif direction == 1 then
    dx, dy = 0, -12
  elseif direction == 2 then
    dx, dy = -20, 4
  else
    dx, dy = 0, 16
  end
  local x, y, layer = hero:get_position()
  map:create_custom_entity{
    model = "lamp_fire",
    x = x + dx,
    y = y + dy,
    layer = layer,
    direction = 0,
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
  if show_bars == true and not starting_cutscene then game:hide_bars() end

   local magic_bar = self:get_game():get_item("magic_bar")
   if not magic_bar:has_variant() then
    magic_bar:set_variant(0)
  end
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
