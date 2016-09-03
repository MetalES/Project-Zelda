local custom_entity_meta = sol.main.get_metatable("custom_entity")

function custom_entity_meta:is_hookshot_hook()
  local sprite = self:get_sprite()
  local anim_set = sprite:get_animation_set()
  
  if sprite ~= nil then
    if anim_set == "entities/dungeon/big_chest_key" then return true
	elseif anim_set == "entities/dungeon/big_chest_default" then return true
	elseif anim_set == "entities/dungeon/small_chest_gold" then return true

    else return false end
  else return false end

end