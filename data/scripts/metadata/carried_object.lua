local carried_meta = sol.main.get_metatable("carried_object")
-- if the carried object is above lava / water / hole, play an animation.
-- Since we can't carry object in these grounds (as it is in this project), that save a lot of time.
function carried_meta:on_removed()
  local map = self:get_map()
  local x, y, z = self:get_position()
  local sprite
	
  if map:get_ground(x, y, z) == "lava" then
	local lava_splash = map:create_custom_entity({x = x, y = y, layer = z, direction = 0})    
    local sprite = lava_splash:create_sprite("entities/carried_ground_effect")
    sprite:set_animation("lava")
	sol.audio.play_sound("common/item_in_lava")
	function sprite:on_animation_finished() lava_splash:remove() end
  elseif map:get_ground(x, y, z) == "deep_water" then
	local water_splash = map:create_custom_entity({x = x, y = y, layer = z, direction = 0})    
    local sprite = water_splash:create_sprite("entities/carried_ground_effect")
    sprite:set_animation("water")
	sol.audio.play_sound("common/item_in_water")
	function sprite:on_animation_finished() water_splash:remove() end
  elseif map:get_ground(x, y, z) == "hole" then
	local effect = map:create_custom_entity({x = x, y = y, layer = z, direction = 0})    
    local sprite = effect:create_sprite("entities/carried_ground_effect")
    sprite:set_animation("fall")
	function sprite:on_animation_finished() effect:remove() end
	sol.audio.play_sound("common/item_in_hole")
  end
end
  
function carried_meta:on_position_changed()
  if self:get_map():has_entity("kdongo_mouth") then
	if self:get_distance(self:get_map():get_entity("kdongo_mouth")) < 20 and (self:get_game():get_hero():get_animation() ~= "carrying_stopped" and self:get_game():get_hero():get_animation() ~= "carrying_walking" and self:get_game():get_hero():get_animation() ~= "lifting") and not self:get_game().king_dodongo_swallowing_bomb then
	  self:get_game():simulate_command_pressed("action")
	  sol.timer.start(1, function()
		self:remove()
		self:get_game().king_dodongo_swallowing_bomb = true
	  end)
	end
  end
end
