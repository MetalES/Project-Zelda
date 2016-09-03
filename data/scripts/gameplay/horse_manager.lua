local horse = {
  spawned = false,
  whiping = false,
  jumping = false,
  hero_on_horse = false,
  reloading = false,
  stamina_available = {},
  usable_item = {
    "bow",
	"hookshot",
	"boomerang",
    "dominion_rod"
  },
}

--[[
  Horse controller.
  Add the ability to make the hero to control a horse  
]]

function horse:initialize(game)
  self.game = game
  
  sol.menu.start(game, self)
end

function horse:load_stamina()
  for i = 1, 6 do
    self.stamina_available[i] = true
  end
end

-- The horse has spawned but we are not riding it, except if we have teleport
function horse:on_started()
  self.hero_on_horse = self.game:get_value("riding_horse")
  self.bitmap = sol.surface.create("hud/horse_stamina.png")  
  
  self:load_stamina()
end

-- The player pressed action in front of the horse
function horse:hero_start_climb()
  
end

-- The player pressed action while he is on the horse
function horse:hero_get_away()
  
end

-- The player pressed action while the horse is walking
function horse:whip()

end

-- The player whiped the horse, he will go faster for a certain amount of time
function horse:forward()
  
end

-- The player pressed an input
function horse:on_command_pressed(command)

  if command == "action" then
    self.stamina_available[6] = false
    self.stamina_available[5] = false
    self.stamina_available[4] = false
    self.stamina_available[3] = false
    self.stamina_available[2] = false
    self.stamina_available[1] = false
	local current_stamina = 0
	
	if not self.reloading then
	  self:reload_stamina(current_stamina)
	end
	
	
  elseif command == "pause" then
    return false
	
  elseif command == "item_1" or command == "item_2" then
    for _, items in ipairs(self.usable_item) do
      print(items)
    end
  end

  
  return true  
end
-- The player didn't whip the horse for some reason and after a certain amount of time, reload the carrot meter
function horse:reload_stamina(current)
  if self.timer ~= nil then self.timer:stop() end
  -- We still have some.
  if self.stamina_available[1] then
    sol.timer.start(self, 5000, function()
	  self.timer = sol.timer.start(self, 600, function()
	    local new = current + 1
		current = new
	    self.stamina_available[new] = true
	    sol.audio.play_sound("common/carrot")
	    return not self.stamina_available[6]
	  end)
    end)  
  else
    self.reloading = true
    sol.timer.start(self, 7000, function()
	  self:load_stamina()
	  self.reloading = false
	  sol.audio.play_sound("common/carrot")
	end)
    
  
  end
  -- if self.current_whip_c ~= 0 then
    -- sol.timer.start(self, 500, function()
	  -- if current_whip_c ~= 6 then
	    -- current_whip_c = current_whip_c + 1
	  -- else return false
	  -- end
	-- end)
  
  -- else -- We don't have anymore
    -- sol.timer.start(self, 2000, function()
	  -- current_whip_c = 6
	-- end)
  -- end
  
end
-- Draw everything
function horse:on_draw(dst)
  for i = 1, 6 do
    if self.stamina_available[i] then
	  self.bitmap:draw_region(0, 0, 16, 16, dst, 103 + (14 * i), 40)
	else
	  self.bitmap:draw_region(16, 0, 16, 16, dst, 103 + (14 * i), 40)
	end
  end
  
end

return horse