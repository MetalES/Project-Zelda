local arrow_types = {}

function arrow_types:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self
  
  object:initialize(game)
  
  return object
end

function arrow_types:initialize(game)
  self.game = game
  self.background_img = sol.surface.create("hud/arrow_box.png")
  self.arrow_spr = sol.sprite.create("hud/arrow_showing")
  self.arrow_spr:set_animation(game:get_value("item_bow_current_arrow_type") or 0)
end


function arrow_types:check_if_can_display()
  return self.game:get_value("item_bow_state") > 0 and self.game:get_value("item_bow_current_arrow_type") ~= nil and not self.game:is_suspended()
end

-- function arrow_types:select_next_arrow()
  -- if game:get_value("item_bow_current_arrow_type") == 3 then
    -- game:set_value("item_bow_current_arrow_type", -1)
  -- end
  
  -- self.arrow_spr:fade_out(4)
  -- local movement = sol.movement.create("straight")
  -- movement:set_speed(70)
  -- movement:set_max_distance(8)
  -- movement:set_angle(2 * math.pi / 2)
  -- movement:start(self.arrow_spr, function()
    -- game:set_value("item_bow_current_arrow_type", game:get_value("item_bow_current_arrow_type") + 1)
    -- self.arrow_spr:set_animation(game:get_value("item_bow_current_arrow_type"))
    -- self.arrow_spr:set_xy(7, 0)
  
    -- self.arrow_spr:fade_in(4)
    -- local smovement = sol.movement.create("straight")
    -- smovement:set_speed(70)
    -- smovement:set_max_distance(8)
    -- smovement:set_angle(2 * math.pi / 2)
    -- smovement:start(self.arrow_spr)
  -- end)
-- end

function arrow_types:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function arrow_types:on_draw(dst_surface)

  if self:check_if_can_display() then
    local x, y = self.dst_x, self.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end
	
	self.background_img:draw(dst_surface, self.dst_x, self.dst_y)
	self.arrow_spr:draw(dst_surface, self.dst_x + 17, self.dst_y + 17)
  end
end

return arrow_types