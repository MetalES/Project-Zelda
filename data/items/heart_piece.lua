local item = ...
local volume_bgm = item:get_game():get_value("old_volume")

local message_id = {
"found_piece_of_heart.first",
"found_piece_of_heart.second",
"found_piece_of_heart.third",
"found_piece_of_heart.fourth"}

function item:on_created()
  self:set_sound_when_picked(nil)
end

function item:on_obtaining(variant, savegame_variable)
  local game = self:get_game()
  local nb_pieces_of_heart = game:get_value("i1700") or 0
  sol.audio.set_music_volume(0)

  if nb_pieces_of_heart < 3 then sol.audio.play_sound("/common/minor_item") else sol.audio.play_sound("/common/heart_container") end
  if not show_bars then game:show_bars() end
end

function item:on_obtained(variant)
  local game = self:get_game()
  local nb_pieces_of_heart = game:get_value("i1700") or 0

  game:start_dialog(message_id[nb_pieces_of_heart + 1], function()
    game:set_value("i1700", (nb_pieces_of_heart + 1) % 4)
    if nb_pieces_of_heart == 3 then
      game:add_max_life(4)
    end
    sol.audio.set_music_volume(volume_bgm)
    if show_bars == true and not starting_cutscene then game:hide_bars()end
    game:add_life(game:get_max_life())
  end)

end
