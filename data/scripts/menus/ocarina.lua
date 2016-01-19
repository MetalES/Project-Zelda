local game = ...
ocarina = {}
local initial_point
local initial_y = 10
local initial_volume 
local index
local hero_was_visible
local hero_spr
local hero_x, hero_y
local matched = {}

local state = 0
local note0, note1, note2, note3, note4, note5, note6, note7 = nil  -- notes played, non-played = nil
local note = {}
local variant = nil 


function game:on_ocarina_started()
  if not sol.menu.is_started(ocarina) then sol.menu.start(game, ocarina) end
end

function ocarina:on_started()
local hero = game:get_hero()
local hero_x, hero_y = hero:get_position()
  hero_was_visible = hero:is_visible()
  hero:set_visible(false)
  
  hero_spr = sol.sprite.create("hero/tunic"..tunic)
  hero_spr:set_animation("playing")
  hero_spr:set_direction(hero:get_direction())
  hero_spr:set_paused(false)

  sol.timer.start(ocarina, 60, function()
    sol.audio.play_sound("stairs_indicator")
    state = 1
-- declare song here
      sol.timer.start(10, function()
       if not learning then 
	     if note0 == 2 and note1 == 1 and note2 == 0 and note3 == 2 and note4 == 1 and note5 == 0 and game:has_item("ocarina_zelda_learned") then self:reset_note(); self:play_song() end -- zelda lullaby
	     if note0 == 4 and note1 == 3 and note2 == 0 and note3 == 1 and note4 == 0 and note5 == 2 then item:reset_note() print("5") end -- soaring
	     if note0 == 1 and note1 == 2 and note2 == 0 and note3 == 1 and note4 == 2 and note5 == 0 then item:reset_note() print("dd") end
	     if note0 == 0 and note1 == 3 and note2 == 1 and note3 == 0 and note4 == 3 and note5 == 1 then item:reset_note() print("sun") end
	
	   end
	  return true
      end)
  end)
end

function ocarina:on_command_pressed(command)
handled = true
		if state == 1 then
			if command == "up" then
			    if note0 == nil then note0 = 1 
				elseif note1 == nil then note1 = 1
				elseif note2 == nil then note2 = 1
				elseif note3 == nil then note3 = 1
				elseif note4 == nil then note4 = 1 
				elseif note5 == nil then note5 = 1
				elseif note6 == nil then note6 = 1
				elseif note7 == nil then note7 = 1
				elseif note7 ~= nil then ocarina:reset_note()
				end
				sol.audio.play_sound(sound_dir..command)
			elseif command == "down" then
			    if note0 == nil then note0 = 3 
				elseif note1 == nil then note1 = 3
				elseif note2 == nil then note2 = 3
				elseif note3 == nil then note3 = 3
				elseif note4 == nil then note4 = 3 
				elseif note5 == nil then note5 = 3
				elseif note6 == nil then note6 = 3
				elseif note7 == nil then note7 = 3
				elseif note7 ~= nil then ocarina:reset_note()
				end
				sol.audio.play_sound(sound_dir..command)
			elseif command == "left" then
			    if note0 == nil then note0 = 2 
				elseif note1 == nil then note1 = 2
				elseif note2 == nil then note2 = 2
				elseif note3 == nil then note3 = 2
				elseif note4 == nil then note4 = 2 
				elseif note5 == nil then note5 = 2
				elseif note6 == nil then note6 = 2
				elseif note7 == nil then note7 = 2
				elseif note7 ~= nil then ocarina:reset_note()
				end
				sol.audio.play_sound(sound_dir..command)
			elseif command == "right" then
			    if note0 == nil then note0 = 0 
				elseif note1 == nil then note1 = 0
				elseif note2 == nil then note2 = 0
				elseif note3 == nil then note3 = 0
				elseif note4 == nil then note4 = 0 
				elseif note5 == nil then note5 = 0
				elseif note6 == nil then note6 = 0
				elseif note7 == nil then note7 = 0
				elseif note7 ~= nil then ocarina:reset_note()
				end
				sol.audio.play_sound(sound_dir..command)
			elseif command == "action" then
			    if note0 == nil then note0 = 4 
				elseif note1 == nil then note1 = 4
				elseif note2 == nil then note2 = 4
				elseif note3 == nil then note3 = 4
				elseif note4 == nil then note4 = 4 
				elseif note5 == nil then note5 = 4
				elseif note6 == nil then note6 = 4
				elseif note7 == nil then note7 = 4
				elseif note7 ~= nil then ocarina:reset_note()
				end
				sol.audio.play_sound(sound_dir..command)
			elseif command == "attack" then
				game:get_item("ocarina"):transit_to_finish()
				sol.menu.stop(ocarina)
			end
		end
  return true
end

function ocarina:on_draw(dst_surface)
if state ~= 0 then
    hero_spr:draw(dst_surface, hero_x, hero_y)
end
end

function ocarina:reset_note()
note0, note1, note2, note3, note4, note5, note6, note7 = nil 
end

function ocarina:on_finished()
  local hero = game:get_hero()
  if hero ~= nil then
    hero:set_visible(hero_was_visible)
  end
  music = nil
  hero_dead_spr = nil
  sol.timer.stop_all(self)
  game:get_map():get_hero():unfreeze()
end