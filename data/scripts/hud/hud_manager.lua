-- Script that creates a head-up display for a game.

local hud_manager = {}

-- Creates and runs a HUD for the specified game.
function hud_manager:initialize(game)

  -- Set up the HUD.
  local hud = {
    enabled = false,
    showing_dialog = false,
    top_left_opacity = 255,
    primary = {}, -- Primary menu (Hearts, money, magic, etc)
	secondary = {}, -- Secondary menu (clock, thigs that can run even if primary is stopped and that need check)
	third = {}, -- Third menu (hud elements that don't need any check timer and that can be called in a simple way)
    custom_command_effects = {},
  }

  -- Returns the current customized effect of the action or attack command.
  -- nil means the built-in effect.
  function game:get_custom_command_effect(command)
    return hud.custom_command_effects[command]
  end
  -- Overrides the effect of the action or attack command.
  -- Set the effect to nil to restore the built-in effect.
  function game:set_custom_command_effect(command, effect)
    hud.custom_command_effects[command] = effect
  end 
  
  local hearts_builder = require("scripts/hud/hearts")
  local magic_bar_builder = require("scripts/hud/magic_bar") 
  local attack_icon_builder = require("scripts/hud/attack_icon")
  local action_icon_builder = require("scripts/hud/action_icon")
  local item_icon_builder = require("scripts/hud/item_icon")
  local small_keys_builder = require("scripts/hud/small_keys")
  local rupees_builder = require("scripts/hud/rupees")
  local floor_builder = require("scripts/hud/floor")
  local minimap_builder = require("scripts/hud/minimap")
  
  local clock_builder = require("scripts/hud/clock")
  
  local bars_builder = require("scripts/hud/cutscene_bars")
  local map_name_builder = require("scripts/hud/map_name")
  local hints_builder = require("scripts/hud/hints")
  local current_arrow_builder = require("scripts/hud/bow_arrow_type")
  
  -- local boss_life_builder = require("scripts/hud/boss_life")
  -- local horse_stamina = require("scripts/hud/horse_stamina")
  -- 
  -- 
  -- 
  -- local plunging_bar_builder = require("scripts/hud/plunging_bar")
  
  local life = hearts_builder:new(game)
  life:set_dst_position(15,12)
  hud.primary[#hud.primary + 1] = life
  
  local magic = magic_bar_builder:new(game)
  magic:set_dst_position(15,31)
  hud.primary[#hud.primary + 1] = magic
  
  local attack = attack_icon_builder:new(game)
  attack:set_dst_position(230,30)
  hud.primary[#hud.primary + 1] = attack
  hud.primary.attack_icon = attack

  local action = action_icon_builder:new(game)
  action:set_dst_position(186,30)
  hud.primary[#hud.primary + 1] = action
  hud.primary.action_icon = action
  
  local item_1 = item_icon_builder:new(game, 1)
  item_1:set_dst_position(232, 12)
  hud.primary[#hud.primary + 1] = item_1
  hud.primary.item_icon_1 = item_1

  local item_2 = item_icon_builder:new(game, 2)
  item_2:set_dst_position(276,12)
  hud.primary[#hud.primary + 1] = item_2
  hud.primary.item_icon_2 = item_2
  
  local small_keys = small_keys_builder:new(game)
  small_keys:set_dst_position(15, -33)
  hud.primary[#hud.primary + 1] = small_keys
  
  local money = rupees_builder:new(game)
  money:set_dst_position(15, -20)
  hud.primary[#hud.primary + 1] = money
  
  local floor = floor_builder:new(game)
  floor:set_dst_position(5, 70)
  hud.primary[#hud.primary + 1] = floor
  
  local minimap = minimap_builder:new(game)
  hud.primary[#hud.primary + 1] = minimap
  
  -- Secondary HUD
  local clock = clock_builder:new(game)
  hud.secondary[#hud.secondary + 1] = clock
  
  -- Third HUD
  local bars = bars_builder:new(game)
  hud.third[#hud.third + 1] = bars
  
  local map_name = map_name_builder:new(game)
  map_name:set_dst_position(0,0)
  hud.third[#hud.third + 1] = map_name

  local hints = hints_builder:new(game)
  hud.third[#hud.third + 1] = hints
  
  -- Set a new Dungeon Map
  function game:set_dungeon_minimap_index(index)
    minimap_dungeon_builder:set_dungeon_map(index)
  end
  
  -- Clock Control
  function game:set_clock_enabled(boolean)
    if boolean then
	  sol.menu.start(self, clock_builder, true)
	  hud.clock_was_enabled = true
	else
	  sol.menu.stop(clock_builder)
	  hud.clock_was_enabled = false
	end
  end

  function game:was_clock_enabled()
    return hud.clock_was_enabled
  end
  
  -- Cutscene Bars control
  function game:show_cutscene_bars(boolean)
	if boolean then
	  sol.menu.start(self, bars_builder, false)
	  bars_builder:show_bars()
	else
	  bars_builder:hide_bars()
	end
	
  end
  
  function game:is_cutscene_bars_enabled()
    return bars_builder:is_active()
  end
  
  -- Map Name control
  function game:show_map_name(map_name, display_extra)
    sol.menu.start(self, map_name_builder, false)
    map_name_builder:show_name(map_name, display_extra or nil)
  end

  function game:clear_map_name()
    sol.menu.stop(map_name_builder)
    map_name_builder:clear()
  end
  
  -- Display a hints
  function game:show_hint(key, seconds)
    sol.menu.start(self, hints_builder, false)
    hints_builder:display_hint(key, seconds)
  end
  
  
  
  

  
  -- local menu = plunging_bar_builder:new(game)
  -- menu:set_dst_position(15,38)
  -- hud.primary[#hud.primary + 1] = menu


  --
  
  -- local menu = horse_stamina:new(self)
  -- menu:set_dst_position(15, -20)
  -- self.hud[#self.hud + 1] = menu
  
  -- local menu = boss_life_builder:new(game)
  -- menu:set_dst_position(110, 220)
  -- hud.primary[#hud.primary + 1] = menu
  -- hud.primary.boss_life = menu  

  -- Destroys the HUD.
  function hud:quit()
    if hud:is_enabled() then
      -- Stop all HUD elements.
      hud:set_enabled(false)
    end
  end

  -- Function called regularly to update the opacity and the position
  -- of HUD elements depending on various factors.
  local function check_hud()
    local map = game:get_map()
    if map ~= nil then
      -- If the hero is below the top-left icons, make them semi-transparent.
      local hero = map:get_entity("hero")
      local hero_x, hero_y = hero:get_position()
      local camera_x, camera_y = map:get_camera():get_position()
      local x = hero_x - camera_x
      local y = hero_y - camera_y
      local opacity = nil

      if hud.top_left_opacity == 255
          and not game:is_suspended()
          and x < 88
          and y < 80 then
        opacity = 96
      elseif hud.top_left_opacity == 96
          and (game:is_suspended()
          or x >= 88
          or y >= 80) then
        opacity = 255
      end

      if opacity ~= nil then
        hud.top_left_opacity = opacity
        hud.primary.item_icon_1.surface:set_opacity(opacity)
        hud.primary.item_icon_2.surface:set_opacity(opacity)
        -- attack_icon.surface:set_opacity(opacity)
        -- action_icon.surface:set_opacity(opacity)
      end
    end

    sol.timer.start(game, 50, check_hud)
  end

  -- Call this function to notify the HUD that the current map has changed.
  function hud:on_map_changed(map)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.primary) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just paused.
  function hud:on_paused()
    if hud:is_enabled() then
      for _, menu in ipairs(hud.primary) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just unpaused.
  function hud:on_unpaused()
    if hud:is_enabled() then
      for _, menu in ipairs(hud.primary) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
    end
  end

  -- Returns whether the HUD is currently enabled.
  function hud:is_enabled()
    return hud.enabled
  end

  -- Enables or disables the HUD.
  function hud:set_enabled(enabled)
    if enabled ~= hud.enabled then
      hud.enabled = enabled

      for _, menu in ipairs(hud.primary) do
        if enabled then
          -- Start each HUD element.
          sol.menu.start(game, menu)
        else
          -- Stop each HUD element.
          sol.menu.stop(menu)
        end
      end
    end
  end

  -- Start the HUD.
  hud:set_enabled(true)

  -- Update it regularly.
  check_hud()

  -- Return the HUD.
  return hud
end

return hud_manager