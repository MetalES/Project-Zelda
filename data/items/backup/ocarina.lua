local item = ...
local volume_bgm = sol.audio.get_music_volume()
local game = item:get_game()

function item:on_created()
  self:set_savegame_variable("b1837")
  self:set_assignable(true)
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    game:set_ability("tunic", 1)
    local sword = game:get_ability("sword")
    game:set_ability("sword", 0)
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
    local kb_action_key = game:get_command_keyboard_binding("action")                                                                                  
    game:set_command_keyboard_binding("action", nil)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
    game:set_value("item_saved_action", kb_action_key)
end


function item:on_using()
  local map = self:get_map()
  local hero = map:get_hero()
hero:set_direction(3)
sol.audio.play_sound("stairs_indicator")
hero:set_tunic_sprite_id("hero/item/ocarina/ocarina.tunic_" .. game:get_value("item_saved_tunic"))
--hero:freeze()

--A = 0, Down = 1, Right = 2, Left = 3, Up = 4
end

function ocarina_learn(song)
ocarina_play(song)
end
