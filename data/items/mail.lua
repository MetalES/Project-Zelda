local item = ...

function item:on_created()
  self:set_sound_when_brandished("common/item_letter")
end

function item:on_obtaining(variant, savegame_variable)
  self:get_game():get_hero():set_animation("brandish_alternate")
  sol.audio.set_music_volume(0)
  self:get_game():get_item("mail_bag"):add_mail(variant)
end


function item:on_obtained()
  sol.audio.set_music_volume(self:get_game():get_value("old_volume"))
end