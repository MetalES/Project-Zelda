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
  
  function game:set_hud_enabled(bool)
    self.hud:set_enabled(bool)
  end
  
  local path = "scripts/hud/"
  
  -- Primary HUD 
  local hearts_builder 		  = require(path .. "hearts")
  local magic_bar_builder 	  = require(path .. "magic_bar") 
  local attack_icon_builder   = require(path .. "attack_icon")
  local action_icon_builder   = require(path .. "action_icon")
  local item_icon_builder 	  = require(path .. "item_icon")
  local small_keys_builder 	  = require(path .. "small_keys")
  local rupees_builder 		  = require(path .. "rupees")
  local floor_builder 		  = require(path .. "floor")
  local minimap_builder 	  = require(path .. "minimap")
  
  -- Secondary HUD
  local clock_builder 		  = require(path .. "clock")
  
  -- Third HUD
  local bars_builder 		  = require(path .. "cutscene_bars")
  local map_name_builder 	  = require(path .. "map_name")
  local hints_builder         = require(path .. "hints")
  local current_arrow_builder = require(path .. "bow_arrow_type")
  
  -- local boss_life_builder = require("scripts/hud/boss_life")
  -- local horse_stamina = require("scripts/hud/horse_stamina")
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
  
  -- local menu = plunging_bar_builder:new(game)
  -- menu:set_dst_position(15,38)
  -- hud.primary[#hud.primary + 1] = menu

  -- local menu = horse_stamina:new(self)
  -- menu:set_dst_position(15, -20)
  -- self.hud[#self.hud + 1] = menu
  
  -- local menu = boss_life_builder:new(game)
  -- menu:set_dst_position(110, 220)
  -- hud.primary[#hud.primary + 1] = menu
  -- hud.primary.boss_life = menu  

  -- Destroy the HUD.
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
          and x > 225
          and y < 70 then
        opacity = 96
      elseif hud.top_left_opacity == 96
          and (game:is_suspended()
          or x <= 225
          or y >= 70) then
        opacity = 255
      end

      if opacity ~= nil then
        hud.top_left_opacity = opacity
        hud.primary.item_icon_1.surface:set_opacity(opacity)
        hud.primary.item_icon_2.surface:set_opacity(opacity)
        hud.primary.attack_icon.surface:set_opacity(opacity)
        hud.primary.action_icon.surface:set_opacity(opacity)
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
	  for _, menu in ipairs(hud.secondary) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
	  for _, menu in ipairs(hud.third) do
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
	  for _, menu in ipairs(hud.secondary) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
	  for _, menu in ipairs(hud.third) do
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
	  for _, menu in ipairs(hud.secondary) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
	  for _, menu in ipairs(hud.third) do
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
  game:set_clock_enabled(true)

  -- Update it regularly.
  check_hud()

  -- Return the HUD.
  return hud
end

return hud_manager