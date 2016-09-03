local minimap = {
  position = {
    [0] = 0,
    [1] = 7,
    [2] = 14,
    [3] = 21
  },
  chests = {},
  sprite = nil -- The minimap sprite, representing the map
}

function minimap:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function minimap:initialize(game)
  self.game = game
  self.hero = game:get_hero()
end

function minimap:on_started()
  self.hero_position = sol.surface.create("hud/minimap_hero.png")
  self.special_draw = sol.surface.create("hud/minimap_feature.png")
end

function minimap:on_room_changed(room)
  self:load_map()
end

function minimap:load_map()
  -- Are we in Hero Mode ? If true, then the map is mirrored, and need the other sprite.
  local folder = "normal" 
  if self.game:get_value("hero_mode") then
    folder = "mirror"
  end
  
  local map = self.game:get_map()
  local map_id = map:get_id()
  self.sprite = nil
  
  self:reload()
  
  -- We are in a dungeon, so maps exist
  if self.game:is_in_dungeon() then
    self.sprite = sol.sprite.create("menus/dungeon_maps/" .. folder .. "/minimap" .. self.game:get_dungeon_index())
	self.sprite:set_animation(map:get_floor())
	self.sprite:set_direction(self.game:get_dungeon_room() - 1)
	self.sprite_x, self.sprite_y = self.sprite:get_origin()
  else
  -- We are in the overworld, map don't exist because it is a static plane.
    self.sprite = sol.surface.create("hud/minimap/" .. map_id .. "/minimap.png")
  end
   
end

function minimap:draw_spawn_point(x, y, dir)
  self.spawn_x = x
  self.spawn_y = y
  self.spawn_dir = dir
end

function minimap:on_key_pressed(key)
  if key == "w" and (self:has_condition_to_display_border() or self:has_condition_to_display_extra()) and not self.game:is_suspended() then
    if self.draw then
	  self.draw = false
	  sol.audio.play_sound("common/minimap_off")
	else
      self.draw = true
      sol.audio.play_sound("common/minimap_on")
	end
  end
end

function minimap:on_map_changed(map)
  local x, y = self.hero:get_position()
  
  self:draw_spawn_point(x, y, self.hero:get_direction())
  self:load_map()
end

function minimap:reload()
  local game = self.game   
  local dungeon = game:get_dungeon()
  
  local map = game:get_map()
  local mx, my = map:get_size()
  local world = map:get_world()
  
  local current_floor, current_map_x, current_map_y
  
  if dungeon == nil then
    return
  end
  
  -- Reset the table needed, data will be parsed again
  for i = 1, #self.chests do
    self.chests[i] = nil
  end

  -- Here is the magic: set up a special environment to load map data files.
  local environment = {
	-- Chests are particular custom entities
    custom_entity = function(chest_properties)
	  if chest_properties.model == "chests/big_chest" or chest_properties.model == "chests/small_chest" then
	    local ename = chest_properties.name:match("^(.*)_[0-9]+$") or chest_properties.name
        minimap.chests[#minimap.chests + 1] = {
	      name = chest_properties.name,
          x = chest_properties.x,
          y = chest_properties.y,
          big = (chest_properties.sprite == "entities/dungeon/big_chest_default" or chest_properties.sprite == "entities/dungeon/big_key_chests"),
		  savegame_variable = "chest_" .. ename .. "_" .. world .. "_" .. mx .. "_" .. my .. "_" .. chest_properties.x .. "_" .. chest_properties.y .. "_" .. chest_properties.layer,
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

  for _, map_id in ipairs(dungeon.maps) do
    -- Load the map data file as Lua.
    local chunk = sol.main.load_file("maps/" .. map_id .. ".dat")
    -- Apply our special environment (with functions properties() and chest()).
    setfenv(chunk, environment)
    -- Run it.
    chunk()
  end
end

function minimap:has_condition_to_display_extra()
  return self.game:is_in_dungeon() and self.game:has_dungeon_compass()
end

function minimap:has_condition_to_display_border()
  return self.game:is_in_dungeon() and self.game:has_dungeon_map()
end

function minimap:on_paused()
  self.was_drawn = self.draw
  self.draw = false
end

function minimap:on_unpaused()
  self.draw = self.was_drawn
end

function minimap:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function minimap:on_draw(dst)
  local x, y = self.hero:get_position()
  local room_width, room_height = self.game:get_map():get_size()
  
  if self:has_condition_to_display_border() and self.draw then 
	if self.sprite ~= nil then
	  self.sprite:draw(dst, 250, 176)
	end
  end
  
  -- if an item or a condition is true, draw the player position and the extra
  if self:has_condition_to_display_extra() and self.draw then 
	if self.spawn_x ~= nil then
	  self.hero_position:draw_region(self.position[self.spawn_dir], 5, 7, 5, dst, (249 + ((self.spawn_x * 50) / room_width)), (176 + ((self.spawn_y * 50) / room_height)))
	end
	
	  -- Some special things need to be drawn
    for _, chest in ipairs(self.chests) do
      if chest.savegame_variable ~= nil and not self.game:get_value(chest.savegame_variable) then
        if chest.big then
	      self.special_draw:draw_region(3, 0, 5, 4, dst, (250 + ((chest.x * 50) / room_width)), (176 + ((chest.y * 50) / room_height)))
        else
          self.special_draw:draw_region(0, 0, 3, 3, dst, (251 + ((chest.x * 50) / room_width)), (176 + ((chest.y * 50) / room_height)))
        end
      end
    end
	
	self.hero_position:draw_region(self.position[self.hero:get_direction()], 0, 7, 5, dst, (249 + ((x * 50) / room_width)), (176 + ((y * 50) / room_height)))
  end
end

return minimap