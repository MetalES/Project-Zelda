local item = ...
local game = item:get_game()
local volume_bgm = sol.audio.get_music_volume()
local bow_state = game:get_value("bow_state") -- strange, if I put it here, the default value is 1

-- TODO : -Elemental Arrows (Fire, Ice, Light is already made, wrightmat's default code include it)
--        -Direction Fix
--        -disable hero heatures while using the item (pushing, pulling, etc)
-- initialisation of the bow mechanism

function item:on_created()
  self:set_savegame_variable("i1801")
  self:set_amount_savegame_variable("i1802")
  self:set_assignable(true)
  self:set_sound_when_brandished("/common/big_item")
  game:set_value("bow_state", 0)
end

function item:on_obtained()
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_started()
  game:set_value("bow_state", 0)
end

function game:on_map_changed(map)
local map = game:get_map()
local hero = map:get_hero()
  game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
  game:set_value("bow_state", 0)
  hero:set_walking_speed(88)
  game:set_pause_allowed(true)
  self:set_finished()
end

function item:on_finished() -- we are destroying the item, reset the hero
local map = game:get_map()
local hero = map:get_hero()
  game:set_ability("tunic", game:get_value("item_saved_tunic"))
  game:set_ability("sword", game:get_value("item_saved_sword"))
  game:set_ability("shield", game:get_value("item_saved_shield"))
  game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
  game:set_value("bow_state", 0)
  hero:set_walking_speed(88)
  game:set_pause_allowed(true)
  self:set_finished()
end

local function store_equipment()
    local tunic = game:get_ability("tunic")
    game:set_ability("tunic", 1)
    local sword = game:get_ability("sword")
    game:set_ability("sword", 0)
    local shield = game:get_ability("shield")
    game:set_ability("shield", 0)
	local kb_action_key = game:get_command_keyboard_binding("action")
	game:set_command_keyboard_binding("action", nil)
    game:set_value("item_saved_tunic", tunic)
    game:set_value("item_saved_sword", sword)
    game:set_value("item_saved_shield", shield)
	game:set_value("item_saved_action", kb_action_key)
end

-- now, we have pressed it's input, tell the game what to do

function item:on_using()  
local map = self:get_map()
local hero = map:get_entity("hero")
local x, y = hero:get_position()
local bow_state = game:get_value("bow_state")
local can_fire = game:get_value("can_shoot")
local tunic = game:get_ability("tunic")

 -- check if hookshot or another item is actually on, if yes, finish the other and start this one
hero.fixed_direction = hero:get_direction()

  if game:get_value("bow_state") == 0 then 
    game:set_pause_allowed(false)
    game:set_value("direction_fix", true)
    game:set_value("item_using", true) -- return if we're using the item 
	hero:freeze()
	game:set_value("direction_fix", true)
	store_equipment()
	sol.audio.play_sound("common/bars_dungeon")
	sol.audio.play_sound("common/item_show")
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
      sol.timer.start(100, function()
	    hero:set_walking_speed(40)
		hero:unfreeze()
		game:set_value("bow_state", 1)
		hero:set_tunic_sprite_id("hero/item/bow/bow_moving_free_tunic"..tunic)
	  end)
  elseif game:get_value("bow_state") == 1 then
  if key == "c" and bow_state == 1 and can_fire == false and not game:is_suspended() and not is_cutscene then -- this one don't need key_press, it just check if the sword button is pressed and then end the bow
    hero:freeze()
	sol.audio.play_sound("common/item_show")
	hero:set_tunic_sprite_id("hero/item/bow/bow_shoot_tunic"..tunic)
      sol.timer.start(100, function()
	    hero:set_walking_speed(88)
		hero:set_tunic_sprite_id("hero/tunic" .. game:get_value("item_saved_tunic"))
        game:set_ability("tunic", game:get_value("item_saved_tunic"))
        game:set_ability("sword", game:get_value("item_saved_sword"))
        game:set_ability("shield", game:get_value("item_saved_shield"))
		game:set_command_keyboard_binding("action", game:get_value("item_saved_action"))
		game:set_value("bow_state", 0)
		hero:unfreeze()
		game:get_item("bow"):set_finished()
	  end)
	end
end

function shoot_arrow()
      sol.audio.play_sound("/items/bow/shoot")
      self:remove_amount(1)
      local x, y = hero:get_center_position()
      local _, _, layer = hero:get_position()
      local arrow = map:create_custom_entity({
        x = x,
        y = y,
        layer = layer,
        direction = hero:get_direction(),
        model = "arrow",
      })
      arrow:set_force(self:get_force())
      arrow:set_sprite_id(self:get_arrow_sprite_id())
      arrow:go()
 end 


end

-- things bellow are logical item function, untouched

function item:on_amount_changed(amount)
  if self:get_variant() ~= 0 then
    if amount == 0 then
      self:set_variant(1)
    else
      self:set_variant(2)
    end
  end
end

function item:on_obtaining(variant, savegame_variable)
  local arrow = game:get_item("arrow")
  local quiver = game:get_item("quiver")

  sol.audio.set_music_volume(0)

  if not quiver:has_variant() then
    -- Give the first quiver and some arrows with the bow.
    quiver:set_variant(1)
    self:add_amount(30)
    arrow:set_obtainable(true)
  else
    -- Set the max value of the bow counter.
    local max_amounts = {30, 60, 100}
    local max_amount = max_amounts[quiver:get_variant()]
    self:set_max_amount(max_amount)
  end
  if amount == 0 then self:set_variant(1) else self:set_variant(2) end
end

function item:get_force()
  return 2
end

function item:get_arrow_sprite_id()
  return "entities/arrow"
end

-- Initialize the metatable of appropriate entities to work with custom arrows.
local function initialize_meta()
  -- Add Lua arrow properties to enemies.
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.set_attack_arrow ~= nil then
    -- Already done.
    return
  end

  enemy_meta.arrow_reaction = "force"
  enemy_meta.arrow_reaction_sprite = {}
  function enemy_meta:get_attack_arrow(sprite)
    if sprite ~= nil and self.arrow_reaction_sprite[sprite] ~= nil then
      return self.arrow_reaction_sprite[sprite]
    end

    if self.arrow_reaction == "force" then
      -- Replace by the current force value.
      local game = self:get_game()
 -- TODO : Elemental Arrows
      if game:has_item("bow_light") then
        return game:get_item("bow_light"):get_force()
      end
      return game:get_item("bow"):get_force()
    end

    return self.arrow_reaction
  end

  function enemy_meta:set_attack_arrow(reaction, sprite)
    self.arrow_reaction = reaction
  end

  function enemy_meta:set_attack_arrow_sprite(sprite, reaction)
    self.arrow_reaction_sprite[sprite] = reaction
  end

  -- Change the default enemy:set_invincible() to also take into account arrows.
  local previous_set_invincible = enemy_meta.set_invincible
  function enemy_meta:set_invincible()
    previous_set_invincible(self)
    self:set_attack_arrow("ignored")
  end
  local previous_set_invincible_sprite = enemy_meta.set_invincible_sprite
  function enemy_meta:set_invincible_sprite(sprite)
    previous_set_invincible_sprite(self, sprite)
    self:set_attack_arrow_sprite(sprite, "ignored")
  end
end

initialize_meta()