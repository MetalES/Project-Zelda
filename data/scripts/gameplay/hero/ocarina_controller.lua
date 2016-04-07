local ocarina_manager = {}

local input_array = {[0]="right",[1]="up",[2]="left",[3]="down", [4]="action"}
local played_note = {}
-- Used for learning
local note_to_memorize = {}
local time_between_note = {}
local y_position = {[0]=185 ,[1]=173,[2]=181,[3]=189, [4]=197}
local color = {[0]=0 ,[1]=0,[2]=0}

local button = {[0] = sol.surface.create("hud/ocarina/input.png"), [1] = sol.surface.create("hud/ocarina/input.png"), 
[2] = sol.surface.create("hud/ocarina/input.png"), [3] = sol.surface.create("hud/ocarina/input.png"), 
[4] = sol.surface.create("hud/ocarina/input.png"), [5] = sol.surface.create("hud/ocarina/input.png"), 
[6] = sol.surface.create("hud/ocarina/input.png"), [7] = sol.surface.create("hud/ocarina/input.png")}

local time_played =  0
local delay_new = 800
local sfont_delay = 0
local song_delay
local song_name_type
local learning_song_delay
local text_x = 154

--todo : Text_x
         --dialog refresh

-- Misc
local song_played
local success = 0
local sustain -- used to maintain a note if the player still press it. Similar to OOT when you press an ocarina note, it will be played unless you release it's input

local good = "common/secret_discover_minor0"
local song_error =  "items/ocarina/error"

local delay = 0
local song_time = 0
local note = 0
local learning_greyscale_note_correct = 0

function ocarina_manager:stop_ocarina()
  sol.menu.stop(self)
  self.game:set_item_on_use(false)
end

function ocarina_manager:start(game)
  self.game = game
  sol.menu.start(game, self, true)
end

-- The Ocarina
function ocarina_manager:on_started()
  local horizontal_alignment = "left"
  local vertical_alignment = "middle"
  self.game:get_hero():get_sprite():set_ignore_suspend(true)
  self.game:set_suspended(true)

  self:clear_note_played_if_error()
  self.ocarina_soundfont = self.ocarina_soundfont or "ocarina"
  
  self.ocarina_box = sol.surface.create("hud/ocarina/bar.png")
  self.width = self.ocarina_box:get_size()
  self.greyscale_button_input = sol.sprite.create("hud/ocarina/note")
  
  self.error_img = sol.surface.create("hud/ocarina/error.png")
  
  self.can_play = true
  
  self.ocarina_se1 = sol.text_surface.create{
    horizontal_alignment = "right",
	vertical_alignment = vertical_alignment,
	font = "lttp",
	font_size = "14"
  }	
  
  self.ocarina_se2 = sol.text_surface.create{
    horizontal_alignment = "left",
	vertical_alignment = vertical_alignment,
	font = "lttp",
	font_size = "14"
  }	
   
  if self.learning_new_song then
    self:retrieve_song_to_learn(self.indexed_song_to_learn)
	sol.audio.set_music_volume(0)
	self.playing_ocarina = true
  end
end

function ocarina_manager:is_learned(id)
  return self.game:is_ocarina_song_learned(id)
end

-- If a song has been played, no mater what position in the array, play the song
function ocarina_manager:check_session()
  local p = played_note
  for t, n  in ipairs(played_note) do
    if p[t] == 2 and p[t + 1] == 1 and p[t + 2] == 0 and p[t + 3] == 2 and p[t + 4] == 1 and p[t + 5] == 0 and self:is_learned(1) then
	  song_played = 0
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 0 and p[t + 3] == 1 and p[t + 4] == 0 and p[t + 5] == 2 and self:is_learned(2) then
	  song_played = 1
	elseif p[t] == 1 and p[t + 1] == 2 and p[t + 2] == 0 and p[t + 3] == 1 and p[t + 4] == 2 and p[t + 5] == 0 and self:is_learned(3) then
	  song_played = 2
	elseif p[t] == 0 and p[t + 1] == 3 and p[t + 2] == 1 and p[t + 3] == 0 and p[t + 4] == 3 and p[t + 5] == 1 and self:is_learned(4) then
	  song_played = 3
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 1 and p[t + 3] == 4 and p[t + 4] == 3 and p[t + 5] == 1 and self:is_learned(5) then
	  song_played = 4
	elseif p[t] == 2 and p[t + 1] == 0 and p[t + 2] == 3 and p[t + 3] == 2 and p[t + 4] == 0 and p[t + 5] == 3 and self:is_learned(6) then
	  song_played = 5
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 1 and p[t + 3] == 2 and p[t + 4] == 1 and p[t + 5] == 2 and self:is_learned(7) then
	  song_played = 6
	elseif p[t] == 0 and p[t + 1] == 4 and p[t + 2] == 3 and p[t + 3] == 0 and p[t + 4] == 4 and p[t + 5] == 3 and self:is_learned(8) then
	  song_played = 7
	elseif p[t] == 4 and p[t + 1] == 1 and p[t + 2] == 2 and p[t + 3] == 0 and p[t + 4] == 2 and p[t + 5] == 0 and self:is_learned(9) then
	  song_played = 8
	elseif p[t] == 3 and p[t + 1] == 4 and p[t + 2] == 3 and p[t + 3] == 4 and p[t + 4] == 0 and p[t + 5] == 3 and p[t + 6] == 0 and p[t + 7] == 3 and self:is_learned(10) then
	  song_played = 9
	elseif p[t] == 4 and p[t + 1] == 0 and p[t + 2] == 4 and p[t + 3] == 3 and p[t + 4] == 4 and p[t + 5] == 0 and p[t + 6] == 1 and p[t + 7] == 3 and self:is_learned(11) then
	  song_played = 10
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 0 and p[t + 3] == 0 and p[t + 4] == 2 and self:is_learned(12) then
	  song_played = 11
	  dest_map = "LostWoods/out/LostPath"
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 4 and p[t + 3] == 0 and p[t + 4] == 3 and p[t + 5] == 4 and self:is_learned(13) then
	  song_played = 12
	elseif p[t] == 2 and p[t + 1] == 0 and p[t + 2] == 0 and p[t + 3] == 4 and p[t + 4] == 2 and p[t + 5] == 0 and p[t + 6] == 3 and self:is_learned(14) then
	  song_played = 13
	elseif p[t] == 4 and p[t + 1] == 3 and p[t + 2] == 0 and p[t + 3] == 4 and p[t + 4] == 3 and p[t + 5] == 0 and p[t + 6] == 1 and p[t + 7] == 0 and self:is_learned(15) then
	  song_played = 14
	  dest_map = "LostWoods/out/LostPath"
	elseif p[t] == 1 and p[t + 1] == 0 and p[t + 2] == 1 and p[t + 3] == 0 and p[t + 4] == 2 and p[t + 5] == 1 and self:is_learned(16) then
	  song_played = 15
	end
  end
  if song_played ~= nil then
   self.playing_ocarina = true
    sol.timer.start(self, 1, function()
	  if sustain ~= nil then sustain:stop() end
	  self:retrieve_song_to_learn(song_played)
	  sol.audio.play_sound(good)
	  self:play_song(song_played)
	  self.song_played = true
	  sol.timer.start(self, 550, function()
	    sol.audio.set_music_volume(0)
	    sol.audio.play_sound("items/ocarina/song/"..song_played)
	  end)
	end)
  end	
end

function ocarina_manager:check_learning_session()
  for t, n  in ipairs(played_note) do
      if played_note[t] ~= note_to_memorize[t - 1] then
	   success = -1
	   learning_greyscale_note_correct = 0
	   self:song_is_error()
	end
  end
  success = success + 1
  if success - 1 == table.getn(note_to_memorize) then
    sol.audio.play_sound(good)
    self.song_played = true
    sol.timer.start(self, 2250, function()
      if sustain ~= nil then sustain:stop() end
	  sol.audio.set_music_volume(0)
	  sol.audio.play_sound("items/ocarina/song/"..self.indexed_song_to_learn)
	  self:play_song(self.indexed_song_to_learn)
    end)
  end
end

function ocarina_manager:song_is_error()
    self:clear_note_played_if_error()
	played_note = {}
	sol.audio.play_sound(song_error)
	self.disable_input = true
	sol.timer.start(self, 1000, function()
	  if sustain ~= nil then sustain:stop() end
	  self.error = true
	  self.avoid_restart = true
  end)
end

function ocarina_manager:play_song(index)
-- this part is used to play song, no matter if learning or not
  text_x = 154
  self.ocarina_se1:set_text("")
  if not self.playing_ocarina then self.playing_ocarina = true end
-- used for learning
  if song_played ~= nil then 
	self.playing_ocarina = true
  else
    self:clear_note_played_if_error()  
	self.can_control = false
  end  
  
  if self.learning_new_song then
    self:start_learn_song(self.indexed_song_to_learn)
  end
  
  sol.timer.start(self, song_delay, function()
    self.ocarina_se1:set_text_key("ocarina.you_played."..song_name_type)
	self.ocarina_se2:set_text_key("quest_status.caption.ocarina_song_"..(song_played or self.indexed_song_to_learn)  + 1)
	self.ocarina_se2:set_color({color[0], color[1], color[2]})
	self.can_draw_text = true
	sol.timer.start(self, 2000, function()
	  if self.learning_new_song then
	    self:learned_song(self.indexed_song_to_learn)
	  else
	    self:clear_all()
	    self:start_song_effect(song_played)
	  end
	end)
  end)
delay, time_between_note[0] = 1, 1
end

function ocarina_manager:clear_all()
  self:clear_note_played_if_error()
  self.playing_ocarina = false; self.can_draw_text = false; self.can_control = false 
  
  for i = 0, #note_to_memorize do
    button[i]:set_opacity(0)
  end
end

function ocarina_manager:learned_song(index)
local game = self.game
sol.audio.play_music(nil)
self:clear_all()
  sol.timer.start(self, learning_song_delay - (song_delay * 1.50), function()
	game:set_ocarina_song_learned(index, true)
    for teacher in self.game:get_map():get_entities("ocarina_teacher") do
	  teacher:on_song_learned(index)
	end
  end)
end

function ocarina_manager:retrieve_song_to_learn(index)
  local n = note_to_memorize
  local t = time_between_note
  local c = color
    if index == 0 then
      n[0], n[1], n[2], n[3], n[4], n[5] = 2,1,0,2,1,0
	  t[0], t[1], t[2], t[3],t[4], t[5] = 650, 820, 540, 1500, 820, 540
	  song_delay = 5980; song_name_type = 1; c[0] = 255; c[1] = 0; c[2] = 255; learning_song_delay = 9620
	elseif index == 1 then -- Soaring
	  n[0], n[1], n[2], n[3], n[4], n[5] = 4,3,0,1,0,2
	  t[0], t[1], t[2], t[3],t[4], t[5] = 120, 120, 120, 120, 140, 120
	  song_delay = 2500; song_name_type = 0; c[0] = 255; c[1] = 255; c[2] = 255; learning_song_delay = 3750
	elseif index == 2 then -- Epona
	  n[0], n[1], n[2], n[3], n[4], n[5] = 1,2,0,1,2,0
	  t[0], t[1], t[2], t[3],t[4], t[5] = 300, 300, 300, 1500, 300, 300
	  song_delay = 4540; song_name_type = 0; c[0] = 255; c[1] = 255; c[2] = 255; learning_song_delay = 7050
	elseif index == 3 then -- Sun Song
	  n[0], n[1], n[2], n[3], n[4], n[5] = 0,3,1,0,3,1
	  t[0], t[1], t[2], t[3],t[4], t[5] = 200, 200, 200, 800, 200, 200
	  song_delay = 3500; song_name_type = 0; c[0] = 255; c[1] = 255; c[2] = 0; learning_song_delay = 4850
	elseif index == 4 then -- Storm
	  n[0], n[1], n[2], n[3], n[4], n[5] = 4,3,1,4,3,1
	  t[0], t[1], t[2], t[3],t[4], t[5] = 200, 200, 200, 800, 200, 200
	  song_delay = 3500; song_name_type = 0; c[0] = 0; c[1] = 0; c[2] = 255; learning_song_delay = 4800
	elseif index == 5 then -- Apaisement
	 n[0], n[1], n[2], n[3], n[4], n[5] = 2,0,3,2,0,3
	 t[0], t[1], t[2], t[3],t[4], t[5] = 600, 600, 600, 700, 600, 600
	 song_delay = 4250; song_name_type = 0; c[0] = 255; c[1] = 0; c[2] = 255; learning_song_delay = 6850
	elseif index == 6 then -- Ode of Byrna
	 n[0], n[1], n[2], n[3], n[4], n[5] = 4,3,1,2,1,2
	 t[0], t[1], t[2], t[3],t[4], t[5] = 400, 400, 400, 600, 300, 300
	 song_delay = 3500; song_name_type = 2; c[0] = 255; c[1] = 255; c[2] = 255; learning_song_delay = 6000
	elseif index == 7 then -- Song on Time
	 n[0], n[1], n[2], n[3], n[4], n[5] = 0,4,3,0,4,3
	 t[0], t[1], t[2], t[3],t[4], t[5] = 400, 600, 1200, 600, 600, 1200 
	 song_delay = 5000; song_name_type = 0; c[0] = 0; c[1] = 0; c[2] = 255; learning_song_delay = 10500
	elseif index == 8 then -- Wood
  	 n[0], n[1], n[2], n[3], n[4], n[5] = 4,1,2,0,2,0
	 t[0], t[1], t[2], t[3],t[4], t[5] = 300, 300, 300, 1600, 300, 300 
	 song_delay = 5000; song_name_type = 0; c[0] = 0; c[1] = 255; c[2] = 0; learning_song_delay = 15700
	elseif index == 9 then -- Fire
	 n[0], n[1], n[2], n[3], n[4], n[5], n[6], n[7] = 3,4,3,4,0,3,0,3
	 t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7] = 250, 250, 250, 250, 250, 250, 250, 250
	 song_delay = 5000; song_name_type = 0; c[0] = 255; c[1] = 0; c[2] = 0; learning_song_delay = 18500
	elseif index == 10 then -- Earth
	 n[0], n[1], n[2], n[3], n[4], n[5], n[6], n[7] = 4,0,4,3,4,0,1,3
	 t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7] = 1000, 1000, 600, 1000, 600, 600, 600, 600
     song_delay = 7000; song_name_type = 0; c[0] = 139; c[1] = 69; c[2] = 19; learning_song_delay = 24700
	elseif index == 11 then -- Water
	 n[0], n[1], n[2], n[3], n[4] = 4,3,0,0,2
	 t[0], t[1], t[2], t[3], t[4] = 600, 600, 600, 600, 600
	  song_delay = 4500; song_name_type = 1; c[0] = 0; c[1] = 0; c[2] = 255; learning_song_delay = 17450
	elseif index == 12 then -- Spirit
	 n[0], n[1], n[2], n[3], n[4], n[5] = 4,3,4,0,3,4
	 t[0], t[1], t[2], t[3], t[4], t[5] = 800, 800, 400, 350, 775, 800
	 song_delay = 6000; song_name_type = 0; c[0] = 255; c[1] = 165; c[2] = 0; learning_song_delay = 22000
	elseif index == 13 then -- Shadow
	 n[0], n[1], n[2], n[3], n[4], n[5], n[6] = 2,0,0,4,2,0,3
	 t[0], t[1], t[2], t[3], t[4], t[5], t[6] = 500, 600, 600, 300, 300, 300, 300
     song_delay = 6500; song_name_type = 0; c[0] = 255; c[1] = 0; c[2] = 255; learning_song_delay = 20200
	elseif index == 14 then -- Air
	 n[0], n[1], n[2], n[3], n[4], n[5], n[6], n[7] = 4,3,0,4,3,0,1,0
	 t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7] = 200, 200, 200, 1000, 200, 200, 200, 1000
	 song_delay = 5000; song_name_type = 1; c[0] = 0; c[1] = 255; c[2] = 255; learning_song_delay = 21000
	elseif index == 15 then -- Light
	 n[0], n[1], n[2], n[3], n[4], n[5] = 1,0,1,0,2,1
	 t[0], t[1], t[2], t[3],t[4], t[5] = 225, 225, 800, 225, 250, 225 
	 song_delay = 5000; song_name_type = 0; c[0] = 255; c[1] = 255; c[2] = 0; learning_song_delay = 16400
	end 
self:start_learn_song()
end

function ocarina_manager:start_learn_song(index)
  note = 0
  if not self.song_played and self.learning_new_song then
    if self.indexed_song_to_learn >= 0 and self.indexed_song_to_learn <= 7 then
	  self.ocarina_se1:set_text_key("ocarina.learn.memorize_this."..self.indexed_song_to_learn) 
	  self.can_draw_text = true
	  text_x = 220
	else
	  self.ocarina_se1:set_text_key("ocarina.learn.memorize_this.type."..song_name_type)
	  self.ocarina_se2:set_text_key("quest_status.caption.ocarina_song_"..self.indexed_song_to_learn + 1)
	  self.can_draw_text = true
	end
  end
  
  for i = 0, #note_to_memorize do
    button[i]:set_opacity(0)
  end
  
  sol.timer.start(self, delay_new, function()
    self:play_song_auto()
  end)
end

function ocarina_manager:play_song_auto()
  note = note + 1

  sol.timer.start(self, time_between_note[note - 1], function()
	button[note - 1]:fade_in(15)
	if not self.song_played then self:simulate_ocarina(note_to_memorize[note - 1]) end
	if note_to_memorize[note] == nil then 
	  if not self.song_played then
	    self:repeat_if_not_done()
	  end
	else
	  self:play_song_auto()
	end
  end)
end

function ocarina_manager:repeat_if_not_done()
  if time_played ~= 1 then
	sol.timer.start(self, 2500, function()
	  self:clear_note_played_if_error()
	  self:start_learn_song(self.indexed_song_to_learn)
	  time_played = 1
	  delay_new = 1
	  note = 0
	  time_between_note[0] = 0
	end)
  elseif time_played == 1 then
	sol.timer.start(self, 2500, function()
	  if sustain ~= nil then sustain:stop() end
	  self.can_control = true
	  self.ocarina_se1:set_text_key("ocarina.learn.play_with.0")
	  self.ocarina_se2:set_text("")
	  text_x = 274
		--Restore the default soundfont to ocarina because we are controlling the hero
	  self.ocarina_soundfont = "ocarina"
		self:clear_note_played_if_error()
	end)
  end
end

function ocarina_manager:start_song_effect(index)
  local g = self.game
  local m = g:get_map()
  local h = m:get_hero()
  
  if index == 0 then -- Zelda's Lullaby
  	if not m:has_entity("ocarina_zelda") then
		self:return_no_effect()
	else
      for entities in m:get_entities("ocarina_zelda") do
	    if entities.on_zelda_lullaby_interaction ~= nil then entities:on_zelda_lullaby_interaction() end
	  end
	end
  elseif index == 1 then -- Song of Soaring
    g:start_soaring_menu()
  elseif index == 2 then -- Epona's song
    if g:get_value("got_epona") then -- If we have the horse
	  local hero_x, hero_y, hero_layer = h:get_position()
	  local direction = h:get_direction() % 2
	  local spawn_point_x, spawn_point_y
	  local type_of = "wall" or "deep_water"
	  
	  	if m:get_ground(hero_x + 32, hero_y, hero_layer) == type_of then
		   spawn_point_x, spawn_point_y = -380, math.random(0,240)		
		elseif m:get_ground(hero_x - 32, hero_y, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = 380, math.random(0,240)
		elseif m:get_ground(hero_x, hero_y - 32, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = math.random(0,320), 300
		elseif m:get_ground(hero_x, hero_y - 32, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = math.random(0,320), -300
		end
	  if not m:has_entity("epona") and not g.no_horse_possible then -- if we are in a valid place
	    local epona = game:get_map():create_custom_entity({
		model = "object/horse/epona",
		x = hero_x + spawn_point_x,
		y = hero_y + spawn_point_y,
		layer = hero_layer,
		direction = direction
		})
	  self:stop_ocarina()
	  else
	    m:get_entity("epona"):set_position(hero_x + spawn_point_x, hero_y, spawn_point_y)
		local target = sol.movement.create("target")
		target:set_target(hero_x, hero_y)
	    target:start(m:get_entity("epona"))
	  end
	else
     self:return_no_effect()
	end
  elseif index == 3 then -- Sun's Song
    if m:get_world() ~= "field" then
	  self:return_no_effect()
	else
	  if not g.has_played_sun_song then
	    g:set_time_flow(20)
	    g.has_played_sun_song = true
	  end
	  self:stop_ocarina()
	end
  elseif index == 4 then -- Song of Storm
    if m:get_world() ~= "outside" then
      self:return_no_effect()
	else
	  -- game:start_storm(song_of_storm)
	end
  elseif index == 5 then -- healing
	if m:has_entity("ocarina_healing") then
		for heal in m:get_entities("ocarina_healing") do
	      local distance = h:get_distance(heal)
	      if distance <= 32 then
	        heal:on_song_of_heal_interaction()
	      else
	        self:return_no_effect()
	      end
	    end
	else
	  self:return_no_effect()
	end
  
  elseif index == 6 then -- Byrna, TODO
	if m:has_entity("ocarina_byrna") then
		for heal in m:get_entities("ocarina_byrna") do
	      local distance = h:get_distance(heal)
	      if distance <= 32 then
	        heal:on_song_of_heal_interaction()
	      else
	        self:return_no_effect()
	      end
	    end
	else
	  self:return_no_effect()
	end
	  
  elseif index == 7 then -- Song of Time
    if m:has_entity("block_of_time") then
		for block in m:get_entities("ocarina_song_of_time") do
	      local distance = h:get_distance(block)
	      if distance <= 32 then
	        block:on_song_of_time_interaction()
	      else
	        self:return_no_effect()
	      end
	    end
	else
	  self:return_no_effect()
	end
  elseif index >= 8 and index <= 15 then
     g:start_dialog("_ocarina."..index..".played", function(answer)
	    if answer == 1 then
		  self:warp_from_ocarina("out")
		  --start the animation and warp
		else
		  self:stop_ocarina()
		end
	 end)
  end
end

function ocarina_manager:return_no_effect()
  self.game:start_dialog("_ocarina.played_but_no_effect.0", function()
    note_to_memorize = {}
	self:stop_ocarina()
  end)
end

function ocarina_manager:create_warp_sprite_entity(time_to_create_trail, tr)
  local game = sol.main.game
  local hero = game:get_hero()
  local map = game:get_map()

  hero:set_invincible(true, 2000)
  local x, y, layer = hero:get_position()
  if tr == "in" then
    x, y, layer = x - 360, y - 240, layer
  else
    game:set_suspended(false)
  end
  self.warp_sprite = map:create_custom_entity({
	x = x,
	y = y,
	layer = layer + 1,
	direction = 0,
	sprite = "effects/hero/warp_effect"
  })
  self.warp_sprite:get_sprite():set_animation(song_played - 8)
	
  sol.timer.start(time_to_create_trail, function()
    sol.timer.start(50, function()
	  local ax, ay, al = self.warp_sprite:get_position()
	  local warp_trail = map:create_custom_entity({
	    x = ax,
	    y = ay,
	    layer = al,
	    direction = 0,
	    sprite = "effects/hero/warp_effect"
	  })
		
	  local warp_trail_2 = map:create_custom_entity({
	    x = ax + math.random(0, 8),
	    y = ay + math.random(-2, 2),
	    layer = al,
	    direction = 0,
		sprite = "effects/hero/warp_effect"
	  })
		
	  local warp_trail_3 = map:create_custom_entity({
        x = ax - math.random(0, 8),
        y = ay + math.random(-2, 2),
        layer = al,
        direction = 0,
	    sprite = "effects/hero/warp_effect"
      })
		
	  warp_trail:get_sprite():set_animation(song_played - 8)
	  warp_trail_2:get_sprite():set_animation(song_played - 8)
	  warp_trail_3:get_sprite():set_animation(song_played - 8)
	  warp_trail_2:get_sprite():set_frame(math.random(0, 2))
	  warp_trail_3:get_sprite():set_frame(math.random(0, 2))
	  
	  sol.timer.start(300, function()
	    warp_trail:remove()
	    warp_trail_2:remove()
	    warp_trail_3:remove()
	  end)
		
	if self.warp_movement_done then 
	  self.warp_sprite:remove()
	end
	
	return (self.warp_movement_done ~= true)
	end)
  end)
end

function ocarina_manager:warp_from_ocarina(tr)
  local game = sol.main.game
  local map = game:get_map()
  local hero = game:get_hero()
  self.surface = sol.surface.create(320, 240)
  self.surface:fill_color({255, 255, 255})
  
  local map_x, map_y = map:get_size()
	
  local x, y, layer	
	
  sol.audio.play_sound("characters/link/effect/warp_"..tr)
	
  if tr == "out" then
    sol.audio.play_music(nil)
    x, y, layer = hero:get_position()
    self:create_warp_sprite_entity(1250, tr)
    sol.timer.start(1250, function()
	  self.draw_flash = true
	  self.surface:fade_in(1, function()
	    self.surface:fade_out(5, function()
		  sol.timer.start(3000, function()
		    self.surface:fade_in(40, function()
			  sol.timer.start(1000, function()
			    hero:teleport_to(dest_map, "from_ocarina")
			  end)
			end)
		  end)
		end)
	  end)
      hero:set_visible(false)
      local s = sol.movement.create("straight")
      s:set_angle(math.pi / 2)
      s:set_speed(60)
      s:set_max_distance(16)
      s:start(self.warp_sprite, function()
        local c = sol.movement.create("circle")
   	    c:set_initial_angle(math.pi / 2)
		c:set_center(hero, 0, -8)
		c:set_clockwise(false)
		c:set_max_rotations(2)
		c:set_radius(16)
		c:set_radius_speed(32)
		c:set_duration(600)
	    c:start(self.warp_sprite, function()
		  local t = sol.movement.create("target")
		  t:set_target(map_x, map_y - map_y)
		  t:set_ignore_obstacles(true)
		  t:set_speed(250)
		  t:start(self.warp_sprite, function()
		    self.warp_movement_done = true
		    sol.timer.start(100, function()
			  self.warp_movement_done = false
			  self.warp_sprite:remove()
			end)			
		  end)
		end)
	  end)
	end)
  else
    x, y, layer = hero:get_position()
	self:create_warp_sprite_entity(1, tr)
	hero:freeze()
	sol.audio.set_music_volume(self.game:get_value("old_volume"))
	self.surface:fade_out(40, function()
	  sol.timer.start(2000, function()
	    self.surface:fade_in(4, function()
		  hero:set_visible(true)
		  self.surface:fade_out(7, function()
		    self.draw_flash = false
			self.surface:clear()
			sol.timer.start(2000, function()
			  self.from_movement = true
			  self:stop_ocarina()
			end)
		  end)
		end)
	  end)
	end)
	local t = sol.movement.create("target")
	t:set_target(x, y - 8)
	t:set_speed(250)
	t:set_ignore_obstacles(true)
	t:start(self.warp_sprite, function()
	  local c = sol.movement.create("circle")
	  c:set_initial_angle(math.pi / 2)
	  c:set_center(hero, 0, -8)
	  c:set_clockwise(true)
	  c:set_max_rotations(2)
	  c:set_radius(16)
	  c:set_radius_speed(32)
	  c:set_duration(1200)
	  c:start(self.warp_sprite, function()
	    self.warp_sprite:remove()
		self.warp_movement_done = true
		sol.timer.start(70, function()
		  self.warp_movement_done = false			
	    end)
	  end)
    end)
  end
end

function ocarina_manager:on_command_pressed(command)
  local game = self.game
  if self.can_play then
    if not self.learning_new_song and song_played == nil then
	  for k, input in pairs(input_array) do
		if command == input then
		  if sustain ~= nil then sustain:stop() end
		  sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..input)
		  sustain = sol.timer.start(183, function()
		    if game:is_command_pressed(input) and not game:is_command_pressed("attack") then
			  sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..input)
			  return true
			else
			 return false
			end
		  end)
		  played_note[#played_note + 1] = k
		  self:check_session()
		elseif command == "attack" then
		  if sustain ~= nil then sustain:stop() end
		    self:stop_ocarina()
		end
	  end
      elseif self.can_control and self.learning_new_song and self.disable_input and self.avoid_restart and not self.song_played then
	    if command == "action" then
		  self.disable_input = false
		  self.avoid_restart = false
		  sol.audio.play_sound("common/dialog/ocarina_restart")
		end
	  elseif self.can_control and self.learning_new_song and not self.disable_input and not self.song_played then
	-- Learning a song, you can't cancel the phase
		for k, input in pairs(input_array) do
		  if command == input then
			if sustain ~= nil then sustain:stop() end
			sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..input)
			sustain = sol.timer.start(183, function()
			  if game:is_command_pressed(input) or self.song_played then
				sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..input)
			    return true
			  else 
			    return false
			  end
			end)
			played_note[#played_note + 1] = k
			button[#button + 1] = k

			learning_greyscale_note_correct = learning_greyscale_note_correct + 1
			button[learning_greyscale_note_correct - 1]:fade_in(15)
			self:check_learning_session()
		  end
		end
	  end
    end
  return true
end

function ocarina_manager:simulate_ocarina(pointer)
  local value
  if pointer == 0 then value = "right" 
  elseif pointer == 1 then value = "up" 
  elseif pointer == 2 then value = "left" 
  elseif pointer == 3 then value = "down" 
  elseif pointer == 4 then value = "action"
  end 
  
  if self.ocarina_soundfont == "ocarina" then sfont_delay = 183
  elseif self.ocarina_soundfont == "malon" then sfont_delay = 80 end
  
  if sustain ~= nil then sustain:stop() end
  sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..value)
  if self.ocarina_soundfont ~= "harp" then
	sustain = sol.timer.start(sfont_delay, function()
	   sol.audio.play_sound("/items/ocarina/soundfont/"..self.ocarina_soundfont.."/"..value)
	   return true
	end)
  end
end

function ocarina_manager:on_finished()
  local game = self.game
  sol.timer.stop_all(self)
  
  for i = 0, #played_note do 
	played_note[i] = nil
	note_to_memorize[i] = nil
    time_between_note[i] = nil 
  end
  
  self.can_play = false; self.song_played = false; self.learning_new_song = false; self.game.using_ocarina = false; self.disable_input = false; self.playing_ocarina = false; self.can_draw_text = false
  self.indexed_song_to_learn = nil; self.ocarina_soundfont = nil; song_played = nil
  
  song_delay, note = 0, 0
  
  if not game:is_current_scene_cutscene() then game:show_cutscene_bars(false) end
  game:set_hud_enabled(true)
  game:get_item("ocarina"):set_finished()
  game:set_suspended(false)
  if self.from_movement then game:fade_audio(game:get_value("old_volume"), 10) self.from_movement = false end
  game:get_hero():set_shield_sprite_id("hero/shield"..game:get_value("current_shield"))
  game:get_hero():unfreeze()
  game:set_ability("shield", game:get_value("current_shield"))
  game:set_pause_allowed(true)
end

function ocarina_manager:clear_note_played_if_error()
  for i = 0, learning_greyscale_note_correct - 1 do
    button[i]:set_opacity(0)
  end
end

function ocarina_manager:on_draw(dst_surface)
  if self.playing_ocarina then
    self.ocarina_box:draw(dst_surface, 27, 157)
  end
  
  if self.can_draw_text then
    self.ocarina_se1:draw(dst_surface, text_x, 167)
    self.ocarina_se2:draw(dst_surface, text_x + 4, 167)
  end
  
  if self.draw_flash then
	self.surface:draw(dst_surface, 0, 0)
  end
 
  for i = 0, #note_to_memorize do
    if note_to_memorize[i] ~= nil then
	  if self.can_control then
	    self.greyscale_button_input:set_direction(note_to_memorize[i])
	    self.greyscale_button_input:draw(dst_surface, 63 + (i * 26), y_position[note_to_memorize[i]])
	    if self.disable_input then
	      self.error_img:draw(dst_surface, 74, 169)
	    end
	    for l = 0, #button do
          if played_note[l] ~= nil then
	        button[l - 1]:draw_region(17 * played_note[l] , 0, 17, 17, dst_surface, 63 + ((l - 1)* 26), y_position[played_note[l]])
          end
        end
	  else	 
	    button[i]:draw_region(17 * note_to_memorize[i], 0, 17, 17, dst_surface, 63 + (i * 26), y_position[note_to_memorize[i]])
	  end
    end
  end
end

return ocarina_manager