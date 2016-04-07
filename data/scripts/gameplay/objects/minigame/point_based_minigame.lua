local minigame_points_manager = {}

-- Set which type of minigame it is : target, increasing points or decreasing
function minigame_points_manager:set_type_of_minigame(t)
  if t ~= "increasing" and t ~= "decreasing" and t ~= "target" then
    -- error("This type of minigame doesn't exist.")
  else 
    self.type = t
  end
end

-- This is used to modify points when the minigame has started
function minigame_points_manager:set_point(score)
  self.score = self.score + score
  self.score_text:set_text(self.score)
end

-- This is used when the minigame ends, so you can print or even store the score in a variable.
function minigame_points_manager:get_point()
  return self.score
end

function minigame_points_manager:on_started()
  -- Get the basic objects
  self.map = sol.main.game:get_map()
  self.hero = self.map:get_hero()
  self.bitmap = sol.surface.create("hud/minigame_arrow.png")
  self.score = 0

  self.score_text = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "middle",
    font = "lttp",
	font_size = "16",
	text = self.score
  }
  
end

function minigame_points_manager:on_finished()
  self.map = nil
  self.hero = nil
  self.bitmap = nil
  self.score = 0
  self.score_text = nil
end

function minigame_points_manager:on_draw(dst_surface)
  self.bitmap:draw(dst_surface, 13, 66)
  self.score_text:draw(dst_surface, 35, 75)
end

return minigame_points_manager