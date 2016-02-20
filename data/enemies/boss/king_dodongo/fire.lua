local fire = ...
local sprite

-- King Dodongo - Fire

function fire:on_created()
  self:set_damage(2)
  self:set_pushed_back_when_hurt(false)
  self:set_invincible()
  self:set_can_attack(true)
  self:set_traversable(true)
end

function fire:on_restarted()
  sprite = self:create_sprite("entities/fire_burns")
  self:set_damage(2)
  self:set_pushed_back_when_hurt(false)
  self:set_invincible()
  self:set_can_attack(true)
  self:set_traversable(true)
  -- The animation is finished, remove this enemy.
	sol.timer.start(1200, function()
	  fire:remove()
	end)
end