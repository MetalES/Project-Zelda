return function(game)
  local cutscene_manager = {}
  
  function game:start_cutscene(file, context, pointer)
    cutscene_manager:run(file, context, pointer)
  end
  
  -- Used to store cutscenes of the entire game.
  -- The reason of this file is because of Hero Mode management (mirrored)
  -- Use Hero mode value to alter movement of objects.
  function cutscene_manager:run(file, context, pointer)
    self.file = require("maps/cutscene_data/" .. file)
  
    -- load the cutscene data and run the target pointer. And reset the container.
    self.file:run(context, cutscene_pointer or nil)
    self.file = nil 
  end
  
  return cutscene_manager
end