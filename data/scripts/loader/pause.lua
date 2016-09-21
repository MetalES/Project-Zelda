return function(game)
  local pause = {}
  
  local function initialize_submenus()
    -- Define the path
    local path = "scripts/menus/pause_submenus/"
  
    -- Load all of the submenus
    local inventory_builder 	  = require(path .. "inventory")
    local map_builder 			  = require(path .. "map")
    local quest_status_builder 	  = require(path .. "quest_status")
    local equipment_builder 	  = require(path .. "equipment")
    local options_builder  		  = require(path .. "options")
    local mail_quest_builder      = require(path .. "mail")
    local bomber_notebook_builder = require(path .. "bomber_notebook")
    local mini_menu_disp 		  = require(path .. "inventory_submenu")


	-- Store the submenus in a array
    pause.submenus = {
      inventory_builder:new(game),
      map_builder:new(game),
      quest_status_builder:new(game),    
      equipment_builder:new(game),
      options_builder:new(game),
      mail_quest_builder:new(game),
	  bomber_notebook_builder:new(game),
	  mini_menu_disp:new(game),
    }
  end
  
  function game:start_pause_menu()
    local submenu_index = self:get_value("pause_last_submenu") or 1
    if submenu_index <= 0 or submenu_index > #pause.submenus then
      submenu_index = 1
    end
  
    self:set_value("pause_last_submenu", submenu_index)
    sol.audio.play_sound("/menu/pause_open")
    sol.audio.set_music_volume(self:get_value("old_volume") / 3)
    sol.menu.start(self, pause.submenus[submenu_index], false)
  end

  function game:stop_pause_menu()
    sol.audio.play_sound("/menu/pause_close")
    sol.audio.set_music_volume(game:get_value("old_volume"))
    local submenu_index = self:get_value("pause_last_submenu")
    sol.menu.stop(pause.submenus[submenu_index])
    self.pause_submenus = {}
    self:set_custom_command_effect("action", nil)
    self:set_custom_command_effect("attack", nil)
  end
  
  --Load the submenus
  initialize_submenus()
  
  return pause
end