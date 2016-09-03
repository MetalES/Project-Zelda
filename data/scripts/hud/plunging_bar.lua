-- The magic bar shown in the game screen.

local plunging_bar = {}

function plunging_bar:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function plunging_bar:initialize(game)
  self.game = game
  self.surface = sol.surface.create(89, 8)
  
  self.remaining_air = game:get_air()
  
  self.bitmap = sol.surface.create("hud/magic.png")
  self.magic_displayed = game:get_max_air()
  self.max_air_displayed = 0
  self.sound_to_play = 0
  
  -- The size of the bar depends whever if you have the zora tunic / Golden Scale
  -- Zora Tunic : half size, but deplete slower then usual
  -- Golden scale: Full size
  
  -- Play an animation when the engine creates this
  if game:get_max_air() > 0 then
    self.surface:fade_in()
  end
  
  self:check()
  self:rebuild_surface()
end

-- Checks whether the view displays the correct info
-- and updates it if necessary.
function plunging_bar:check()
  local need_rebuild = false
  local hero = self.game:get_hero()
  self.in_danger = false
  
  local max_air = self.game:get_max_air()
  local magic = self.remaining_air
  
  if hero:get_state() == "swimming" then
	need_rebuild = true
	self.start_timer = false
    self.remaining_air = self.remaining_air - 1
  else
    if self.remaining_air < max_air then
	  need_rebuild = true
	  self.remaining_air = self.remaining_air + 3
	  if self.remaining_air > max_air then
	    local difference = self.remaining_air - max_air
	    self.remaining_air = self.remaining_air - difference
	  end
	elseif self.remaining_air == max_air and not self.start_timer then
	  self.start_timer = true
	  -- should be when exiting the menu
	  -- sol.timer.start(self, 2500, function()
		-- if hero:get_state() ~= "swimming" then
		  -- self.surface:fade_out()
		  -- self.start_timer = false
		-- end
	  -- end)
	end
  end

  -- Maximum magic.
  if max_air ~= self.max_air_displayed then
    need_rebuild = true
    if self.magic_displayed > max_air then
      self.magic_displayed = max_air
    end
    self.max_air_displayed = max_air
  end
  
  if (max_air > 42 and magic <= 30) or (max_air == 42 and magic <= 20) then
    self.in_danger = true
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
	      -- sol.audio.play_sound("common/plunging_bar/" .. self.sound_to_play)
      end
    end
  end

  -- Redraw the surface only if something has changed.
  if need_rebuild then
    self:rebuild_surface()
  end

  -- Schedule the next check.
  sol.timer.start(self.game, 250, function()
    self:check()
  end)
end

function plunging_bar:rebuild_surface()
  self.surface:clear()
  local position = 6
  
  if self.in_danger then
    position = 8
  end
  
  -- Left Side
  self.bitmap:draw_region(0, 0, 2, 8, self.surface)
  -- Right Side
  self.bitmap:draw_region(3, 0, 2, 8, self.surface, 2 + self.game:get_max_air())
  
  -- Max Magic
  for i = 1, self.game:get_max_air() do
    self.bitmap:draw_region(2, 0, 1, 8, self.surface, 1 + (1 * i))
	-- Current Magic
	if i <= self.remaining_air then
	  self.bitmap:draw_region(position, 0, 1, 8, self.surface, 1 + (1 * i))
	end
  end 
end

function plunging_bar:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function plunging_bar:on_draw(dst_surface)
  -- Is there a magic bar to show?
  if self.max_air_displayed > 0 then
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

return plunging_bar
