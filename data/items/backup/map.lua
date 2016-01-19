local item = ...
local game = item:get_game()
local volume_bgm = item:get_game():get_value("old_volume")

function item:on_created()
  self:set_sound_when_brandished("/common/big_item")
end

function item:on_obtaining(variant, savegame_variable)
  -- Save the possession of the map in the current dungeon.
  local dungeon = game:get_dungeon_index()
  sol.audio.set_music_volume(0)
  if dungeon == nil then  
    error("This map is not in a dungeon")
  end
  game:set_value("dungeon_" .. dungeon .. "_map", true)
  if not show_bars then game:show_bars() end
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
if show_bars == true and not starting_cutscene then game:hide_bars()end
end