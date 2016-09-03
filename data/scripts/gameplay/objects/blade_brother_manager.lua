local blade_brother_manager = {
  learning = false, -- State of learning
}

--[[
-- Blade Brother Manager --
Used to make Link to learn skills !

Replace and added methods : 
  - Entitified blade brother
  - NPC Meta
]]

  --[[  Sword Skills ->
    0 = Spin Attack
	1 = Rock Breaker
	2 = Dash Attack
	3 = Perish Beam
	4 = Sword Beam
	5 = Down Thrust
	6 = Spin Attack 2
  ]]

-- Get the skill to learn, if not matched, it will return -1, thus, there is no skills to learn.
function blade_brother_manager:get_lesson()
  local lesson = -1
  local game = self.game
  local name = tostring(self.name)
  local item = game:get_item("blade_skills"):get_variant()

  if item == 0 and name == "0" then lesson = 0 end
  if item > 0 and game:get_value("dungeon_2_finished") and name == "0" then lesson = 1 end
  if item > 0 and game:get_value("dungeon_3_finished") and name == "1" then lesson = 2 end
  if item > 0 and game:get_ability("sword") > 1 and name == "3" then lesson = 3 end
  if item > 0 and game:get_ability("sword") > 3 and game:get_max_life() == 4 * 11 and name == "2" then lesson = 4 end
  if item > 0 and game:has_item("roc_cape") and name == "3" then lesson = 5 end
  if item == 6 and name == "0" then lesson = 6 end
  if item == 7 then lesson = 7 end
  
  return lesson
end

function blade_brother_manager:on_update()
  print("upd")
end

function blade_brother_manager:on_finished()
  self.game = nil
  self.map = nil
  self.hero = nil
end


function blade_brother_manager:start_interact(entity)
  self.game = entity:get_game()
  self.map = entity:get_map()
  self.hero = self.game:get_hero()
  
  local game = self.game
  local lesson = self:get_lesson()
  local sprite = entity:get_sprite()
  local x, y, layer = entity:get_position()

  game:show_cutscene_bars(true)
  game:set_pause_allowed(false)
  sol.audio.play_sound("common/bars_npc_dialog")
  
  print(lesson)
  print(self.name)
  
  if lesson ~= -1 and not self.learning then 
	sol.audio.play_sound("characters/npc/blade_brother/common_tah")
	game:start_dialog("map.location.interior.blade_brother.start_learn_skill_" .. lesson, function(answer)
	  if answer == 1 then	
		game:start_dialog("map.location.interior.blade_brother.start_learn_skill_".. lesson .."_accepted", function()
		
		  -- self:disable_input_depend_skill(s)
		  -- self:go_to_middle_of_carpet()
		  
		  sol.timer.start(1360, function()
			game:start_dialog("map.location.interior.blade_brother.start_learn_skill_".. lesson .."_accepted_on_carpet", function()
			  sprite:set_animation(self.name .. "_backflip_control")
			  self.learning = true
			  sol.timer.start(1200, function()
			    local anim = self.map:create_custom_entity({
				  direction = 0,
				  layer = layer + 1,
				  x = x,
				  y = y,
				})
				anim:create_sprite("npc/location/interior/blade_brother/effect")
				sol.audio.play_sound("characters/npc/blade_brother/control")
				sol.menu.start(self.map, self)
				function anim:on_animation_finished()
				  self:remove()
				  -- entity:skill_preview_demo_managemet(s)
				end
			  end)	
			end)
		  end)
		end)
      else
	    game:start_dialog("map.location.interior.blade_brother.abort", function() 
		  game:show_cutscene_bars(false)
	    end)
	  end
	end)
	-- We are learing. 
  elseif lesson ~= -1 and self.learning then
	sol.audio.play_sound("characters/npc/blade_brother/common_oy")
	game:start_dialog("map.location.interior.blade_brother.skill_".. lesson .."_interraction_instruction")
  else
    game:show_cutscene_bars(true)
	game:start_dialog("map.location.interior.blade_brother.common_after_learned", function() 
	  game:show_cutscene_bars(false)
	end)
  end
end

return blade_brother_manager