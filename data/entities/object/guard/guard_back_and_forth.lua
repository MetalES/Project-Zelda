local entity = ...
local ai_model = "object/guard/ai_system"
local ai_loader = entity:get_name():match("^avoid_guard_([0-9])$") or "avoid_guard" 
local ai_system
-- Guard with AI

function entity:on_created()
  self:set_size(16,16)
  self:set_traversable_by("hero", false)
  self:set_traversable_by("custom_entity", false)
  self:set_can_traverse("hero", false)
  self:set_can_traverse("custom_entity", false)
  self:set_drawn_in_y_order(true)
  
  -- if the name of this entity is avoid_guard + suffix, start the detection system.
  
  if ai_loader then
    local x, y, z = self:get_position()
	local direction = self:get_direction()
    ai_system = self:get_game():get_map():create_custom_entity({
	model = ai_model,
	x = x,
	y = y,
	layer = z,
	direction = direction,
	})
	ai_system:set_direction(self:get_direction())
  end
end

-- if the guard is a normal guard, then you can interact with, the dialog depend on it's name

function entity:on_interaction()
  self:get_game():start_dialog("map.location.castle.guard"..self:get_name())
end

function entity:on_position_changed()
print("hehe")
 if ai_loader then
    local x, y, z = self:get_position()
    ai_system:set_position(x, y, z)
 end
end