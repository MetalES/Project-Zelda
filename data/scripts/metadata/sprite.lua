local sprite_meta = sol.main.get_metatable("sprite")
  
function sprite_meta:on_direction_changed()
  if self:get_animation_set() == "hero/tunic1" then
    local game = sol.main.game
    if game ~= nil then
      local hero = game:get_hero()
      if hero ~= nil and hero.fixed_direction ~= nil and self:get_direction() ~= hero.fixed_direction then
        self:set_direction(hero.fixed_direction)
      end
    end
  end
end
