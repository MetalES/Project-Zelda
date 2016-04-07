local cutscene = {}

-- These compose the visual and displayed entities of this cutscene
local npc
local nspr
local dungeon 
local tile

function cutscene:wave_sprite(sprite)
  sprite:set_xy(0, -2)
  local dy = 1
  local t = 0
  
  sol.timer.start(self, 250, function()
    local _,y = sprite:get_xy()
    if sprite then sprite:set_xy(0,y+dy) end
    -- Direction of movement is changed each second.
    t = (t+1)%5
    if t == 0 then dy = -dy end
    -- Restart timer.
    return true
  end)
end

function cutscene:create_npc(map)
  npc = map:create_npc({
    name = "sage",
    layer = 0,
    x = 160,
    y = 80,
    direction = 0,
    subtype = 1,
    sprite = "npc/sage/"..dungeon,
  })
  npc:set_position(150, 72)
  nspr = npc:get_sprite()
  npc:set_visible(false)
  
  tile = map:get_entity(dungeon)
  tile:set_position(136, 72)
  tile:set_visible(false)
end


function cutscene:run(map)
  local game = map:get_game()
  local hero = map:get_hero()
  local surface = require("scripts/gameplay/objects/warp_manager")
  dungeon = surface:get_finished_dungeon()
  hero:freeze()
  self:create_npc(map)
  
  npc:set_visible(true)
  tile:set_visible(true)
  
  self:wave_sprite(nspr)
  nspr:fade_in(150)
  
  local function dialog_position(position)
    game:set_dialog_position(position)
  end
  
  local function move_npc()  
    game:fade_audio(0, 10)
	game.disable_message_box_sound = false
    local m = sol.movement.create("straight")
	m:set_angle(3 * math.pi / 2)
	m:set_speed(20)
	m:set_max_distance(npc:get_distance(hero) - 32)
	m:start(npc, function() 
	  local c = sol.movement.create("circle")
	  c:set_center(hero, 0, -8)
      c:set_clockwise(false)
      c:set_initial_angle(math.pi / 2)
      c:set_max_rotations(4)
      c:set_radius(16)
      c:set_radius_speed(16)
	  c:start(npc, function()
	    sol.audio.set_music_volume(game:get_value("old_volume"))
	    sol.audio.play_music("cutscene_sage_saved", false)
		dialog_position("bottom")
		game:start_dialog("_treasure.medalions." .. dungeon, function()
		
		end)
	  end)
	end)
  end
  
  if dungeon == "7" then -- forest
    game.disable_message_box_sound = true
    game:set_dialog_style("empty")
	dialog_position("middle")
    game:start_dialog("_treasure.apple.2", function()
      surface:fade_surface(60)
	  sol.timer.start(1200, function()
	    game:set_dialog_style("default")
	    move_npc()
	  end)
    end)
  end
  sol.menu.start(map, self)
end

return cutscene