local minimap = {
  position = {
    [0] = 0,
    [1] = 7,
    [2] = 14,
    [3] = 21
  },
  surface = sol.surface.create(55, 56),
  chests = {},
  sprite = nil -- The minimap sprite, representing the map
}

local chest_loader = require("scripts/loader/chest")

function minimap:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self
  
  self:initialize(game)

  return object
end

function minimap:initialize(game)
  -- Set a new Dungeon Map
  function game:set_dungeon_minimap_index(index)
    minimap:set_dungeon_map(index)
  end
  
  -- Reload the minimap
  function game:reload_minimap()
    minimap:load_map()
  end
  
  self.hero_position = sol.surface.create("hud/minimap_hero.png")
  self.special_draw = sol.surface.create("hud/minimap_feature.png")
 
  self.game = game
  self.hero = game:get_hero()
end


function minimap:load_map()
  -- Are we in Hero Mode ? If true, then the map is mirrored, and need the other sprite. 
  local hero_mode = has_value("hero_mode") and "mirror" or "normal"

  local map = self.game:get_map()
  local map_id = map:get_id()
  
  self.room_width, self.room_height = map:get_size()
  self.sprite = nil
  
  self:reload()
  
  -- We are in a dungeon, so maps exist
  if self.game:is_in_dungeon() then
    self.sprite = sol.sprite.create("menus/dungeon_maps/" .. hero_mode .. "/minimap" .. self.game:get_dungeon_index())
	self.sprite:set_animation(map:get_floor())
	self.sprite:set_direction(self.game:get_dungeon_room() - 1)
	self.sprite_x, self.sprite_y = self.sprite:get_origin()
  else
  -- We are in the overworld, map don't exist because it is a static plane.
    self.sprite = sol.surface.create("hud/minimap/" .. map_id .. "/minimap.png")
  end
   
  -- Draw the map
  self:draw_map()
end

function minimap:draw_map()
  self.surface:clear()
  
  -- if the map has been obtained, draw it
  if self:has_condition_to_display_border() then 
    if self.sprite ~= nil then
	  self.sprite:draw(self.surface)
	end
  end 
  -- if the compass has been obtained, draw object needed
  if self:has_condition_to_display_extra() then 
	if self.spawn_x ~= nil then
	  self.hero_position:draw_region(self.position[self.spawn_dir], 5, 7, 5, self.surface, (-1 + ((self.spawn_x * 50) / self.room_width)), ((self.spawn_y * 50) / self.room_height))
	end	
	self:draw_chest()
  end
end

function minimap:reload()
  local dungeon = self.game:get_dungeon()
  
  if dungeon == nil then
    return
  end
  
  local id = {self.game:get_map():get_id()}
  self.chests = chest_loader:load_chests(id, "minimap")
end

function minimap:draw_chest()
  -- Some special things need to be drawn
  for _, chest in ipairs(self.chests) do
    if chest.savegame_variable ~= nil and not self.game:get_value(chest.savegame_variable) then
	  local dst_x = ((chest.x * 50) / self.room_width)
	  local dst_y = ((chest.y * 50) / self.room_height)
	  
      if chest.big then
	    self.special_draw:draw_region(3, 0, 5, 4, self.surface, dst_x, dst_y)
      else
        self.special_draw:draw_region(0, 0, 3, 3, self.surface, 1 + dst_x, dst_y)
      end
    end
  end
end

function minimap:draw_spawn_point(x, y, dir)
  self.spawn_x = x
  self.spawn_y = y
  self.spawn_dir = dir
end

function minimap:display_minimap()

  if (self:has_condition_to_display_border() or self:has_condition_to_display_extra()) and not self.game:is_suspended() then
    self.draw = not self.draw
	if self.draw then
	  sol.audio.play_sound("common/minimap_on")
	  return
	end
	sol.audio.play_sound("common/minimap_off")
  end

end

function minimap:on_key_pressed(key)
  local handled = false
  
  if key == self.game:get_value("keyboard_minimap") then
    self:display_minimap()
	handled = true
  end
  
  return handled
end

function minimap:on_joypad_button_pressed(button)

  local joypad_action = "button " .. button
  local value = self.game:get_value("joypad_minimap")

  if joypad_action == value then
    self:display_minimap()
  end
  
  return false
end

function minimap:on_map_changed(map)
  local x, y = self.hero:get_position()  
  self:draw_spawn_point(x, y, self.hero:get_direction())
  self:load_map()
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

function minimap:on_draw(dst)
  local x, y = self.hero:get_position()
  if self.draw then
    self.surface:draw(dst, 250, 176)
	if self:has_condition_to_display_extra() then 
	  self.hero_position:draw_region(self.position[self.hero:get_direction()], 0, 7, 5, dst, (249 + ((x * 50) / self.room_width)), (176 + (y * 50) / self.room_height))
    end
  end
end

return minimap