local item = ...
local game = item:get_game()

local item_name = "deku_nuts"
local is_assignable = true
local sound_dir = "/items/"..item_name.."/"

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_amount_savegame_variable("item_"..item_name.."_amount")
  self:set_assignable(is_assignable)
end

function item:on_using()
local hero = game:get_hero()
local x, y, layer = hero:get_position()
local direction = hero:get_direction()

hero:freeze()

if self:get_amount() == 0 then
hero:set_animation("rod")
sol.audio.play_sound("characters/link/voice/throw0")
sol.timer.start(200, function() hero:unfreeze() end)
else
hero:set_animation("rod")
sol.audio.play_sound("characters/link/voice/throw0")
sol.audio.play_sound(sound_dir.."throw_effect")
self:remove_amount(1)

local dx, dy
  if direction == 0 then
    dx, dy = 4, -20
  elseif direction == 1 then
    dx, dy = -7, -20
  elseif direction == 2 then
    dx, dy = -4, -20
  else
    dx, dy = 8, -20
  end

  local deku = game:get_map():create_custom_entity({
  x = x + dx,
  y = y + dy,
  layer = layer,
  direction = direction,
  model = "deku_nuts"
  })
  sol.timer.start(200, function() hero:unfreeze() end)
  end
self:set_finished()
end

local function initialize_meta()

  -- Add Lua deku properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.get_deku_reaction ~= nil then
    -- Already done.
    return
  end

  enemy_meta.deku_reaction = "immobilized"
  enemy_meta.deku_reaction_sprite = {}
  function enemy_meta:get_deku_reaction(sprite)

    if sprite ~= nil and self.deku_reaction_sprite[sprite] ~= nil then
      return self.deku_reaction_sprite[sprite]
    end
    return self.deku_reaction
  end

  function enemy_meta:set_deku_reaction(reaction, sprite)

    self.deku_reaction = reaction
  end

  function enemy_meta:set_deku_reaction_sprite(sprite, reaction)

    self.deku_reaction_sprite[sprite] = reaction
  end

  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_deku_reaction("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_deku_reaction_sprite(sprite, "ignored")
  end

end
initialize_meta()