local carried_meta = sol.main.get_metatable("carried_object")
-- if the carried object is above lava / water / hole, play an animation.
-- Since we can't carry object in these grounds (as it is in this project), that save a lot of time.
function carried_meta:on_removed()
  local map = self:get_map()
  local x, y, z = self:get_position()
  local ground = map:get_ground(x, y, z)
  
  if ground == "lava" or ground == "deep_water" or ground == "hole" then
    local effect = map:create_custom_entity({
	  x = x, 
	  y = y, 
	  layer = z, 
	  width = 8, 
	  height = 8, 
	  direction = 0
	})
	
	local sprite = effect:create_sprite("entities/carried_ground_effect")
    sprite:set_animation(map:get_ground(x, y, z))
	sol.audio.play_sound("common/item_in_" .. map:get_ground(x, y, z))
	
	function sprite:on_animation_finished() 
	  effect:remove() 
	end
  end
end
  
function carried_meta:on_position_changed()
  local map = self:get_map()
  local game = self:get_game()
  local hero = map:get_entity("hero")
  
  if map:has_entity("kdongo_mouth") then
	if self:get_distance(map:get_entity("kdongo_mouth")) < 20 and (hero:get_animation() ~= "carrying_stopped" and hero:get_animation() ~= "carrying_walking" and hero:get_animation() ~= "lifting") and not game.king_dodongo_swallowing_bomb then
	  game:simulate_command_pressed("action")
	  sol.timer.start(1, function()
		self:remove()
		game.king_dodongo_swallowing_bomb = true
	  end)
	end
  end
end
