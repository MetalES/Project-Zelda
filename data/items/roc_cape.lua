local item = ...
local game = item:get_game()
sol.main.load_file("scripts/gameplay/hero/roc_cape_controller")(game)

local item_name = "roc_cape"
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"
local volume_bgm = game:get_value("old_volume")

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  game:set_value("item_"..item_name.."_state", 0)
  game:set_value("item_"..item_name.."_type", 0)
end

function item:on_map_changed()
  game:stop_roccape_jump()
  self:set_finished()
end

function item:transit_to_finish()
  game:stop_roccape_jump()
  self:set_finished()
end

function item:on_obtained()
  game:show_cutscene_bars(false)
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_using()
  game:set_item_on_use(true)
  game:start_roccape_jump()
  self:set_finished()
end