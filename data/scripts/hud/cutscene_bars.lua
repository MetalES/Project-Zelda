local cutscene_bars_builder = {}

local cutscene_bars_size = sol.surface.create(320, 26)
local cutscene_bars_2_size = sol.surface.create(320, 27)

local initialized_at_start = false
local movement_type = "straight"
local speed = 500
local distance = 26
local direction_angle_calc_up = math.pi / 2
local direction_angle_calc_down = 3 * direction_angle_calc_up
local state = 0

function cutscene_bars_builder:new(game)

  local cutscene_bars = {}
  local cutscene_bars_enabled = false  
    
  function cutscene_bars:set_dst_position(x, y)
    self.dst_x = x
    self.dst_y = y
  end
  
  function cutscene_bars:on_draw(dst_surface)
    if cutscene_bars_enabled then
	  cutscene_bars_size:draw(dst_surface, 0, -26)
	  cutscene_bars_size:fill_color({0,0,0})
	  cutscene_bars_size:set_opacity(255)

	  cutscene_bars_2_size:draw(dst_surface, 0 , 239)
	  cutscene_bars_2_size:fill_color({0,0,0})
	  cutscene_bars_2_size:set_opacity(255)
	  bars_draw = true
	elseif not initialized_at_start then
	  cutscene_bars_2_size:clear()
	  cutscene_bars_size:clear()
	  cutscene_bars_size:set_xy(0,0)
      cutscene_bars_2_size:set_xy(0,0)
	  initialized_at_start = true
	end
  end

local function check()
 -- define movement here
 local up = sol.movement.create(movement_type)
	   up:set_speed(speed)
	   up:set_angle(direction_angle_calc_up)
       up:set_max_distance(distance)
 local down = sol.movement.create(movement_type)
	   down:set_speed(speed)
	   down:set_angle(direction_angle_calc_down)
       down:set_max_distance(distance)
 function up:on_finished()
   up:stop()
   down:on_finished()
 end
 function down:on_finished()
   down:stop()
    if state == 1 then
      cutscene_bars_2_size:clear()
	  cutscene_bars_size:clear()	
	  show_bars = false 
	  cutscene_bars_enabled = false
	  initialized_at_start = false
	  state = 0
    end
 end

  if show_bars ~= true then		
  cutscene_bars_enabled = false
  else  
	  if not cutscene_bars_enabled then
		up:start(cutscene_bars_2_size)
		down:start(cutscene_bars_size)
		cutscene_bars_enabled = true
	  elseif cutscene_bars_enabled == true and bars_dispose == true then	
		down:start(cutscene_bars_2_size)
		up:start(cutscene_bars_size)
		state = 1
		bars_dispose = false
	  end
   end
  return true 
end

  check()
  sol.timer.start(game, 100, check)

return cutscene_bars
end

return cutscene_bars_builder