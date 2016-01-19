local entity = ...
local game = entity:get_game()

-- Horse System
-- Todo : All (refer to the doc in /work/system/horse/controlable)

local function is_on_horse()
  return game:get_hero().is_on_horse
end

function entity:on_created()
  
end

function entity:on_update()
  if is_on_horse and self:get_animation() ~= "stopped" then
  
  end
end