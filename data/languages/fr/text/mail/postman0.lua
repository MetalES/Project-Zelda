-- This is a sample  of how the mail's content is displayed.
-- You can modify the strings / add pages if needed.

--[[
  /// For Translators
  
  If you see a string that have a blank space and a $ symbol (eg. " $", don't delete it, this is a line skipping defined by the host script.
  Do not delete the .. that are after the strings.
  Do not translate the string and the value of ["reward"] and object like "game:get_value("player_name")
  If you need to declare another page (It is possible), you can do it like so :
  
  [number] = (
    "blablabla$" ..
    "blabla$" .. 
    " $" ..
    "blablabla"  
  ),
  
  You don't have to do any script modification, page are automatically parsed
--]]

local game = sol.main.game
local player = game:get_value("player_name")

local text = {
  [0] = (
    "Header$" ..
    " $" ..
    "Line1$" ..
    "Line2$" ..
    "Line3$" ..
    "Line4$" ..
    "Line5$" ..
    "Line6$" ..
    "Line7$" ..
    "Line8"
  ),
	
  [1] = (
    " " .. player .. "$" ..
    "Line1Page1$" ..
    "Line2Page1$" ..
    "Line3Page1$" ..
    "Line4Page1$" ..
    "Line5Page1$" ..
    "Line6Page1$" ..
    "Line7Page1$" ..
    "Line8Page1$" ..
    "Line9Page1"
  ),
  
  [2] = (
    " " .. player .. "$" ..
    ":)$" ..
    ":)$" ..
    "Line3Page1$" ..
    "Line4Page1$" ..
    "Line5Page1$" ..
    "Line6Page1$" ..
    "Line7Page1$" ..
    "Line8Page1$" ..
    "Line9Page1"
  ),
  
  [3] = "lfflk",

  -- Do not translate this !
  -- Reward       Savegame variable       Item        Variant
  ["reward"] = {"letter_from_postman", "heart_piece"}
}

function text:get_max_page()
  return table.getn(text)
end

return text