local cutscene_manager = {}

-- Used to store cutscenes of the entire game.
-- The reason of this file is because of Hero Mode management (mirrored) and I don't want to duplicate code that much.
-- Use Hero mode value to alter movement of objects.

function cutscene_manager:load_cutscene_data(file, context, cutscene_pointer)
  self.file = require("maps/cutscene_data/" .. file)
  
  -- load the cutscene data and run the target pointer. And reset the container.
  self.file:run(context, cutscene_pointer or nil)
  self.file = nil 
  sol.menu.stop(self)  
end

return cutscene_manager