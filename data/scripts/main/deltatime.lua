-- Delta time
local runtime = 0

function sol.main:getDelta()
  local temp = sol.main.get_elapsed_time()
  local deltatime = (temp - runtime) / (1000 / 30)
  runtime = temp
  return deltatime
end