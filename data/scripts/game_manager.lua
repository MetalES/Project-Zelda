local game = ...

-- This script handles global properties of a particular savegame.

-- Include the various game features.
-- Use load_file for file that you want to start immediately
sol.main.load_file("scripts/menus/pause")(game)
sol.main.load_file("scripts/menus/game_over")(game)
sol.main.load_file("scripts/menus/dialog_box")(game)
sol.main.load_file("scripts/hud/hud")(game)


sol.main.load_file("scripts/gameplay/fog")(game)
sol.main.load_file("scripts/gameplay/time_system")(game)
-- sol.main.load_file("scripts/gameplay/cutscene_manager")(game)
-- sol.main.load_file("scripts/gameplay/screen/transition_manager")(game)
-- sol.main.load_file("scripts/menus/credits")(game)

-- These need to be require()

-- Functions for Dungeons
sol.main.load_file("scripts/dungeons")(game)
sol.main.load_file("scripts/equipment")(game)

-- Use require for file you want to pre load
local camera_manager = require("scripts/camera_manager")
local soaring_menu = require("scripts/menus/soaring_warp")
local condition_manager = require("scripts/hero_condition")
local horse_manager = require("scripts/gameplay/horse_manager")
local hyrule_audio = require("scripts/gameplay/audio/hyrule_field_audio_mgr")

-- Extra feature for the Water Temple
local water_manager = require("scripts/gameplay/objects/water_level_manager")

function game:on_started()
  -- Set up the dialog box, HUD, hero conditions and effects.
  condition_manager:initialize(self)
  self:initialize_dialog_box()
  self:initialize_hud()
  camera = camera_manager:create(self)
end

function game:start_horse()
  horse_manager:initialize(self)
  sol.menu.start(self, horse_manager)
end

function game:on_finished()
  -- self:set_current_scene_cutscene(false)
  -- Clean what was created by on_started()
  self:set_item_on_use(false) -- Debug only
  self:quit_hud()
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

function game:start_soaring_menu()
  sol.menu.start(self, soaring_menu, false)
end

-- This event is called when a new map has just become active.
function game:on_map_changed(map)  
  -- Notify the hud.
  self:start_tone_system()
  self:hud_on_map_changed(map)
  
  local world = map:get_world()
  if world == "field" then
    hyrule_audio:on_started()
  else
    self.is_in_field = false
  end
end

function game:on_paused()
  self:hud_on_paused()
  self:start_pause_menu()
end

function game:on_unpaused()
  self:stop_pause_menu()
  self:hud_on_unpaused()
end


-- Returns whether the current map is in the inside world.
function game:is_in_inside_world()
  return self:get_map():get_world() == "inside_world"
end

-- Returns whether the current map is in the outside world.
function game:is_in_outside_world()
  return self:get_map():get_world() == "outside_world" or self:get_map():get_world() == "outside_north"
end

-- Returns whether the current map is in a dungeon.
function game:is_in_dungeon()
  return self:get_dungeon() ~= nil
end

-- Run the game.
sol.main.game = game
game:start()