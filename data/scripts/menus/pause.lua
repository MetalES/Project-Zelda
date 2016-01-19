local game = ...
local current_audio_volume = sol.audio.get_music_volume()

-- build
local inventory_builder = require("scripts/menus/pause_inventory")
local map_builder = require("scripts/menus/pause_map")
local quest_status_builder = require("scripts/menus/pause_quest_status")
local equipment_builder = require("scripts/menus/pause_equipment")
local options_builder = require("scripts/menus/pause_options")
local mail_quest_builder = require("scripts/menus/pause_quest_status_mail")
local bomber_notebook_builder = require("scripts/menus/pause_quest_bomber_notebook")


function game:start_pause_menu()

  self.pause_submenus = {
    inventory_builder:new(self),
    map_builder:new(self),
    quest_status_builder:new(self),    
	equipment_builder:new(self),
    options_builder:new(self),
	mail_quest_builder:new(self),
	bomber_notebook_builder:new(self)
  }
  
  self:clear_map_name()  
  self:set_clock_enabled(false)

  local submenu_index = self:get_value("pause_last_submenu") or 1
  if submenu_index <= 0
      or submenu_index > #self.pause_submenus then
    submenu_index = 1
  end
  self:set_value("pause_last_submenu", submenu_index)
  sol.audio.play_sound("/menu/pause_open")
  sol.audio.set_music_volume(game:get_value("old_volume") / 3)
  sol.menu.start(self, self.pause_submenus[submenu_index], false)
end

function game:stop_pause_menu()
  sol.audio.play_sound("/menu/pause_close")
  sol.audio.set_music_volume(game:get_value("old_volume"))
  local submenu_index = self:get_value("pause_last_submenu")
  sol.menu.stop(self.pause_submenus[submenu_index])
  self.pause_submenus = {}
  
  self:set_clock_enabled(true)
	
  self:set_custom_command_effect("action", nil)
  self:set_custom_command_effect("attack", nil)
end

