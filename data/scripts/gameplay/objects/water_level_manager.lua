local water = {
  default_level = 9,
  max_entities_count = nil,
}

function water:on_started()
  self.game = sol.main.game
  self.map = self.game:get_map()
  
  local modifying_level = false
  local path = "environment/water_level/"

  --map:manage_water_level(), used in Water Temple
  function self.map:manage_water_level(args, x, y, target_entity, target, to_floor, callback)
    modifying_level = true
	-- Get the floor
	local floor = self:get_floor()
	-- Count
	local count = map:get_entities_count(target_entity)
	-- Target is expressed as target layer
	local target_final = nil
	
	-- MOM GET THE CAMERA
	local camera = self:get_camera()
	-- camera:move(x, y)
	
	sol.audio.play_sound(path .. "start")
	local timer = sol.timer.start(self, 2110, function()
      sol.audio.play_sound(path .. "loop")
      return modifying_level
    end)
	timer:set_suspended_with_map(false)
    
  end

end

function water:on_finished()
  -- Deprecate the functions
  self.map.manage_water_level = nil
end

return water