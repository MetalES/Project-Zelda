local submenu = require("scripts/menus/pause_submenu")
local equipment_submenu = submenu:new()
local current_sword

--TODO draw a marker on the current tunic / sword when multiple are avilable


function equipment_submenu:on_started()

  submenu.on_started(self)
  self.equipment_surface = sol.surface.create(320, 240)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.caption_text_keys = {}
  
  local item_sprite = sol.sprite.create("entities/items")
  
  -- store the primary sword value (for biggoron sword)
  current_sword = sol.main.game:get_ability("sword")
  if current_sword > 0 and current_sword < 5 then 
  self.game:set_value("equipment_sword", current_sword)
  end
  
  self.tunic_paperdoll_sprite = sol.sprite.create("entities/items")
  self.tunic_paperdoll_sprite:set_animation("tunic_paperdoll")
  self.tunic_paperdoll_sprite:set_direction(self.game:get_value("item_saved_tunic") - 1)
	
  self.current_tunic_sprite = sol.sprite.create("entities/items")
  self.current_tunic_sprite:set_animation("item_equipment_current")
  self.current_tunic_sprite:set_direction(0)
  
  if self.game:get_item("sword"):get_variant() > 0 then
  self.current_sword_sprite = sol.sprite.create("entities/items")
  self.current_sword_sprite:set_animation("item_equipment_current")
  self.current_sword_sprite:set_direction(0)
	
  local sword_paperdoll = self.game:get_item("sword"):get_variant()
  self.sword_paperdoll_sprite = sol.sprite.create("entities/items")
  self.sword_paperdoll_sprite:set_animation("sword_paperdoll")
  self.sword_paperdoll_sprite:set_direction(current_sword - 1)
  end
  
  -- Draw the items on a surface.
  self.equipment_surface:clear()

  -- Tunics.
  local tunic0 = self.game:get_item("tunic"):get_variant()
  if tunic0 > 0 then
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(0)
  item_sprite:draw(self.equipment_surface, 209, 180)
  self.caption_text_keys[5] = "equipment.caption.tunic_1"   
  end  

  if self.game:get_value("tunic_2_obtained") == true then
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(1)
  item_sprite:draw(self.equipment_surface, 233, 180)
  self.caption_text_keys[6] = "equipment.caption.tunic_2" 
  end
  
  if self.game:get_value("tunic_3_obtained") == true then
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(2)
  item_sprite:draw(self.equipment_surface, 257, 180)
  self.caption_text_keys[7] = "equipment.caption.tunic_3" 
  end


  -- Sword.
  local sword = self.game:get_item("sword"):get_variant()
  if sword > 0 then
    item_sprite:set_animation("sword")
    item_sprite:set_direction(sword - 1)
    item_sprite:draw(self.equipment_surface, 217, 84)
    self.caption_text_keys[4] = "equipment.caption.sword_" .. sword
  end

  -- Shield.
  local shield = self.game:get_item("shield"):get_variant()
  if shield > 0 then
    item_sprite:set_animation("shield")
    item_sprite:set_direction(shield - 1)
    item_sprite:draw(self.equipment_surface, 233, 132)
    self.caption_text_keys[9] = "equipment.caption.shield_" .. shield
  end
  
  -- Glove.
  local glove = self.game:get_item("glove"):get_variant()
  if glove > 0 then
    item_sprite:set_animation("glove")
    item_sprite:set_direction(glove - 1)
    item_sprite:draw(self.equipment_surface, 209, 132)
    self.caption_text_keys[8] = "equipment.caption.item.glove." .. glove
  end

  -- Wallet.
  local rupee_bag = self.game:get_item("rupee_bag"):get_variant()
  if rupee_bag > 0 then
    item_sprite:set_animation("rupee_bag")
    item_sprite:set_direction(rupee_bag - 1)
    item_sprite:draw(self.equipment_surface, 68, 85)
    self.caption_text_keys[0] = "equipment.caption.rupee_bag_" .. rupee_bag
  end

  -- Bomb bag.
  if self.game:get_item("bomb_bag") ~= nil then
    local bomb_bag = self.game:get_item("bomb_bag"):get_variant()
    if bomb_bag > 0 then
      item_sprite:set_animation("bomb_bag")
      item_sprite:set_direction(bomb_bag - 1)
      item_sprite:draw(self.equipment_surface, 68, 115)
      self.caption_text_keys[1] = "equipment.caption.bomb_bag_" .. bomb_bag
    end
  end

  -- Quiver.
  if self.game:get_item("quiver") ~= nil then
    local quiver = self.game:get_item("quiver"):get_variant()
    if quiver > 0 then
      item_sprite:set_animation("quiver")
      item_sprite:set_direction(quiver - 1)
      item_sprite:draw(self.equipment_surface, 68, 145)
      self.caption_text_keys[2] = "equipment.caption.quiver_" .. quiver
    end
  end
  
  -- Deku Nut Bag.
  local deku = self.game:get_item("deku_nuts_bag"):get_variant()
  if deku > 0 then
    item_sprite:set_animation("deku_nuts_bag")
    item_sprite:set_direction(deku - 1)
    item_sprite:draw(self.equipment_surface, 68, 175)
    self.caption_text_keys[3] = "equipment.caption.deku_nuts_bag_" .. deku
  end
  
  --Shield Paperdoll, no need to redraw like the sword & tunic
  local shield_paperdoll = self.game:get_item("shield"):get_variant()
  if shield_paperdoll > 0 then
    item_sprite:set_animation("shield_paperdoll")
    item_sprite:set_direction(shield_paperdoll - 1)
    item_sprite:draw(self.equipment_surface, 120, 131)
  end
  
  -- Cursor.
  local index = self.game:get_value("equipment_last_index") or 0
  self:set_cursor_position(index)
end

function equipment_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then
    self.cursor_position = position
    if position <= 3 then
      self.cursor_sprite_x = 68
    elseif position == 4 then -- MS
      self.cursor_sprite_x = 217
	elseif position == 5 or position == 8 then -- Tunic, p_bracelet
	  self.cursor_sprite_x = 209
	elseif position == 6 or position == 9 then -- tunic, shield
	  self.cursor_sprite_x = 233
	elseif position == 7 or position == 10 then -- tunic, climb
	  self.cursor_sprite_x = 257
	elseif position == 11 then -- bsword
	  self.cursor_sprite_x = 249
    end

    if position == 0 then
      self.cursor_sprite_y = 80
    elseif position == 1 then
      self.cursor_sprite_y = 110
    elseif position == 2 then
      self.cursor_sprite_y = 140
    elseif position == 4 or position == 11 then -- MS
      self.cursor_sprite_y = 79
	elseif position == 5 or position == 6 or position == 7 then -- tunics
	  self.cursor_sprite_y = 175
	elseif position == 8 or position == 9 or position == 10 then
	  self.cursor_sprite_y = 127
    else
      self.cursor_sprite_y = 170
    end
    self.game:set_value("equipment_last_index", position)
    self:set_caption(self.caption_text_keys[position])
  end
end

function equipment_submenu:on_command_pressed(command)

  local handled = submenu.on_command_pressed(self, command)

  if not handled then

    if command == "left" then
      if self.cursor_position <= 3 then
        self:previous_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
        if self.cursor_position == 4 then
          self:set_cursor_position(0)
        elseif self.cursor_position == 5 then
          self:set_cursor_position(3)
		elseif self.cursor_position == 8 then
		  self:set_cursor_position(2)
		elseif self.cursor_position == 11 then
		  self:set_cursor_position(4)
        else
          self:set_cursor_position(self.cursor_position - 1)
        end
      end
      handled = true

    elseif command == "right" then
      if self.cursor_position == 7 or self.cursor_position == 10 or self.cursor_position == 11 then
        self:next_submenu()
      else
        sol.audio.play_sound("/menu/cursor")
		if self.cursor_position == 0 then -- Rupee to Master Sword
          self:set_cursor_position(4)
		elseif self.cursor_position == 4 then -- Master Sword to Biggoron
		  self:set_cursor_position(11)
        elseif self.cursor_position == 1 or self.cursor_position == 2 then -- Quiver to Power Bracelet
          self:set_cursor_position(8)
		elseif self.cursor_position == 8 and self.cursor_position <= 10 then -- Power Bracelet to Shield
		  self:set_cursor_position(self.cursor_position + 1)
        elseif self.cursor_position == 3 then -- Ocarina to Tunic
          self:set_cursor_position(5)
        else
          self:set_cursor_position(self.cursor_position + 1)
        end
      end
      handled = true

    elseif command == "down" then
      sol.audio.play_sound("/menu/cursor")
	  if self.cursor_position == 4 or self.cursor_position == 7 then
	  self:set_cursor_position(self.cursor_position + 4)
	  elseif self.cursor_position == 11 or self.cursor_position == 5 then
	  self:set_cursor_position(self.cursor_position - 1)
	  elseif self.cursor_position == 8 or self.cursor_position == 9 or self.cursor_position == 10 then 
	  self:set_cursor_position(self.cursor_position - 3)
	  elseif self.cursor_position == 6 then
	  self:set_cursor_position(4)
	  elseif self.cursor_position == 3 then
	  self:set_cursor_position(0)
	  elseif self.cursor_position == 0 or self.cursor_position < 3 then
	  self:set_cursor_position(self.cursor_position + 1)
	  end
      handled = true

    elseif command == "up" then
      sol.audio.play_sound("/menu/cursor")
	  if self.cursor_position == 6 or self.cursor_position == 5 or self.cursor_position == 7 or self.cursor_position == 0 then
      self:set_cursor_position(self.cursor_position + 3)	  
	  elseif self.cursor_position == 8 or self.cursor_position == 11 then 
      self:set_cursor_position(self.cursor_position - 4)
	  elseif self.cursor_position == 9 then 
	  self:set_cursor_position(4)
	  elseif self.cursor_position == 10 or self.cursor_position == 4 then 
	  self:set_cursor_position(self.cursor_position + 1)
	  elseif self.cursor_position <= 3 or self.cursor_position == 4 then
      self:set_cursor_position(self.cursor_position - 1)
	  end
      handled = true
	  
	elseif command == "action" then
	  if self.cursor_position == 4 and self.game:get_ability("sword") > 0 then
	   sol.audio.play_sound("/menu/select")
	   self.sword_paperdoll_sprite:set_direction(self.game:get_ability("sword") - 1)
	   self.game:set_ability("sword", current_sword)
	   
	  elseif self.cursor_position == 5 or self.cursor_position == 6 and self.game:get_value("tunic_2_obtained") == true or self.cursor_position == 7 and self.game:get_value("tunic_3_obtained") == true then
	  sol.audio.play_sound("/menu/select")
      self.tunic_paperdoll_sprite:set_direction(self.cursor_position - 5)
	  self.game:set_ability("tunic", self.cursor_position - 4)
	  self.game:set_value("item_saved_tunic", self.cursor_position - 4)
	  self.game:set_value("i1822", self.cursor_position - 4)
	  
	  elseif self.cursor_position == 11 and self.game:get_value("got_biggoron_sword") == 2 then
	   sol.audio.play_sound("/menu/select")
	   self.game:set_ability("sword", 5)
    end
	handled = true
  end
 end

  return handled
end


function equipment_submenu:on_draw(dst_surface)

  local width, height = dst_surface:get_size()
  local x = width / 2 - 160
  local y = height / 2 - 120

  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.tunic_paperdoll_sprite:draw(dst_surface, 143, 118)
  self.current_tunic_sprite:draw(dst_surface, 185 + 24 *  self.game:get_value("item_saved_tunic"), 175)
  if self.game:get_item("sword"):get_variant() > 0 then
  self.sword_paperdoll_sprite:draw(dst_surface, 170, 141)
  self.current_sword_sprite:draw(dst_surface, 185 + 32 * (self.game:get_value("got_biggoron_sword") or 1) , 79)
  end
  self.equipment_surface:draw(dst_surface, x, y)
  self.cursor_sprite:draw(dst_surface, x + self.cursor_sprite_x, y + self.cursor_sprite_y)
  self:draw_save_dialog_if_any(dst_surface)
end

return equipment_submenu

