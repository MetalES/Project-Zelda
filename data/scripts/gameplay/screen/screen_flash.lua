return function(game)
  local screen = {}
  
  function screen:flash(r, g, b, a, d)
    self.surface = sol.surface.create(320, 240)
	self.r = r
	self.g = g
	self.b = b
	self.a = a
	
	self.d = d
	
	sol.menu.start(game, self, false)
  end
  
  function screen:on_draw(dst)
    if self.d > 0 then
	  self.surface:draw(dst)
	  
	  if (not game:is_paused() and not game:is_suspended()) then
        self.r = (self.r * (self.d - 1) + 255) / self.d
        self.g = (self.g * (self.d - 1) + 255) / self.d
        self.b = (self.b * (self.d - 1) + 255) / self.d
        self.a = (self.a * (self.d - 1) + 255) / self.d
      end
	
	  self.d = self.d - 1
	end
  end
  
  
  return screen
end