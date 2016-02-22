local item = ...
local game = item:get_game()

local item_name = "bow"
local sound_played_on_brandish = "/common/big_item"
local sound_played_when_picked = nil
local is_assignable = true

local volume_bgm = game:get_value("old_volume")
item.BowCheckForAmmo = ""

-- load the script when the game has made this item
sol.main.load_file("scripts/gameplay/hero/bow_controller")(game)

-- TODO : -Elemental Arrows (Fire, Ice) -- > Todo. 
--        -Direction Fix
--        -disable hero features while using the item (pushing, pulling, etc)
--        -check ground bellow hero

local function set_state(int)
  game:set_value("item_"..item_name.."_state", int)
end

local function get_state()
  return game:get_value("item_"..item_name.."_state")
end

function item:on_created()
  self:set_savegame_variable("item_"..item_name.."_possession")
  self:set_amount_savegame_variable("item_"..item_name.."_current_amount")
  self:set_assignable(is_assignable)
  self:set_sound_when_picked(sound_played_when_picked)
  self:set_sound_when_brandished(sound_played_on_brandish)
  set_state(0)
end

-- The Item was obtained and the dialog has passed
function item:on_obtained()
  game:show_cutscene_bars(false)
  sol.audio.set_music_volume(volume_bgm)
end

function item:on_map_changed()
  if get_state() > 0 then 
	game:get_hero():freeze()
	game:get_hero():set_tunic_sprite_id("hero/tunic"..game:get_value("item_saved_tunic"))
	game:set_ability("sword", game:get_value("item_saved_sword"))
	game:get_hero():set_walking_speed(88)
	if not game:is_current_scene_cutscene() then game:show_cutscene_bars(false); game:set_pause_allowed(true) game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("item_saved_shield")); game:set_ability("shield", game:get_value("item_saved_shield")) end
	game:set_custom_command_effect("attack", nil)
	game:get_hero():unfreeze()
	self:set_finished()
  end
end

function item:transit_to_finish()
  game:stop_bow()
end

function item:store_equipment()
  local kb_action_key = game:get_command_keyboard_binding("action")
  local kb_item_1_key = game:get_command_keyboard_binding("item_1")
  local kb_item_2_key = game:get_command_keyboard_binding("item_2")
  local jp_action_key = game:get_command_joypad_binding("action")
  local jp_item_1_key = game:get_command_joypad_binding("item_1")
  local jp_item_2_key = game:get_command_joypad_binding("item_2")
	
  game:set_ability("sword", 0)
  game:set_ability("shield", 0)
	
  game:set_command_keyboard_binding("action", nil)
  game:set_command_joypad_binding("action", nil)
	
  if game:get_value("_item_slot_1") ~= item_name then game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil) end
  if game:get_value("_item_slot_2") ~= item_name then game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil) end

  game:set_value("item_saved_kb_action", kb_action_key)
  game:set_value("item_1_kb_slot", kb_item_1_key)
  game:set_value("item_2_kb_slot", kb_item_2_key)
  game:set_value("item_saved_jp_action", jp_action_key)
  game:set_value("item_1_jp_slot", jp_item_1_key)
  game:set_value("item_2_jp_slot", jp_item_2_key)
  game:set_pause_allowed(false)
end

function item:on_using()
  local tunic = game:get_value("item_saved_tunic")
  local hero = game:get_hero()
  self.BowStateArmed = "hero/item/bow/bow_moving_" .. self.BowCheckForAmmo .. "arrow_tunic" .. tunic
  self.BowFreeState = "hero/item/bow/bow_moving_free_tunic" .. tunic
  self.BowShoot = "hero/item/bow/bow_shoot_tunic" .. tunic
  
  if self:get_amount() == 0 then
    self.BowCheckForAmmo = ""
  else
    self.BowCheckForAmmo = "with_"
  end
  
  if get_state() == 0 then
    hero:start_bow()
	set_state(1)
  else
    if not game.is_building_new_arrow then
	  hero:set_animation("bow_arming_"..self.BowCheckForAmmo.."arrow")
	else
	  hero:unfreeze()
	end
  end
end

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
    quiver:set_variant(1)
    self:add_amount(30)
    arrow:set_obtainable(true)
  else
    local max_amounts = {30, 60, 100}
    local max_amount = max_amounts[quiver:get_variant()]
    self:set_max_amount(max_amount)
  end
  self:set_variant(2)
end

function item:get_force()
  if self:get_game():get_value("hero_mode") then
    return 1
  else
    return 2
  end
end

function item:get_arrow_sprite_id()
  return "entities/arrow"
end

local function initialize_meta()
  local enemy_meta = sol.main.get_metatable("enemy")
  if enemy_meta.set_attack_arrow ~= nil then
    return
  end

  enemy_meta.arrow_reaction = "force"
  enemy_meta.arrow_reaction_sprite = {}
  function enemy_meta:get_attack_arrow(sprite)
    if sprite ~= nil and self.arrow_reaction_sprite[sprite] ~= nil then
      return self.arrow_reaction_sprite[sprite]
    end

    if self.arrow_reaction == "force" then
      local game = self:get_game()
      -- TODO : Elemental Arrows
      -- if game:has_item("bow_light") then
        -- return game:get_item("bow_light"):get_force()
      -- end
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