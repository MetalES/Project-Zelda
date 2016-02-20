local game = ...
local cutscene_manager = {}

-- Used to store cutscenes of the entire game.
-- The reason of this file is because of Hero Mode management (mirrored) and I don't want to duplicate that much.
-- Symetrical maps don't need this so careful when you use it

-- Todo : When there will be a map with asymetrical walls, fill here.

function game:load_cutscene_data(cutscene_pointer, start_now)
  self.game.cutscene_pointer = cutscene_pointer
  self.game.start_cutscene = start_now
end

function game:start_cutscene()
  self.start_cutscene = true
end

function cutscene_manager:initialize()
  self.game = game
  self.hero_mode = self.game:get_value("hero_mode")
  
  self.game.cutscene_pointer = nil
  self.game.start_cutscene = false
end

function cutscene_manager:on_started()
  self:check()
end

function cutscene_manager:check()
  
  
  sol.timer.start(100, function() check() end)
end

return cutscene_manager