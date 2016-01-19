-- Deku Nuts
local bombchu = ...
local explosion = false

function bombchu:on_created()
  bombchu:set_size(8, 8)
  bombchu:set_origin(4, 8)
  
local bombchu_mvt = sol.movement.create("straight")
bombchu_mvt:set_angle(self:get_game():get_hero():get_direction() * math.pi / 2)
bombchu_mvt:set_speed(120)
bombchu_mvt:set_max_distance(300)
bombchu_mvt:set_smooth(false)
bombchu_mvt:start(self, function() self:explode() end)

sol.audio.play_sound("items/bombchu/start")

bombchu_trail = sol.timer.start(bombchu, 15, function()
local lx, ly, llayer = self:get_position()
local trail = self:get_game():get_map():create_custom_entity({
				x = lx,
				y = ly,
				layer = llayer,
				direction = bombchu:get_direction(),
				sprite = "entities/misc/item/bombchu/b_trail",
			    })
			trail:get_sprite():fade_out(22, function() trail:remove() end)
		return true
end)

bombchu_snd = sol.timer.start(bombchu, 60, function() sol.audio.play_sound("items/bombchu/loop") return true end)

function self:on_obstacle_reached()
if not explosion then 
self:explode()
explosion = true
end
end
end

-- Hurt enemies.
bombchu:add_collision_test("sprite", function(bombchu, entity)
  if entity:get_type() == "enemy" then
    if not explosion then 
		bombchu:explode()
		bombchu:remove()
		explosion = true
	end
  end
end)

-- Traversable rules.
bombchu:set_can_traverse("crystal", false)
bombchu:set_can_traverse("crystal_block", false)
bombchu:set_can_traverse("hero", true)
bombchu:set_can_traverse("jumper", true)
bombchu:set_can_traverse("stairs", false)
bombchu:set_can_traverse("stream", true)
bombchu:set_can_traverse("switch", true)
bombchu:set_can_traverse("teletransporter", true)
bombchu:set_can_traverse_ground("deep_water", false)
bombchu:set_can_traverse_ground("shallow_water", true)
bombchu:set_can_traverse_ground("hole", false)
bombchu:set_can_traverse_ground("lava", false)
bombchu:set_can_traverse_ground("prickles", true)
bombchu:set_can_traverse_ground("low_wall", false)
bombchu.apply_cliffs = true

function bombchu:explode()
if bombchu_trail ~= nil then bombchu_trail:stop() end
if bombchu_snd ~= nil then bombchu_snd:stop() end
local bx, by, blayer = self:get_position()
sol.audio.play_sound("explosion")
local explosion = self:get_game():get_map():create_explosion({
	x = bx,
	y = by,
	layer = blayer,
})
sol.timer.start(200, function() explosion = false self:remove() end)
end
