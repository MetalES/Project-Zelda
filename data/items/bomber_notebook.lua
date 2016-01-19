local item = ...
local notification_snd = "common/b_notebook_notification"
--Bomber Notebook System, when obtained, just call game:get_item("bomber_notebook"):add_notification(index)
--For translators : Menu texts are stored in Strings.dat, dialogs in dialogs.dat (quest_status.bomber_notebook.notif) and (quest_status.bomber_notebook.notif_quest_finished)

-- Debug, event:
-- For Bomber Notebook related NPCs, custom entities is the best solution.

function item:on_created()
  self:set_savegame_variable("bomber_book_possession")
  self:set_sound_when_brandished("common/big_item")
-- notify quest finished when player otained the notebook.
end

function item:add_quest(value)
  self:get_game():set_value("bomber_quest" .. value .. "_started", true)
  sol.audio.play_sound(notification_snd)
  self:get_game():start_dialog("misc_quest.bomber_notebook."..value - 1)
end

function item:notify_quest_finished(value)
  self:get_game():set_value("bomber_quest" .. value .. "_started", false)
  self:get_game():set_value("bomber_quest" .. value .. "_finished", true)
sol.audio.play_sound(notification_snd)
  self:get_game():start_dialog("misc_quest.bomber_notebook."..value - 1)
end
