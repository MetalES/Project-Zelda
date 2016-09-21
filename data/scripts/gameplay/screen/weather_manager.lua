return function(game)
  -- This is the Weather system. 
  -- Work in Progress
  
  local weather = {current = nil}
  local d
  
  function game:set_weather(new, duration)
    d = duration or 1800
  
    if weather.current ~= nil then
	  weather:finish()
	  weather.next = new
	  return
	end	
	weather:start(new)
  end
  
  function weather:on_started()
  
  end
  
  function weather:start(new)
  
  end
  
  function weather:finish()
  
  end
  
  function weather:get_cycle()
    return weather.current
  end
  
  function weather:on_draw(dst)
  
  end
  
  return weather
end