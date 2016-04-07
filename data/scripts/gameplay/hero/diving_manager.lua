local diving_manager = {}

diving_manager.sound = "characters/effect/diving"
diving_manager.animation_sprite_id = "entities/ground_effect"
diving_manager.hero_animation_sprite_id = "hero/action/diving/diving"

local state = 0

function diving_manager:is_started()
  return sol.menu.is_started(self)
end

function diving_manager:start(game)
  self.game = game
  sol.menu.start(self.game:get_map(), self)
end

function diving_manager:dive()
  
end

function diving_manager:on_command_pressed(command)
  if command == "attack" then
    if state == 0 then
      self:dive()  
	  self.game:get_hero():set_walking_speed(45)
	  self.game:get_hero().is_diving = true
	  state = 1
	else
	  sol.menu.stop(self)
	end
  end
end

function diving_manager:on_finished()
  self.game:get_hero():set_tunic_sprite_id("hero/tunic"..self.game:get_ability("tunic"))
  self.game:set_custom_command_effect("attack", nil) 
  self.game:get_hero().is_diving = false
  state = 0
  print(self.game:get_hero():get_walking_speed())
  if self.game:get_hero():get_state() == "swimming" then
    self.game:get_hero():set_walking_speed(45)
  else
  --check if shallow water or not
  end
end

return diving_manager

