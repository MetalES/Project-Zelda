local item = ...
local volume_bgm = sol.audio.get_music_volume()

function item:on_created()
  self:set_sound_when_brandished("/common/big_item")
end

function item:on_obtaining(variant, savegame_variable)
  -- Save the possession of the map in the current dungeon.

  local game = self:get_game()
  local dungeon = game:get_dungeon_index()
  sol.audio.set_music_volume(0)
  if dungeon == nil then  
    error("This map is not in a dungeon")
  end
  game:set_value("dungeon_" .. dungeon .. "_map", true)
end

function item:on_obtained()
sol.audio.set_music_volume(volume_bgm)
end