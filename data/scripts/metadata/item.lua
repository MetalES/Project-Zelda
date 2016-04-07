local item_meta = sol.main.get_metatable("item")
   
function item_meta:store_equipment(item)
  local game = self:get_game()
  if item ~= "boomerang" then game:set_item_on_use(true) end
 end
   
function item_meta:restore_equipment()
  local game = self:get_game()
  if not game.is_going_to_another_item then
    game:set_item_on_use(false)
  end
end