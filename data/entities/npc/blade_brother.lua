local entity = ...
local game = entity:get_game()
local is_learning = false
local logic_skill_progress
local has_finished = false
local good_action_executed = false

local hero_facing_npc = false
local action_command_npc = false

--these are loaded when the map is started and when the entity is loaded
local item_var = game:get_item("blade_skills"):get_variant() or 0
if item_var == 0 then logic_skill_progress = 0 end
if item_var > 0 and game:get_value("dungeon_2_finished") then logic_skill_progress = 1 end

-- Hud notification
entity:add_collision_test("touching", function(entity, other)
if other:get_type() == "hero" then 
game:set_custom_command_effect("action", "speak")
action_command_npc = true
hero_facing_npc = true
end
end)

function entity:on_created()
self:set_size(16,16)
self:set_origin(6,16)
self:set_can_traverse("hero", false)
self:set_traversable_by("hero", false)
end

function entity:on_update()
  if action_command_npc and not hero_facing_npc then
    game:set_custom_command_effect("action", nil)
    action_command_npc = false
  end
   hero_facing_npc = false
   
   if is_learning and game:get_hero():get_state() == "sword spin attack" and logic_skill_progress == 0 then good_action_executed = true; end
   
   if is_learning and good_action_executed and not has_finished and not skill_learned then 
   has_finished = true
   is_learning = false
   skill_learned = false
   sol.timer.start(700, function() sol.audio.play_sound("common/secret_discover_minor0"); self:manage_movement_skill_start_type(logic_skill_progress) end)
   sol.timer.start(1400, function()
	sol.audio.play_sound("common/gong") 
	sol.audio.set_music_volume(0)
		game:start_dialog("map.location.interior.blade_brother.start_learn_skill_"..logic_skill_progress.."_done", function()
		  game:get_hero():teleport("interiors/blade_brother/0", "after_learn", "fade")
		    sol.timer.start(1350, function()
			game:start_dialog("map.location.interior.blade_brother.start_learn_skill_"..logic_skill_progress.."_done_2", function()
            game:get_hero():set_direction(2)
				sol.timer.start(100, function()
					game:get_hero():set_direction(3)
					game:get_hero():set_animation("chest_holding_before_brandish")
						sol.timer.start(800, function()
							game:get_hero():start_treasure("blade_skills", logic_skill_progress + 1, savegame_variable, function()
								sol.audio.play_sound("characters/npc/blade_brother/common_lahum")
								game:get_hero():set_direction(1)
								game:set_command_keyboard_binding("item_1", game:get_value("item_1_kb_slot")); game:set_command_joypad_binding("item_1", game:get_value("item_1_jp_slot"))
								game:set_command_keyboard_binding("item_2", game:get_value("item_2_kb_slot")); game:set_command_joypad_binding("item_2", game:get_value("item_2_jp_slot"))
								game:start_dialog("map.location.interior.blade_brother.common_after_learned", function()
									self:manage_movement_skill_end_type(logic_skill_progress)
									game:set_pause_allowed(true)
								    sol.audio.set_music_volume(game:get_value("old_volume"))
									if show_bars == true and not starting_cutscene then game:hide_bars() end
									game:get_hero():unfreeze()
									logic_skill_progress = -1
								end)
							end)
						end)
					end)
				end)
			end)
		end)
	end)
  end  
end


local function initialize_dialog_movement()
local x,y = entity:get_position()
local back_mvt = sol.movement.create("target")
back_mvt:set_target(x, y + 20)
back_mvt:set_speed(70)
back_mvt:start(game:get_hero(), function() game:get_hero():freeze() end)
end

local function go_to_middle_of_carpet()
local x,y = entity:get_position()
game:get_hero():set_animation("walk_opposite")
local back_mvt = sol.movement.create("target")
back_mvt:set_target(x, y + 65)
back_mvt:set_speed(70)
back_mvt:start(game:get_hero(), function() game:get_hero():set_animation("stopped"); game:get_hero():set_direction(2) end)
end

function entity:on_interaction()
game:set_pause_allowed(false) -- disable pause access during the phase

initialize_dialog_movement()
sol.audio.play_sound("common/bars_npc_dialog")

if logic_skill_progress ~= -1 and not is_learning then 

	if not show_bars then game:show_bars() end --show the cutscene bars
	sol.audio.play_sound("characters/npc/blade_brother/common_tah")
	game:start_dialog("map.location.interior.blade_brother.start_learn_skill_"..logic_skill_progress, function(answer)
		if answer == 1 then	
			game:start_dialog("map.location.interior.blade_brother.start_learn_skill_"..logic_skill_progress.."_accepted", function()
				self:manage_movement_skill_start_type(logic_skill_progress)
				go_to_middle_of_carpet()
				game:set_command_keyboard_binding("item_1", nil); game:set_command_joypad_binding("item_1", nil)
				game:set_command_keyboard_binding("item_2", nil); game:set_command_joypad_binding("item_2", nil)
				sol.timer.start(860, function()
					sol.timer.start(10, function() game:get_hero():set_direction(1) end)
					sol.timer.start(500, function()
						game:start_dialog("map.location.interior.blade_brother.start_learn_skill_"..logic_skill_progress.."_accepted_on_carpet", function()
						self:skill_preview_demo_managemet(logic_skill_progress)
						end)
					end)
				end)
			end)
else
	game:start_dialog("map.location.interior.blade_brother.abort", function() 
		if show_bars == true and not starting_cutscene then game:hide_bars() end
	end)
		end
	end) -- start dialog 0

elseif logic_skill_progress ~= -1 and is_learning then
	sol.audio.play_sound("characters/npc/blade_brother/common_oy")
	game:start_dialog("map.location.interior.blade_brother.skill_"..logic_skill_progress.."_interraction_instruction")

else

if not show_bars then game:show_bars() end
	game:start_dialog("map.location.interior.blade_brother.common_after_learned", function() 
		if show_bars == true and not starting_cutscene then game:hide_bars() end
	end)
end
end

function entity:manage_movement_skill_start_type(target_skill)
	if target_skill == 0 then
		local kb_up = game:get_command_keyboard_binding("up") 
		local kb_down = game:get_command_keyboard_binding("down") 
		local kb_left = game:get_command_keyboard_binding("left") 
		local kb_right = game:get_command_keyboard_binding("right") 
		local kb_attack = game:get_command_keyboard_binding("attack") 
		local jp_up = game:get_command_joypad_binding("up") 
		local jp_down = game:get_command_joypad_binding("down") 
		local jp_left = game:get_command_joypad_binding("left") 
		local jp_right = game:get_command_joypad_binding("right") 
		local jp_attack = game:get_command_joypad_binding("attack") 
		game:set_value("kb_up", kb_up)
		game:set_value("kb_down", kb_down)
		game:set_value("kb_left", kb_left)
		game:set_value("kb_right", kb_right)
		game:set_value("kb_attack", kb_attack)
		game:set_value("jp_up", jp_up)
		game:set_value("jp_down", jp_down)
		game:set_value("jp_left", jp_left)
		game:set_value("jp_right", jp_right)
		game:set_value("jp_attack", jp_attack)
		game:set_command_keyboard_binding("up", nil) 
		game:set_command_keyboard_binding("down", nil)  
		game:set_command_keyboard_binding("left", nil)  
		game:set_command_keyboard_binding("right", nil)  
		game:set_command_keyboard_binding("item_1", nil)
		game:set_command_keyboard_binding("item_2", nil)
		game:set_command_keyboard_binding("attack", nil)
		game:set_command_joypad_binding("up", nil)  
		game:set_command_joypad_binding("down", nil)  
		game:set_command_joypad_binding("left", nil)  
		game:set_command_joypad_binding("right", nil) 
		game:set_command_joypad_binding("item_1", nil)
		game:set_command_joypad_binding("item_2", nil)
		game:set_command_joypad_binding("attack", nil)
		game:simulate_command_released("attack")
		game:simulate_command_released("action")
		game:simulate_command_released("item_1")
		game:simulate_command_released("item_2")
		game:simulate_command_released("up")
		game:simulate_command_released("down")
		game:simulate_command_released("left")
		game:simulate_command_released("right")
	end
end

function entity:manage_movement_skill_end_type(target_skill)
	if target_skill == 0 then
		game:set_command_keyboard_binding("up", game:get_value("kb_up")) 
		game:set_command_keyboard_binding("down", game:get_value("kb_down"))  
		game:set_command_keyboard_binding("left", game:get_value("kb_left"))
		game:set_command_keyboard_binding("right", game:get_value("kb_right")) 
		game:set_command_keyboard_binding("action", game:get_value("item_saved_kb_action"))
		game:set_command_keyboard_binding("attack", game:get_value("kb_attack"))
		game:set_command_joypad_binding("up", game:get_value("jp_up")) 
		game:set_command_joypad_binding("down", game:get_value("jp_down"))  
		game:set_command_joypad_binding("left", game:get_value("jp_left"))   
		game:set_command_joypad_binding("right", game:get_value("jp_right")) 
		game:set_command_joypad_binding("action", game:get_value("item_saved_jp_action"))
		game:set_command_joypad_binding("attack", game:get_value("jp_attack"))
	end
end

function entity:skill_preview_demo_managemet(target_skill)
	if target_skill == 0 then
		sol.timer.start(200, function()
			game:set_value("skill_1_learned", true)
			game:simulate_command_pressed("attack")
			sol.timer.start(1800, function()
				game:simulate_command_released("attack")
				sol.timer.start(1500, function()
					game:start_dialog("map.location.interior.blade_brother.start_learn_skill_control", function() is_learning = true; self:manage_movement_skill_end_type(logic_skill_progress); end)
				end)
			end)
		end)
	end
end