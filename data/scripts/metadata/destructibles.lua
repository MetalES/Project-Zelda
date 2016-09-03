local destructible_meta = sol.main.get_metatable("destructible")

local function play_sound()
  sol.audio.play_sound("common/bars_dungeon")
end

local function disable_bars(game)
  game:show_cutscene_bars(false)
end

function destructible_meta:on_looked()
  -- Here, self is the destructible object.
  local game = self:get_game()
  
  game:show_cutscene_bars(true)
  play_sound()
  
  if self:get_can_be_cut() and not self:get_can_explode() and not game:has_ability("sword") then
    -- The destructible can be cut, but the player no cut ability.
    game:start_dialog("gameplay.logic._cannot_lift_should_cut", function() disable_bars(game) end);
  elseif not game:has_ability("lift") then
    -- No lift ability at all.
    game:start_dialog("gameplay.logic._cannot_lift_too_heavy", function() disable_bars(game) end);
  else
    -- Not enough lift ability.
    game:start_dialog("gameplay.logic._cannot_lift_still_too_heavy", function() disable_bars(game) end);
  end
end