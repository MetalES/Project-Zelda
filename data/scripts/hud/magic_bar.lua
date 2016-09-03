-- The magic bar shown in the game screen.

local magic_bar = {}

function magic_bar:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function magic_bar:initialize(game)
  self.game = game
  self.surface = sol.surface.create(89, 8)
  
  self.bitmap = sol.surface.create("hud/magic.png")
  self.magic_displayed = game:get_magic()
  self.max_magic_displayed = 0
  self.sound_to_play = 0
  
  -- Play an animation when the engine creates this
  if game:get_max_magic_meter() > 0 then
    self:play_animation(game:get_max_magic_meter() + 1, self.magic_displayed)
    game:set_magic(0)
    game:set_max_magic_meter(0)
  end
  
  self:check()
  self:rebuild_surface()
end

function magic_bar:play_animation(target, magic)
  local current = 0
  local game = self.game

  local function play_animation()
    sol.timer.start(self, 20, function()
      game:set_max_magic_meter(current)   
	  
	  if current == 20 then
	    game:set_magic(magic)
	  end
	  
      current = current + 1
      return current ~= target
    end)
  end
  
  play_animation()
end

-- Checks whether the view displays the correct info
-- and updates it if necessary.
function magic_bar:check()
  local need_rebuild = false
  
  local max_magic = self.game:get_max_magic_meter()
  local magic = self.game:get_magic()

  -- Maximum magic.
  if max_magic ~= self.max_magic_displayed then
    need_rebuild = true
    if self.magic_displayed > max_magic then
      self.magic_displayed = max_magic
    end
    self.max_magic_displayed = max_magic
  end

  -- Current magic.
  if magic ~= self.magic_displayed then
    need_rebuild = true
	local increment
    if magic < self.magic_displayed then
      increment = -1
    elseif magic > self.magic_displayed then
      increment = 1
	end
	
    if increment ~= 0 then
      self.magic_displayed = self.magic_displayed + increment
      rebuild_animation = true
      -- Play the magic bar sound.
      if increment == 1 and (magic - self.magic_displayed) % 3 == 1 then
	      sol.audio.play_sound("common/magic_bar/" .. self.sound_to_play)
		  self.sound_to_play = self.sound_to_play + 1 
      end
    end
  else
    self.sound_to_play = 0
  end

  -- Redraw the surface only if something has changed.
  if need_rebuild then
    self:rebuild_surface()
  end

  -- Schedule the next check.
  sol.timer.start(self.game, 20, function()
    self:check()
  end)
end

function magic_bar:rebuild_surface()
  self.surface:clear()
  
  -- Left Side
  self.bitmap:draw_region(0, 0, 2, 8, self.surface)
  -- Right Side
  self.bitmap:draw_region(3, 0, 2, 8, self.surface, 2 + self.game:get_max_magic_meter())
  
  -- Max Magic
  for i = 1, self.game:get_max_magic_meter() do
    self.bitmap:draw_region(2, 0, 1, 8, self.surface, 1 + (1 * i))
	-- Current Magic
	if i <= self.magic_displayed then
	  self.bitmap:draw_region(5, 0, 1, 8, self.surface, 1 + (1 * i))
	end
  end 
end

function magic_bar:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function magic_bar:on_draw(dst_surface)
  -- Is there a magic bar to show?
  if self.max_magic_displayed > 0 then
    local x, y = self.dst_x, self.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    self.surface:draw(dst_surface, x, y)
  end
end

return magic_bar
