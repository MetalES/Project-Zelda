local item = ...
--Mail System, when obtained, just call game:get_item("mail_bag"):add_mail(mail)
--For translators : Mail texts are stored in Strings.dat

--For debugging staff : 
-- the way unread mail works is by using default item amount. This is not an error.
-- the amount is removed when the mail is read in it's respective menu script.
function item:on_created()
  self:set_savegame_variable("mail_bag_possession")
  self:set_amount_savegame_variable("unread_mail_amount")
  self:set_sound_when_brandished("common/big_item")
-- add the 1st letter in the NPC event.
  self:set_max_amount(100)
  self:get_game():set_value("total_mail", 0)
end

function item:add_mail(value)
  self:get_game():set_value("mail_" .. value .. "_obtained", true)
  self:get_game():set_value("mail_" .. value .. "_opened", false)
  self:get_game():set_value("mail_" .. value .. "_highlighted", false)
  self:get_game():set_value("total_mail", self:get_game():get_value("total_mail") + 1)
  self:add_amount(1)
end

function item:get_mail(value)
return self:get_game():get_value("mail_" .. value .. "_obtained")
end