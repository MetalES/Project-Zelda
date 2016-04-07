local enemy_meta = sol.main.get_metatable("enemy")

  -- Enemies: redefine the damage of the hero's sword. (The default damages are less important.)
function enemy_meta:on_hurt_by_sword(hero, enemy_sprite)
  -- Here, self is the enemy.
  local game = self:get_game()
  local hero_mode = game:get_value("hero_mode")
  local sword = game:get_ability("sword")
  local damage_factors = { 1, 2, 4, 8 }  -- Damage factor of each sword.
  local damage_factor = damage_factors[sword]
	
  if hero:get_state() == "sword spin attack" then
	if hero_mode then
	  damage_factor = damage_factor
	else
	  damage_factor = damage_factor * 2  -- The spin attack is twice as powerful, but costs more stamina.
	end
  end
	
  if hero:get_state() == "sword swinging" then
	if hero_mode then
	  damage_factor =  damage_factor / 2 -- damage are ridiculous
	else
	  damage_factor = damage_factor  -- Dafault damage value
	end
  end
		
  local reaction = self:get_attack_consequence_sprite(enemy_sprite, "sword")
  self:remove_life(reaction * damage_factor)
end

  -- Helper function to inflict an explicit reaction from a scripted weapon.
function enemy_meta:receive_attack_consequence(attack, reaction)
  if type(reaction) == "number" then
    self:hurt(reaction)
  elseif reaction == "immobilized" then
    self:immobilize()
  elseif reaction == "protected" then
    sol.audio.play_sound("sword_tapping")
  elseif reaction == "custom" then
    if self.on_custom_attack_received ~= nil then
      self:on_custom_attack_received(attack)
    end
  end
end