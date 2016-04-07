local map = ...
map.shop = {}

local function retrieve_shop_item_position()
  for i, j in ipairs(map.shop) do
    if i <= 9 then
      map.shop[i - 1].x, map.shop[i - 1].y, map.shop[i - 1].z = map.shop[i - 1]:get_position()
    end
  end
end


function map:on_started()
map.shop[0] = map:get_entity("heart_piece")
map.shop[1] = map:get_entity("heart")
map.shop[2] = map:get_entity("arrow")
map.shop[3] = map:get_entity("bomb")
-- 
map.shop[4] = map:get_entity("tunic")
map.shop[5] = map:get_entity("deku_nuts_6")
map.shop[6] = map:get_entity("butterfly_luck")
map.shop[7] = map:get_entity("bomb_bag")

map.shop[8] = map:get_entity("shopkeeper")
map.shop[9] = 0.5 -- shop price multiplier
map.shop[10] = 0 -- shop type

retrieve_shop_item_position()
end
