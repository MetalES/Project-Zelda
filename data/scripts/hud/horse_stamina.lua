local horse_stamina = {
  available = {},
}

function horse_stamina:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object 
end

function horse_stamina:initialize(game)
  self.game = game
  self.bitmap = sol.surface.create("hud/horse_stamina.png") 
end

function horse_stamina:on_draw(dst)

  for i = 0, 5 do
    if self.game.horse_stamina_state[i] then
	  self.bitmap:draw_region(0, 0, 16, 16, dst, 117 + (14 * i), 40)
	else
	  self.bitmap:draw_region(16, 0, 16, 16, dst, 117 + (14 * i), 40)
	end
  end

end

return horse_stamina