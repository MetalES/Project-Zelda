-- Main script of the quest.

local console = require("scripts/console")
local quest_manager = require("scripts/quest_manager")

local debug_enabled = false
function sol.main.is_debug_enabled()
  return debug_enabled
end

-- Event called when the program starts.
function sol.main:on_started()

  -- Make quest-specific initializations.
  quest_manager:initialize_quest()

  -- Load built-in settings (audio volume, video mode, etc.).
  sol.main.load_settings()

  -- If there is a file called "debug" in the write directory, enable debug mode.
  debug_enabled = sol.file.exists("debug")

  local solarus_logo = require("scripts/menus/solarus_logo")
  local language_menu = require("scripts/menus/language")
  local title_screen = require("scripts/menus/title")
  local savegame_menu = require("scripts/menus/savegames")

  -- Show the Solarus logo first.
  sol.menu.start(self, solarus_logo)

  -- Then the language selection menu, unless a game was started by a debug key.
  solarus_logo.on_finished = function()
    if self.game == nil then
      sol.menu.start(self, language_menu)
    end
  end

  -- Then the title screen.
  language_menu.on_finished = function()
    if self.game == nil then
      sol.menu.start(self, title_screen)
    end
  end

  -- Then the savegame menu.
  title_screen.on_finished = function()
    if self.game == nil then
      sol.menu.start(self, savegame_menu)
    end
  end
end

-- Event called when the program stops.
function sol.main:on_finished()
  sol.main.save_settings()
end

function sol.main:debug_on_key_pressed(key, modifiers)
  local handled = true
  if key == "f1" then
    if sol.game.exists("save1.dat") then
      self.game = sol.game.load("save1.dat")
      sol.menu.stop_all(self)
      self:start_savegame(self.game)
    end
  elseif key == "f2" then
    if sol.game.exists("save2.dat") then
      self.game = sol.game.load("save2.dat")
      sol.menu.stop_all(self)
      self:start_savegame(self.game)
    end
  elseif key == "f3" then
    if sol.game.exists("save3.dat") then
      self.game = sol.game.load("save3.dat")
      sol.menu.stop_all(self)
      self:start_savegame(self.game)
    end
  elseif key == "n" then
print(sol.audio.get_music_volume())
  elseif key == "f11" then
    print('Stamina: '..self.game:get_value("i1024")..' / '..self.game:get_value("i1025"))
    print('current bgm volume '..sol.audio.get_music_volume())
    print('current map' ..self.game:get_map():get_id())
  elseif key == "f12" and not console.enabled then
    sol.menu.start(self, console)
  elseif sol.main.game ~= nil and not console.enabled then
    local game = sol.main.game
    local hero = nil
    if game ~= nil and game:get_map() ~= nil then
      hero = game:get_map():get_entity("hero")
    end

    -- In-game cheating keys.
    if key == "p" then
      game:add_life(12)
    elseif key == "m" then
      game:remove_life(2)
    elseif key == "o" then
      game:add_money(50)
    elseif key == "l" then
      game:remove_money(15)
    elseif key == "i" then
      game:add_magic(10)
    elseif key == "k" then
      game:remove_magic(4)
    elseif key == "f6" then
      game:set_max_life(game:get_max_life() - 4)
    elseif key == "f7" then
      game:set_max_life(game:get_max_life() + 4)
    elseif key == "f8" then
      game:set_max_stamina(game:get_max_stamina() - 44)
      game:add_stamina(game:get_max_stamina())
    elseif key == "f9" then
      game:set_max_stamina(game:get_max_stamina() + 44)
      game:add_stamina(game:get_max_stamina())
    elseif key == "kp 7" then
      game:set_max_magic(0)
    elseif key == "kp 8" then
      game:set_max_magic(51)
    elseif key == "kp 9" then
      game:set_max_magic(104)
    elseif key == "kp 1" then
      local tunic = game:get_item("tunic")
      local variant = math.max(1, tunic:get_variant() - 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)

 elseif key == "n" then
      game:set_max_money(max_money + 1)
    elseif key == "kp 4" then
      local tunic = game:get_item("tunic")
      local variant = math.min(3, tunic:get_variant() + 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)
    elseif key == "kp 2" then
      local sword = game:get_item("sword")
      local variant = math.max(1, sword:get_variant() - 1)
      sword:set_variant(variant)
    elseif key == "kp 5" then
      local sword = game:get_item("sword")
      local variant = math.min(4, sword:get_variant() + 1)
      sword:set_variant(variant)
    elseif key == "kp 3" then
      local shield = game:get_item("shield")
      local variant = math.max(1, shield:get_variant() - 1)
      shield:set_variant(variant)
    elseif key == "kp 6" then
      local shield = game:get_item("shield")
      local variant = math.min(3, shield:get_variant() + 1)
      shield:set_variant(variant)
    elseif key == "g" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= 0 then
	hero:set_position(x, y, layer - 1)
      end
    elseif key == "t" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= 2 then
	hero:set_position(x, y, layer + 1)
      end
    elseif key == "r" then
      if hero:get_walking_speed() == 600 then
        hero:set_walking_speed(88)
      else
        hero:set_walking_speed(600) --400 300
      end
    else
      -- Not a known in-game debug key.
      handled = false
    end
  else
    -- Not a known debug key.
    handled = false
  end

  return handled
end

-- If debug is enabled, the shift key skips dialogs
-- and the control key traverses walls.
local hero_movement = nil
local ctrl_pressed = false
function sol.main:on_update()

  if sol.main.is_debug_enabled() then
    local game = sol.main.game

    if game ~= nil then

      if game:is_dialog_enabled() then
        if sol.input.is_key_pressed("left shift") or sol.input.is_key_pressed("right shift") then
          game.dialog_box:show_all_now()
        end
      end

      local hero = game:get_hero()

      if hero ~= nil then
        if hero:get_movement() ~= hero_movement then
          -- The movement has changed.
          hero_movement = hero:get_movement()
          if hero_movement ~= nil
              and ctrl_pressed
              and not hero_movement:get_ignore_obstacles() then
            -- Also traverse obstacles in the new movement.
            hero_movement:set_ignore_obstacles(true)
          end
        end
        if hero_movement ~= nil then
          if not ctrl_pressed
              and (sol.input.is_key_pressed("w") or sol.input.is_key_pressed("right control")) then
            hero_movement:set_ignore_obstacles(true)
            ctrl_pressed = true
          elseif ctrl_pressed
              and (not sol.input.is_key_pressed("w") and not sol.input.is_key_pressed("right control")) then
            hero_movement:set_ignore_obstacles(false)
            ctrl_pressed = false
          end
        end
      end
    end
  end
end

-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)
  local handled = false

  -- Debugging features.
  if sol.main.is_debug_enabled() then
    handled = sol.main:debug_on_key_pressed(key, modifiers)
  end

  -- Normal features.
  if not handled then

    if key == "f5" then
      -- F5: change the video mode.
      sol.video.switch_mode()
    elseif key == "return" and (modifiers.alt or modifiers.control) then
      -- Alt + Return or Ctrl + Return: switch fullscreen.
      sol.video.set_fullscreen(not sol.video.is_fullscreen())
    elseif key == "f4" and modifiers.alt then
      -- Alt + F4: stop the program.
      sol.main.exit()
    end
  end

  return handled
end

-- Starts a game.
function sol.main:start_savegame(game)
  local game_manager = sol.main.load_file("scripts/game_manager")
  game_manager(game)
end

-- Returns the font and size to be used for dialogs
-- depending on the specified language (the current one by default).
function sol.language.get_dialog_font(language)
  language = language or sol.language.get_language()

  local font
  if language == "zh_TW" or language == "zh_CN" then
    -- Chinese font.
    font = "zqy-microhei"
    size = 12
  else
    font = "lttp"
    size = 14 --14
  end

  return font, size
end

-- Returns the font and size to be used to display text in menus
-- depending on the specified language (the current one by default).
function sol.language.get_menu_font(language)
  language = language or sol.language.get_language()

  local font, size
  if language == "zh_TW" or language == "zh_CN" then
    -- Chinese font.
    font = "wqy-microhei"
    size = 12
  else
    font = "minecraftia"
    size = 8
  end

  return font, size
end

-- Returns the font and size to be used to display text as the Book of Mudora
-- depending on the specified language (the current one by default).
function sol.language.get_book_font(language)
  language = language or sol.language.get_language()

  local font, size
  if language == "zh_TW" or language == "zh_CN" then
    -- Chinese font.
    --font = "wqy-microhei"
    --size = 12
  else
    font = "bom"
    size = 14
  end

  return font, size
end