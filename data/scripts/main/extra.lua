-- Titlescreen states
function sol.main:parse_titlescreen_data(mode, game)
  local name = "system_boot.dat"
  local exist = sol.game.exists(name)
  local file = sol.game.load(name)
  
  local method = {"action","attack","pause","left","up","right","down"}
  local joypad_default = {"button 0","button 1","button 4","axis 1 -","axis 0 -","axis 0 +","axis 1 +"}
  local keyboard_default = {"space", "c", "d", "left", "up", "right", "down"}

  if not exist then
	file:set_starting_location("cutscene/scene_TitleScreen/0", "default")

    file:set_value("current_hour", 10)
    file:set_value("current_minute", 59)
    file:set_value("current_day", 1)
    file:set_life(1)

    file:set_value("i1025",0)
    file:set_value("i1024",0)
    file:set_value("old_volume", sol.audio.get_music_volume())
    file:set_value("old_sound", sol.audio.get_sound_volume())
	
    file:get_item("tunic"):set_variant(1)
    file:set_ability("tunic", 1)
    file:set_ability("shield", 1)

    file:set_value("cr", 240)
    file:set_value("cg", 240)
    file:set_value("cb", 240)
	
	file:set_value("tr", 240)
    file:set_value("tg", 240)
    file:set_value("tb", 240)

    file:save()
  end

  -- We are reading the file
  if mode == "read" then
    sol.audio.set_music_volume(file:get_value("old_volume"))
    sol.main:start_savegame(file)

  -- We are writing the file
  elseif mode == "write" then
    for i = 1, #method do
      file:set_value("joypad_" .. method[i], game:get_command_joypad_binding(method[i]))
      file:set_value("keyboard_" .. method[i], game:get_command_keyboard_binding(method[i]))
    end
  
    file:set_value("old_volume", game:get_value("old_volume"))
    file:set_value("old_sound", game:get_value("old_sound"))
    file:save()
  end
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
    size = 14
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

-- Function to return a value easier
function has_value(value)
  return sol.main.game:get_value(value) or false
end