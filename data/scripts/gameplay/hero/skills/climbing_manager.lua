local climbing_manager = {}

function climbing_manager:on_started()
  self.game = sol.main.game
  self.map = self.game:get_map()
  self.hero = self.game:get_hero()
  
  self.shield = self.game:get_ability("shield")
  self.game:set_ability("shield", 0)
end 

function climbing_manager:climb(type_of_obstacle, entity)
  self.type = type_of_obstacle
  
  sol.timer.start(self, 10, function()
    entity:set_position(self.hero:get_position())
    return true
  end)
end

function climbing_manager:on_command_pressed(command)
  if command == "left" or command == "right" then
    if self.type == "0" then
	  self.game:simulate_command_released(command)	
	end
  elseif command == "pause" then 
    return false
  end
  return true
end

function climbing_manager:on_finished()
  sol.timer.stop_all(self)
  self.game:set_ability("shield", self.shield)
end

return climbing_manager