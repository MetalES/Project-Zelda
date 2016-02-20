local enemy = ...
local sprite = nil

function enemy:on_created()
  sprite = self:create_sprite("enemies/boss/d_king/mouth")
  self:set_treasure(nil)
  self:set_optimization_distance(0)
  -- protect the mouth from any other custom items
  self:set_hammer_reaction("protected", sprite)
  self:set_attack_arrow("protected", sprite)
  self:set_ice_reaction("protected", sprite)
  self:set_fire_reaction("protected", sprite)
  self:set_deku_reaction("protected", sprite)
  self:set_attack_hookshot("protected", sprite)
  self:set_attack_boomerang_sprite("protected", sprite)

  self:set_invincible()
  self:set_attack_consequence("sword", "protected")
  self:set_attack_consequence("thrown_item", "custom")
end

function enemy:on_custom_attack_received()
  if not self:get_game().king_dodongo_swallowing_bomb then
    self:get_game().king_dodongo_swallowing_bomb = true
  end
end

function enemy:on_enabled()
  sprite:set_frame_delay(5000)
  sol.timer.start(500, function()
	sprite:set_frame(1)
	  sol.timer.start(500, function()
	    sprite:set_frame(2)
		  sol.timer.start(500, function()
		   sprite:set_frame(3)
			sol.timer.start(500, function()
		    	sprite:set_frame(4)
				sol.timer.start(500, function()
					sprite:set_frame(5)
					sol.timer.start(250, function()
					end)
				end)
			end)
		end)
	end)
  end)
end

function enemy:on_restarted()
  sprite:set_animation("vulnerable")
end

function enemy:on_disabled()
  self:get_game().king_dodongo_swallowing_bomb = false
end