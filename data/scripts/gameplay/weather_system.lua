--[[
  Dynamic Weather System
  Creation date: 06-23-2016
  
  Dynamic Weather, the world feel more filled with live and atmosphere.
  You can change the probability of a weather to happen, probabilities are 
  automatically changed each game-days.
  
  This rewrites the fog effect script, so if used, delete the fog script.
  
  Snow is used in Snowpeak, not as a dynamic element.
]]

local weather = {
  allowed_weather = {"cloud", "sun", "rain", "storm", "snow"}
  sprites = {}
}

-- Start the system: Load all of the variables
function weather:on_started()
  self.game = sol.game
  self.current_weather = self.game:get_value("current_weather") or "cloud"
  self.weather_force = self.game:get_value("current_weather_force") or 1
  self.weather_duration = self.game:get_value("current_weather_duration") or math.random(500000)
  self.planned_next_weather = self.allowed_weather[math.random(1, 4)]
end

-- Set a new weather
function weather:set_weather(new)
  -- We want to slowly transit to a new weather, so finish it.
  self:finish_weather(new)
  self.current_weather = new
end

function weather:autochange_weather()
  -- In case the weather is dynamic, change it automatically
  self:set_weather(math.random(1, 4))  
end

-- Return the current weather. Cannot be nil.
function weather:get_weather()
  return self.current_weather or "cloud"
end

--Start a new weather
function weather:start_weather(weather, force, duration, speed)
  

end

function weather:rain()

end

-- Finish a weather, and call a function if any
function weather:finish_weather(duration, callback)

  if callback then
    callback()
  end

end

return weather