return function(game)
  -- List bellow things that need to be created AND executed before the game's loaded (so most of things are loaded before the transition starts)
  game.pause = require("scripts/loader/pause")(game)
  require("scripts/loader/equipment")(game)
  require("scripts/loader/dungeon")(game)
  require("scripts/menus/game_over")(game) 
  require("scripts/loader/audio_res/hyrule_field")(game)
  require("scripts/loader/dialog_box")(game)
  require("scripts/gameplay/system/cutscene_manager")(game)
  
  -- Environment settings
  require("scripts/gameplay/screen/fog_manager")(game)
  require("scripts/gameplay/screen/tone_manager")(game)
  require("scripts/gameplay/screen/weather_manager")(game)
  
  -- List bellow things that need to be created when the game is being created
  local hud_manager = require("scripts/loader/hud")
  local condition_manager = require("scripts/loader/hero_condition")
  local camera_manager = require("scripts/camera_manager")
  
  function game:on_started()
    -- Set up the dialog box, HUD, hero conditions and effects.
    condition_manager:initialize(self)
    self.hud = hud_manager:initialize(self)
  
    self:initialize_dialog_box()
    camera = camera_manager:create(self)
  end

  function game:on_finished()
    -- Clean what was created by on_started()
    self.hud:quit()
    self:quit_dialog_box()
    sol.audio.set_music_volume(self:get_value("old_volume"))
    camera = nil
  end

  local save = game.save
  function game:save()
    local hero = self:get_hero()
    -- Set all values that you need to save bellow this and above old_save(self)
    -- An item is supposed to be active
    if hero.shield ~= nil then
      self:set_ability("shield", hero.shield)
    end
  
    -- Save the Day / Night Tones
    self:on_tone_system_saving()
    -- Save the game
    save(self)
  
    -- Bellow this, values can be reset
    -- An item is supposed to be active, the game has been saved
    if hero.shield ~= nil then
      self:set_ability("shield", 0)
    end
  end

  -- This event is called when a new map has just become active.
  function game:on_map_changed(map)  
   -- Notify the hud.
  
    self:start_tone_system()
    self.hud:on_map_changed(map)
  
    local world = map:get_world()
    if world == "field" then
      self:start_field_audio()
    else
      self.is_in_field = false
    end
	
	map:check_night()
  end

  function game:on_paused()
    self.hud:on_paused()
    self:start_pause_menu()
  end

  function game:on_unpaused()
    self:stop_pause_menu()
    self.hud:on_unpaused()
  end

  function game:start_horse()
    horse_manager:initialize(self)
    sol.menu.start(self, horse_manager)
  end

  function game:start_soaring_menu()
    sol.menu.start(self, soaring_menu, false)
  end

  -- Returns whether the current map is in the inside world.
  function game:is_in_inside_world()
    return self:get_map():get_world() == "inside_world"
  end

  -- Returns whether the current map is in the outside world.
  function game:is_in_outside_world()
   return self:get_map():get_world() == "outside_world"
  end

  -- Returns whether the current map is in a dungeon.
  function game:is_in_dungeon()
    return self:get_dungeon() ~= nil
  end
  
  -- Run the game.
  sol.main.game = game
  game:start()  
end