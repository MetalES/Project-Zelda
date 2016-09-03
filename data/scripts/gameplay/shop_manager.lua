local shop_manager = {}

-- initialize containers
local item_name = {}
-- initialize integers
local font_size = 14
-- initilize strings
local vertical_alignement = "middle"
local horizontal_alignment = "left"
local font = "lttp"

function shop_manager:start_shop(game)
  self.game = game
  self.hero = game:get_hero()
  self.map = game:get_map()
  self:retrieve_shop_item_placement() -- Load item placement.
  self.interrupt_display = false
  
  self.map.is_shopping = true
  game:show_cutscene_bars(true)
  game:set_clock_enabled(false)

  self.hero:freeze()
  game:set_custom_command_effect("action", "next")  

  self.dialog_text_line0 = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
    vertical_alignment = vertical_alignment,
    font = font,
    font_size = font_size,
  }
  
  self.dialog_text_line1 = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
    vertical_alignment = vertical_alignment,
    font = font,
    font_size = font_size,
  }
  
  self.dialog_text_line2 = sol.text_surface.create{
    horizontal_alignment = horizontal_alignment,
    vertical_alignment = vertical_alignment,
    font = font,
    font_size = font_size,
  }
  
  self.price_text = sol.text_surface.create{
    horizontal_alignment = "right",
    vertical_alignment = vertical_alignment,
    font = font,
    font_size = font_size,
	color = {102,255,102}
  }

  self.dialog_box_src = sol.surface.create("hud/dialog_box.png")
  self.cursor_sprite = sol.sprite.create("menus/shop_cursor")
  
  self:set_cursor_position(8)
  self:load_item_dialog_box()
  
  sol.menu.start(self.map, self) 
end

function shop_manager:set_cursor_position(position)
  self.cursor_position = position
  
  for i = 0, #item_name do
    if position == i and item_name[i] ~= nil then
	  self.cursor_x = item_name[i].x
	  self.cursor_y = item_name[i].y
	end
  end
  
  if position == 8 then
    self.game:set_custom_command_effect("action", "speak")
	return
  end
  
  self.game:set_custom_command_effect("action", "look")
end

-- Get the information to display items dynamically, this is mostly for the cursor info.
function shop_manager:retrieve_shop_item_placement()
  local map = self.map
  
  for i = 0, #map.shop do 
    item_name[i] = map.shop[i]
  end
  
  item_name[9] = map.shop[9] -- shop multiplier
  item_name[10] = map.shop[10] -- shop type( 1 = beetle)
end

function shop_manager:load_item_dialog_box()  
  local item = item_name
  local position = self.cursor_position
  
  if position ~= 8 then
    self.final_name = item[position].shop_item
    self.variant = item[position]:get_direction() + 1
    self.price = item_name[position].shop_price[self.variant]
    self.amount = item_name[position].shop_amount[self.variant]
    self.final_price = math.floor(self.price * item[9])
  
    self.dialog_text_line0:set_text_key("shop.items."..self.final_name.."."..self.variant)
	self.dialog_text_line0:set_color({255,102,102})
    self.price_text:set_text(sol.language.get_string("shop.items.price") .. self.final_price .. sol.language.get_string("shop.items.currency"))
    self.dialog_text_line1:set_text_key("shop.items." .. self.final_name .. "." .. "item_desc")
	if sol.language.get_string("shop.items." .. self.final_name .. "." .. "item_desc_0") == nil then 
      self.dialog_text_line2:set_text("")
    else
      self.dialog_text_line2:set_text_key("shop.items." .. self.final_name .. "." .. "item_desc_0")
    end
  else
    self.dialog_text_line0:set_text_key("shop.shopkeeper.".. item[10] ..".0")
	self.dialog_text_line0:set_color({255, 255, 255})
    self.dialog_text_line1:set_text_key("shop.shopkeeper.".. item[10] ..".1")
    self.dialog_text_line2:set_text_key("shop.shopkeeper.".. item[10] ..".2")
	self.price_text:set_text("")
  end
end 

function shop_manager:replace_slot_if_needed(index, save_in_savegame)
  local item = item_name[index]
  local x, y, layer = item:get_position()  
  local next_item = self.next_item 
  local next_item_direction = self.next_item_direction
  local next_item_name = self.new_shop_item_name
  
  item_name[index] = nil

  local new_entity = self.map:create_custom_entity({
    model = next_item,
	name = next_item_name,
    x = x,
	y = y,
	width = 8,
	height = 8,
	layer = layer,
    direction = next_item_direction,
	sprite = "entities/items"
  })
  -- reload the array
  item_name[index] = self.map:get_entity(new_entity:get_name())
  item_name[index].x, item_name[index].y = self.map:get_entity(new_entity:get_name()):get_position()
  
  if save_in_savegame then
    self.game:set_value("shop_"..self.map.shop[10].."_item_"..self.map.shop[index]:get_name().."_changed_to", next_item_name)
  end

  self:load_item_dialog_box()
end

function shop_manager:choose_this_item(index) 
  local function return_item(index) 
     local sprite = shop_manager.final_name 
	 local item = item_name[index]
	 
     local target = sol.movement.create("target")
	 target:set_target(item_name[index]:get_position())
	 target:set_speed(200)
	 target:set_ignore_obstacles(true)
	 target:start(shop_manager.item_icon, function() 
	   item:get_sprite():set_animation(sprite) 	  
	   if self.item_icon:get_sprite():get_animation() == "heart" then
	     item:get_sprite():set_frame(24)
		 item:get_sprite():set_frame_delay(160)
	   end 
	   shop_manager.item_icon:remove() 
	 end)
  end
 -- check if the player isn't selecting the shopkeeper, if yes, start a dialog.
  if index == 8 then
    self.interrupt_display = true
    self.game:start_dialog("_shop.shopkeeper." .. self.map.shop[10], function()
	  self.game:set_custom_command_effect("action", "speak")
	  self.interrupt_display = false
	end)
  else
    local item = item_name[index]
    local can_buy = item:can_buy_this_item()
    local x, y, layer = item:get_position()
	local obtainable = self.game:get_item(tostring(self.final_name)):is_obtainable()
	
    self.interrupt_display = true
	item:get_sprite():set_animation("random")
	sol.timer.start(sol.main, 10, function()
	  self.item_icon = self.map:create_custom_entity({
	    x = x,
	    y = y,
	    layer = layer,
		width = 8,
		height = 8,
	    direction = 0,
        sprite = "entities/items"
	  })
	  
	  self.item_icon:get_sprite():set_animation(self.final_name)
	  if self.item_icon:get_sprite():get_animation() == "heart" then
	      self.item_icon:get_sprite():set_frame(24)
	      self.item_icon:get_sprite():set_frame_delay(160)
	  end
	  
	  self.item_icon:get_sprite():set_direction(self.variant - 1)
	  self.item_icon:set_drawn_in_y_order(true)
	  local sx, sy, sl = self.map:get_entity("shop"):get_position()
	  local target = sol.movement.create("target")
	  target:set_target(sx, sy - 8, sl)
	  target:set_speed(200)
	  target:set_ignore_obstacles(true)
	  target:start(self.item_icon)
	end)
	  
    self.game:start_dialog("_shop.item.buy_this", function(answer)
	 if answer == 1 then
	    sol.audio.play_sound("menu/select")
	    if self.game:get_money() < self.final_price then
		  self.game:start_dialog("_shop.not_enough_money", function() return_item(index) self.game:set_custom_command_effect("action", "look") self.interrupt_display = false end)
		elseif not obtainable then
		  self.game:start_dialog("_shop.cant_buy_this_item_not_obtained", function() return_item(index) self.game:set_custom_command_effect("action", "look") self.interrupt_display = false end)
		else
		  if can_buy then
		    self.item_icon:remove()
            self.game:set_money(self.game:get_money() - self.final_price)
			self.map.is_buying_from_shop = true
			sol.timer.start(100, function()
			  self.hero:set_direction(2)
			end)
			sol.timer.start(200, function()
			  self.hero:set_direction(3)
			  self.hero:set_animation("chest_holding_before_brandish")
			end)
			sol.timer.start(1300, function()
			   self.hero:set_direction(1)
			   sol.audio.set_music_volume(0)
			   self.hero:start_treasure(item:get_target_item(), self.variant, nil, function()
				 if item:get_target_item() == "heart_piece" then
				   local message_id = {
					"found_piece_of_heart.first",
					"found_piece_of_heart.second",
					"found_piece_of_heart.third",
					"found_piece_of_heart.fourth"}
				    local nb_pieces_of_heart = self.game:get_value("i1700") or 0
					self.game:start_dialog(message_id[nb_pieces_of_heart + 1], function()
					  self.game:set_value("i1700", (nb_pieces_of_heart + 1) % 4)
					  if nb_pieces_of_heart == 3 then
						self.game:add_max_life(4)
					  end
					  self.game:add_life(self.game:get_max_life())
					  self:continue_shop()
					end)
				 else
				   self:continue_shop()
				 end
			   end)
			end)
          else
			if item_name[index].dont_need_more_of_this_shop_item then -- enough ammo
			  self.game:start_dialog("_shop.dont_need_more_of_this_shop_item", function() return_item(index) self.game:set_custom_command_effect("action", "look") item.dont_need_more_of_this_shop_item = false self.interrupt_display = false end)
			else -- the hero doesn't have the item
			  return_item(index)
			  self.game:set_custom_command_effect("action", "look")
			end
          end
		end
	  else
		return_item(index)
		self.game:set_custom_command_effect("action", "look")
	    self.interrupt_display = false
	  end
	end)
  end
end

function shop_manager:continue_shop()
  local item = item_name[self.cursor_position]
  sol.timer.start(sol.main, 10, function()
	if item:is_sold_out() then
  	  item:replace_item_on_sold_out() 
	  self.next_item = item.new_shop_item
      self.next_item_direction = item.new_shop_direction
	  self.new_shop_item_name = item.new_shop_item_name
	  self:replace_slot_if_needed(self.cursor_position, true)
	else
	  item:get_sprite():set_animation(self.final_name)
	end
  end)
  self.hero:freeze()
  self.game:start_dialog("_shop.wanna_continue_shopping", function(answer)
	if answer == 1 then
	  self.interrupt_display = false
	  self.game:set_custom_command_effect("action", "look")
	else
	  sol.menu.stop(self)
	end
  end)
end

function shop_manager:on_command_pressed(command)
  if command == "left" and not self.interrupt_display then
    if item_name[10] ~= 1 then
      if self.cursor_position == 0 or self.cursor_position == 4 then
        self:set_cursor_position(self.cursor_position + 3)
	  elseif self.cursor_position == 8 then
	    self:set_cursor_position(5)
	  elseif self.cursor_position == 6 then 
	    self:set_cursor_position(8)
	  else
	    self:set_cursor_position(self.cursor_position - 1)
	  end
	else
	  if self.cursor_position == 8 then
	    self:set_cursor_position(2)
	  elseif self.cursor_position == 0 then
		self:set_cursor_position(8)
	  else
		self:set_cursor_position(self.cursor_position - 1)
	  end
	end
    sol.audio.play_sound("menu/cursor")
  elseif command == "right" and not self.interrupt_display then
    if item_name[10] ~= 1 then
      if self.cursor_position == 3 or self.cursor_position == 7 then
		self:set_cursor_position(self.cursor_position - 3)
	  elseif self.cursor_position == 8 then
		self:set_cursor_position(6)
	  elseif self.cursor_position == 5 then 
		self:set_cursor_position(8)
	  else
		self:set_cursor_position(self.cursor_position + 1)
	  end
	else
	  if self.cursor_position == 2 then
	    self:set_cursor_position(8)
	  elseif self.cursor_position == 8 then
		self:set_cursor_position(0)
	  else
		self:set_cursor_position(self.cursor_position + 1)
	  end
	end
    sol.audio.play_sound("menu/cursor")
  elseif command == "up" and not self.interrupt_display then
    if item_name[10] ~= 1 then
      if self.cursor_position >= 0 and self.cursor_position <= 3  then
	    self:set_cursor_position(self.cursor_position + 4)
	  elseif self.cursor_position >= 4 and self.cursor_position <= 7 then
	    self:set_cursor_position(self.cursor_position - 4)
	  elseif self.cursor_position == 8 then
	    self:set_cursor_position(1)
	  end
	else
	  self:set_cursor_position(8)
	end
	sol.audio.play_sound("menu/cursor")

  elseif command == "down" and not self.interrupt_display then
    if item_name[10] ~= 1 then
      if self.cursor_position >= 4 and self.cursor_position <= 8 then
	    self:set_cursor_position(self.cursor_position - 4)
	  elseif self.cursor_position >= 0 and self.cursor_position <= 3 then
	    self:set_cursor_position(self.cursor_position + 4)
	  end
	else
	  self:set_cursor_position(8)
	end
    sol.audio.play_sound("menu/cursor")
	
  elseif command == "action" and not self.interrupt_display then
    sol.audio.play_sound("menu/select")
	self:choose_this_item(self.cursor_position)
	
  elseif command == "attack" and not self.interrupt_display then
	sol.menu.stop(self)
	self.game:get_hero():unfreeze()
  end
  self:load_item_dialog_box()
  return true
end

function shop_manager:on_finished()
  self.game:set_clock_enabled(true)
  self.game:show_cutscene_bars(false) 
  self.game:set_custom_command_effect("action", nil)
  self.map.is_shopping = false
  self.hero:unfreeze()
end

function shop_manager:on_draw(dst_surface)
  local width, height = dst_surface:get_size()
  local x = width / 2
  local y = height / 2
  
  if not self.interrupt_display then
    self.dialog_box_src:draw_region(0, 0, 280, 60, dst_surface, x - 140, y + 24)
	self.dialog_text_line0:draw(dst_surface, x - 124, 164)
	self.dialog_text_line1:draw(dst_surface, x - 124, 177)
	self.dialog_text_line2:draw(dst_surface, x - 124, 190)
	if self.price_text:get_text() ~= nil then
	  self.price_text:draw(dst_surface, x + 124, 164)
	end
	self.cursor_sprite:draw(dst_surface,  self.cursor_x,  self.cursor_y)
  end
end

return shop_manager