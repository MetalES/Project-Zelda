local shop = ...
-- Shop System : OOT Style
local game = shop:get_game()
local shop_load_on_creation

local hero_facing_shopkeeper = false
local action_command_shopkeeper = false

-- Hud notification
shop:add_collision_test("facing", function(shop, other)
if other:get_type() == "hero" then 
   hero_facing_shopkeeper = true
   game:set_custom_command_effect("action", "speak")
   action_command_shopkeeper = true
else
   game:set_custom_command_effect("action", nil)
end
end)

function shop:on_created()
local x,y,l = self:get_position()
local ex, ey
self:set_size(16,16)
self:set_traversable_by("hero", false)

if self:get_direction() == 0 then ex, ey = -30,0 
elseif self:get_direction() == 1 then ex, ey = 0, -30 
elseif self:get_direction() == 2 then ex, ey = 30,0 
else ex, ey = 0, 30 end

--create the shopkeeper dynamically, graphic depend on the custom entity's name
local shopkeeper = game:get_map():create_npc({
name = "shopkeeper",
x = x + ex,
y = y + ey,
layer = l,
direction = shop:get_direction(),
sprite = shop:get_name(),
subtype = 1
})

end

-- The shop system
function shop:on_interaction()
if not show_bars then game:show_bars() end
game:start_shop()
end

-- Update area
function shop:on_update()
  if action_command_shopkeeper and not hero_facing_shopkeeper then
    game:set_custom_command_effect("action", nil)
    action_command_shopkeeper = false
  end
   hero_facing_shopkeeper = false
end