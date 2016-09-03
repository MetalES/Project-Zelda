local teletransporter_meta = sol.main.get_metatable("teletransporter")

-- Add a algorythm that check if we are in Hero Mode and set the correct destination.
-- Kinda like hero:teleport_to() but for normal teletransporters.
-- Normal warps starts with (/normal/) as it is the default map folder. We need to ignore it and apply a fix on it.
function teletransporter_meta:on_activated()
  local hero_mode = self:get_game():get_value("hero_mode") or false
  local destination = string.sub(self:get_destination_map(), 8)
  local folder = "normal/"

  if hero_mode then
    folder = "mirror/"
  end

  self:set_destination_map(folder .. destination)
end