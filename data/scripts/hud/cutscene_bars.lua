local cutscene_bars_builder = {}

cutscene_bars_size = sol.surface.create(320, 26)
cutscene_bars_2_size = sol.surface.create(320, 27)

function cutscene_bars_builder:new(game)

  local cutscene_bars = {}
  local cutscene_bars_enabled = false  
    
  function cutscene_bars:set_dst_position(x, y)
    self.dst_x = x
    self.dst_y = y
  end

  function cutscene_bars:on_draw(dst_surface)
    if cutscene_bars_enabled then
	
	cutscene_bars_size:draw(dst_surface, 0, -26)
	cutscene_bars_size:fill_color({0,0,0})
	cutscene_bars_size:set_opacity(255)

	cutscene_bars_2_size:draw(dst_surface, 0 , 239)
	cutscene_bars_2_size:fill_color({0,0,0})
	cutscene_bars_2_size:set_opacity(255)
    end
  end

local function check()
  if show_bars ~= true then		
  cutscene_bars_enabled = false
  else  
  if not cutscene_bars_enabled then
        bars_down_to_up = sol.movement.create("straight")
		bars_down_to_up:set_speed(500)
		bars_down_to_up:set_angle(1 * math.pi / 2)
		bars_down_to_up:set_max_distance(26)
		bars_down_to_up:start(cutscene_bars_2_size)
	  
        bars_up_to_down = sol.movement.create("straight")
		bars_up_to_down:set_speed(500)
		bars_up_to_down:set_angle(3 * math.pi / 2)
		bars_up_to_down:set_max_distance(26)
		bars_up_to_down:start(cutscene_bars_size)
	
    function bars_up_to_down:on_finished()	
	bars_up_to_down:stop()
	bars_up_to_down = nil
	bars_down_to_up:stop()
	bars_down_to_up = nil
	end
	
	cutscene_bars_enabled = true
	
 elseif cutscene_bars_enabled == true and bars_dispose == true then	
 
        bars_down_to_down = sol.movement.create("straight")
		bars_down_to_down:set_speed(500)
		bars_down_to_down:set_angle(3 * math.pi / 2)
		bars_down_to_down:set_max_distance(26)
		bars_down_to_down:start(cutscene_bars_2_size)
	  
        bars_up_to_up = sol.movement.create("straight")
		bars_up_to_up:set_speed(500)
		bars_up_to_up:set_angle(1 * math.pi / 2)
		bars_up_to_up:set_max_distance(26)
		bars_up_to_up:start(cutscene_bars_size)
		
  function bars_up_to_up:on_finished()
	bars_down_to_down:stop()
	bars_down_to_down = nil
	show_bars = false 
	cutscene_bars_enabled = false
	cutscene_bars_2_size:clear()
	cutscene_bars_size:clear()
	bars_up_to_up:stop()
	bars_up_to_up = nil
	--reset the surface values
	
	cutscene_bars_size:set_xy(0,0)
    cutscene_bars_2_size:set_xy(0,0)
  end
	
	bars_dispose = false
	
	end
	end
    return true 
end

  check()
  sol.timer.start(game, 100, check)

return cutscene_bars
end

return cutscene_bars_builder