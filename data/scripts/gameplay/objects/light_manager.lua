local light_manager = { opacity = 255 }
local sprite = sol.sprite.create("entities/misc/dark")
local animation_state = "no_oil"

local denied_direction

function light_manager:on_started()
  self.map = self.game:get_map()
  self.hero = self.game:get_hero()
  
  if self.game:get_magic() > 0 then
    animation_state = "normal"
  end
  
  sprite:set_animation(animation_state)
  
  self:check()
end

function light_manager:check()
  local need_rebuild = false
  local current_oil = self.game:get_magic()

  if current_oil ~= 0 then
    animation_state = "normal"
  else
    animation_state = "no_oil"
  end

  -- Schedule the next check.
  sol.timer.start(self, 50, function()
    self:check()
  end)
end

function light_manager:has_magic()
  return self.game:get_magic() > 0
end

function light_manager:on_draw(dst)
  local x, y, z = self.hero:get_position()
  sprite:set_animation(animation_state)
  
  if animation_state ~= "no_oil" then
    sprite:set_direction(self.hero:get_direction())
  else
    sprite:set_direction(0)
  end
  
  sprite:draw(dst, x, y)
end

-- local black = {0, 0, 0}

-- function light_manager.enable(hero)
  
  -- local game = hero:get_game()
  -- local map = game:get_map()

  -- map.light = 1
  -- map.get_light = function(map)
    -- return map.light
  -- end

  -- map.set_light = function(map, light)
    -- map.light = light
  -- end

  -- map.on_draw = function(map, dst_surface)

    -- if map.light ~= 0 then
      -- Normal light: nothing special to do.
      -- return
    -- end

    -- Dark room.
    -- local screen_width, screen_height = dst_surface:get_size()
    -- local hero = map:get_entity("hero")
    -- local hero_x, hero_y = hero:get_center_position()
    -- local camera_x, camera_y = map:get_camera_position()
    -- local x = 320 - hero_x + camera_x
    -- local y = 240 - hero_y + camera_y
    -- local dark_surface = dark_surfaces[hero:get_direction()]
    -- dark_surface:draw_region(
        -- x, y, screen_width, screen_height, dst_surface)

    -- dark_surface may be too small if the screen size is greater
    -- than 320x240. In this case, add black bars.
    -- if x < 0 then
      -- dst_surface:fill_color(black, 0, 0, -x, screen_height)
    -- end

    -- if y < 0 then
      -- dst_surface:fill_color(black, 0, 0, screen_width, -y)
    -- end

    -- local dark_surface_width, dark_surface_height = dark_surface:get_size()
    -- if x > dark_surface_width - screen_width then
      -- dst_surface:fill_color(black, dark_surface_width - x, 0,
          -- x - dark_surface_width + screen_width, screen_height)
    -- end

    -- if y > dark_surface_height - screen_height then
      -- dst_surface:fill_color(black, 0, dark_surface_height - y,
          -- screen_width, y - dark_surface_height + screen_height)
    -- end
  -- end
-- end

return light_manager
