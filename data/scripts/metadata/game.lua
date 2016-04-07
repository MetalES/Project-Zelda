local game_metatable = sol.main.get_metatable("game")

-- Stamina functions mirror magic and life functions.
function game_metatable:get_stamina()
  return self:get_value("i1024")
end

function game_metatable:set_stamina(value)
  if value > self:get_max_stamina() then value = self:get_max_stamina() end
  return self:set_value("i1024", value)
end

function game_metatable:add_stamina(value)
  local stamina = self:get_value("i1024") + value
  if value >= 0 then
    if stamina > self:get_max_stamina() then stamina = self:get_max_stamina() end
    return self:set_value("i1024", stamina)
  end
end

function game_metatable:remove_stamina(value)
  local stamina = self:get_value("i1024") - value
  if value >= 0 then
    if stamina < 0 then stamina = 0 end
    return self:set_value("i1024", stamina)
  end
end

function game_metatable:get_max_stamina()
  return self:get_value("i1025")
end

function game_metatable:set_max_stamina(value)
  if value >= 20 then
    return self:set_value("i1025", value)
  end
end

function game_metatable:add_max_stamina(value)
  local stamina = self:get_value("i1025")
  if value > 0 then
    return self:set_value("i1025", stamina+value)
  end
end

function game_metatable:get_random_map_position()
  function random_8(lower, upper)
    math.randomseed(os.time())
    return math.random(math.ceil(lower/8), math.floor(upper/8))*8
  end
  function random_points()
    local x = random_8(1, 1120)
    local y = random_8(1, 1120)
    if self:get_map():get_ground(x,y,1) ~= "traversable" then
       random_points()
    else
      return x,y
    end
  end
end  