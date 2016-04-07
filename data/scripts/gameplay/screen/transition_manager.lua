local game = ...
local transition = {}

function game:start_transition(fade_type, duration, r, g, b, callback)
  transition.fade_type = fade_type
  transition.duration = duration
  transition.callback = callback or nil
  if fade_type == "in" then
    transition.r = r
    transition.g = g
    transition.b = b
	sol.menu.start(self, transition)
  else
    transition:on_started()
  end
end

function transition:on_started()
  self.surface = sol.surface.create(320, 240)
  
  if self.fade_type == "in" then
    self.surface:fill_color({self.r, self.g, self.b})
    self.surface:fade_in(self.duration, function()
	  if self.callback ~= nil then self.callback() end
	end)
  elseif self.fade_type == "out" then
    self.surface:fade_out(self.duration, function()
	  if game:get_map().on_transition_finished then game:get_map().on_transition_finished() end
	  sol.menu.stop(self)
	end)
  else error("Transition ".. self.fade_type .." doesn't seems to exist. Please refer to surface fading method.")
  end
end

function transition:on_draw(dst_surface)
  self.surface:draw(dst_surface, 0, 0)
end
