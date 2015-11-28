local game = ...

function game:initialize_hud()

  -- Set up the HUD.
  local floor_builder = require("scripts/hud/floor")
  local rupees_builder = require("scripts/hud/rupees")
  local hearts_builder = require("scripts/hud/hearts")
  local item_icon_builder = require("scripts/hud/item_icon")
  local magic_bar_builder = require("scripts/hud/magic_bar")
  local pickables_builder = require("scripts/hud/pickables")
  local pause_icon_builder = require("scripts/hud/pause_icon")
  local small_keys_builder = require("scripts/hud/small_keys")
  local stamina_bar_builder = require("scripts/hud/stamina_bar")
  local attack_icon_builder = require("scripts/hud/attack_icon")
  local action_icon_builder = require("scripts/hud/action_icon")

  self.hud = {  -- Array for the hud elements, table for other hud info.
    showing_dialog = false,
    top_left_opacity = 255,
    custom_command_effects = {},
  }

  local menu = hearts_builder:new(self)
  menu:set_dst_position(15,12)
  self.hud[#self.hud + 1] = menu

  menu = magic_bar_builder:new(self)
  menu:set_dst_position(15,33)
  self.hud[#self.hud + 1] = menu

  menu = stamina_bar_builder:new(self)
  menu:set_dst_position(15, 40)
  self.hud[#self.hud + 1] = menu

  menu = rupees_builder:new(self)
  menu:set_dst_position(8, -20)
  self.hud[#self.hud + 1] = menu

  menu = pickables_builder:new(self)
  menu:set_dst_position(-255, -30)
  self.hud[#self.hud + 1] = menu

  menu = small_keys_builder:new(self)
  menu:set_dst_position(8, -40)
  self.hud[#self.hud + 1] = menu

  menu = floor_builder:new(self)
  menu:set_dst_position(5, 70)
  self.hud[#self.hud + 1] = menu

  menu = item_icon_builder:new(self, 1)
  menu:set_dst_position(232, 12)
  self.hud[#self.hud + 1] = menu
  self.hud.item_icon_1 = menu

  menu = item_icon_builder:new(self, 2)
  menu:set_dst_position(276,12)
  self.hud[#self.hud + 1] = menu
  self.hud.item_icon_2 = menu

  menu = attack_icon_builder:new(self)
  menu:set_dst_position(230,30)
  self.hud[#self.hud + 1] = menu
  self.hud.attack_icon = menu

  menu = action_icon_builder:new(self)
  menu:set_dst_position(186,30)
  self.hud[#self.hud + 1] = menu
  self.hud.action_icon = menu

  self:set_hud_enabled(true)
  self:check_hud()
end

function game:quit_hud()
  if self:is_hud_enabled() then
    -- Stop all HUD menus.
    self:set_hud_enabled(false)
  end
  self.hud = nil
end

function game:check_hud()
  local map = self:get_map()
  if map ~= nil then
    -- If the hero is below the top-left icons, make them semi-transparent.
    local hero = map:get_entity("hero")
    local hero_x, hero_y = hero:get_position()
    local camera_x, camera_y = map:get_camera_position()
    local x = hero_x - camera_x
    local y = hero_y - camera_y
    local opacity = nil

    if hud.top_left_opacity == 255
        and not self:is_suspended()
        and x > 225
        and y < 70 then
      opacity = 96
    elseif self.hud.top_left_opacity == 96
        and (self:is_suspended()
        or x <= 225
        or y >= 70) then
      opacity = 255
    end

    if opacity ~= nil then
      self.hud.top_left_opacity = opacity
      self.hud.item_icon_1.surface:set_opacity(opacity)
      self.hud.item_icon_2.surface:set_opacity(opacity)

      self.hud.attack_icon.surface:set_opacity(opacity)
      self.hud.action_icon.surface:set_opacity(opacity)
    end

    -- During a dialog, move the action icon and the sword icon.
    if not self.hud.showing_dialog and
        game:is_dialog_enabled() then
      self.hud.showing_dialog = true
    elseif self.hud.showing_dialog and
        not game:is_dialog_enabled() then
      self.hud.showing_dialog = false
    end
  end

  sol.timer.start(self, 50, function()
    self:check_hud()
  end)
end

function game:hud_on_map_changed(map)
  if self:is_hud_enabled() then
    for _, menu in ipairs(self.hud) do
      if menu.on_map_changed ~= nil then
        menu:on_map_changed(map)
      end
    end
  end
end

function game:hud_on_paused()
  if self:is_hud_enabled() then
    for _, menu in ipairs(self.hud) do
      if menu.on_paused ~= nil then
        menu:on_paused()
      end
    end
  end
end

function game:hud_on_unpaused()
  if self:is_hud_enabled() then
    for _, menu in ipairs(self.hud) do
      if menu.on_unpaused ~= nil then
        menu:on_unpaused()
      end
    end
  end
end

function game:is_hud_enabled()
  return self.hud_enabled
end

function game:set_hud_enabled(hud_enabled)
  if hud_enabled ~= self.hud_enabled then
    game.hud_enabled = hud_enabled

    for _, menu in ipairs(self.hud) do
      if hud_enabled then
        sol.menu.start(self, menu)
      else
        sol.menu.stop(menu)
      end
    end
  end
end

function game:get_custom_command_effect(command)
  return self.hud.custom_command_effects[command]
end

-- Make the action (or attack) icon of the HUD show something else than the
-- built-in effect or the action (or attack) command.
-- You are responsible to override the command if you don't want the built-in
-- effect to be performed.
-- Set the effect to nil to show the built-in effect again.
function game:set_custom_command_effect(command, effect)
  if self.hud ~= nil then
    self.hud.custom_command_effects[command] = effect
  end
end