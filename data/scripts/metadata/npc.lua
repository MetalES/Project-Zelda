local npc_meta = sol.main.get_metatable("npc")

local shop_manager = require("scripts/gameplay/shop_manager") -- Load the shop system and attach it to an NPC.

-- Give default dialog styles and certain event to certain entities.
function npc_meta:on_interaction()
  local name = self:get_name()
  local game = self:get_game()
  
  -- Apply dialog box style to some objects
  if name:match("^sign_") or name:match("^mailbox_") then game:set_dialog_style("wood")
  elseif name:match("^hint_") then game:set_dialog_style("stone")
  else game:set_dialog_style("default") 
  end
  
  -- Apply custom systems to some objects
  if name:match("^shop") then shop_manager:start_shop(game)
  end
  
end

  -- Make certain entities automatic hooks for the hookshot.
function npc_meta:is_hookshot_hook()
  local anim_set = self:get_sprite():get_animation_set()
  if self:get_sprite() ~= nil then
    if anim_set == "entities/sign" then return true
    elseif anim_set == "entities/mailbox" then return true
    elseif anim_set == "entities/pot" then return true
    elseif anim_set == "entities/block" then return true
    elseif anim_set == "entities/chest" then return true
    elseif anim_set == "entities/chest_big" then return true
    elseif anim_set == "entities/torch" then return true
    elseif anim_set == "entities/torch_wood" then return true
    else return false end
  else return false end
end
