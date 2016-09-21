local chest_loader = {}

function chest_loader:load_chests(map_ids, option)
  local chests = {}  
  local current_floor, current_map_x, current_map_y, current_width, current_height, current_world

  -- Here is the magic: set up a special environment to load map data files.
  local environment = {
    properties = function(map_properties)
      -- Remember the floor and the map location
      -- to be used for subsequent chests.
      current_floor = map_properties.floor
      current_map_x = map_properties.x
      current_map_y = map_properties.y
	  current_width = map_properties.width
	  current_height = map_properties.height
	  current_world = map_properties.world
    end,

    custom_entity = function(chest_properties)
	  local big = chest_properties.model == "chest/big"
	  local small = chest_properties.model == "chest/small"
	  if big or small then
	    if option ~= nil then current_map_x = 0; current_map_y = 0 end
	    local ename = chest_properties.name:match("^(.*)_[0-9]+$") or chest_properties.name
        chests[#chests + 1] = {
		  floor = current_floor,
          x = current_map_x + chest_properties.x,
          y = current_map_y + chest_properties.y,
          big = big,
		  savegame_variable = "chest_" .. ename .. "_" .. current_world .. "_" .. current_width .. "_" .. current_height .. "_" .. chest_properties.x .. "_" .. chest_properties.y .. "_" .. chest_properties.layer,
        }
	  end
    end,
  }

  -- Make any other function a no-op (tile(), enemy(), block(), etc.).
  setmetatable(environment, {
    __index = function()
      return function() end
    end
  })

  for _, map_id in ipairs(map_ids) do
    -- Load the map data file as Lua.
    local chunk = sol.main.load_file("maps/" .. map_id .. ".dat")
    -- Apply our special environment (with functions properties() and chest()).
    setfenv(chunk, environment)
    -- Run it.
    chunk()
  end
  
  return chests
end

return chest_loader