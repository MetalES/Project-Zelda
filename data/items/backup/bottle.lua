-- This script handles all bottles (each bottle script runs it).

local item = ...

function item:on_using()
  local variant = self:get_variant()
  local game = self:get_game()
  local map = self:get_map()

  -- empty bottle
  if variant == 1 then
    sol.audio.play_sound("wrong")
    self:set_finished()

    -- water
  elseif variant == 2 then
    -- ask the hero to pour away the water
    game:start_dialog("use_bottle_with_water", function(answer)
      if answer == 1 then
	-- empty the water
	self:set_variant(1) -- make the bottle empty
	sol.audio.play_sound("item_in_water")
      end
      self:set_finished()
    end)

    -- red potion
  elseif variant == 3 then
    game:add_life(game:get_max_life())
    self:set_variant(1)
    self:set_finished()

    -- green potion
  elseif variant == 4 then
    game:add_magic(game:get_max_magic())
    self:set_variant(1)
    self:set_finished()

    -- blue potion
  elseif variant == 5 then
    game:add_stamina(game:get_max_stamina())
    self:set_variant(1)
    self:set_finished()

    -- revitalizing potion
  elseif variant == 6 then
    game:add_life(game:get_max_life())
    game:add_magic(game:get_max_magic())
    game:add_stamina(game:get_max_stamina())
    self:set_variant(1)
    self:set_finished()

    -- fairy
  elseif variant == 7 then
    -- release the fairy
    local x, y, layer = map:get_entity("hero"):get_position()
    map:create_pickable{
      treasure_name = "fairy",
      treasure_variant = 1,
      x = x,
      y = y,
      layer = layer
    }
    self:set_variant(1) -- make the bottle empty
    self:set_finished()

    -- poe soul
  elseif variant == 8 then
    -- release the poe soul
    local x, y, layer = map:get_entity("hero"):get_position()
    map:create_pickable{
      treasure_name = "poe_soul",
      treasure_variant = 1,
      x = x,
      y = y,
      layer = layer
    }
    self:set_variant(1) -- make the bottle empty
    self:set_finished()
  end
end

function item:on_npc_interaction(npc)
  if npc:get_name():find("^water_for_bottle") then
    local game = self:get_game()
    local map = self:get_map()
    -- The hero interacts with a place where he can get some water.
    if game:has_bottle() then
      local first_empty_bottle = game:get_first_empty_bottle()
      if first_empty_bottle ~= nil then
        game:start_dialog("found_water", function(answer)
	  if answer == 1 then
            local hero = map:get_entity("hero")
            hero:start_treasure(first_empty_bottle:get_name(), 2, nil)
	  end
	end)
      else
        game:start_dialog("found_water.no_empty_bottle")
      end
    else
      game:start_dialog("found_water.no_bottle")
    end
  end
end

function item:on_npc_interaction_item(npc, item_used)
  if item_used:get_name():find("^bottle")
      and npc:get_name():find("^water_for_bottle") then
    -- the hero interacts with a place where he can get some water:
    -- no matter whether he pressed the action key or the item key of a bottle, we do the same thing
    self:on_npc_interaction(npc)
    return true
  end
  return false
end
