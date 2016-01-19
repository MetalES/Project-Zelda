local game = ...
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
local text_x = 150

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

--Game-accessible funtion
function game:start_ocarina()
  sol.menu.start(self:get_map(), ocarina_manager, true)
end

function game:is_ocarina_active()
  return sol.menu.is_started(ocarina_manager)
end

function game:start_learn_song(index, soundfont)
  self.indexed_song_to_learn = index
  self.ocarina_soundfont = soundfont or "ocarina"
  self.learning_new_song = true
end

function game:stop_ocarina()
  sol.timer.stop_all(ocarina_manager)
  sol.menu.stop(ocarina_manager)
  self:get_item("ocarina"):transit_to_finish()
  self:set_value("using_ocarina", false)
end

function game:is_ocarina_song_learned(song_index)
  return self:get_value("song_" .. song_index .. "_learned")
end

function game:set_ocarina_song_learned(song_index, learned)
  if learned == nil then
    learned = true
  end
  self:set_value("song_" .. song_index .. "_learned", learned)
end

-- The Ocarina
function ocarina_manager:on_started()
  local horizontal_alignment = "left"
  local vertical_alignment = "middle"

  self.game = game
  self.game.ocarina_soundfont = self.game.ocarina_soundfont or "ocarina"
  
  self:clear_note_played_if_error()
  
  self.ocarina_box = sol.surface.create("hud/ocarina/bar.png")
  self.greyscale_button_input = sol.sprite.create("hud/ocarina/note")
  
  self.error_img = sol.surface.create("hud/ocarina/error.png")
  self.first_note_x = 67
  self.note_spacing_x = 9  
  
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
   
  if self.game.learning_new_song then
    self:retrieve_song_to_learn(self.game.indexed_song_to_learn)
	sol.audio.set_music_volume(0)
	self.playing_ocarina = true
  end
end

-- If a song has been played, no mater what position in the array, play the song
function ocarina_manager:check_session()
  for t, n  in ipairs(played_note) do
    if played_note[t] == 2 and played_note[t + 1] == 1 and played_note[t + 2] == 0 and played_note[t + 3] == 2 and played_note[t + 4] == 1 and played_note[t + 5] == 0 and self.game:is_ocarina_song_learned(1) then
	  song_played = 0
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 0 and played_note[t + 3] == 1 and played_note[t + 4] == 0 and played_note[t + 5] == 2 and self.game:is_ocarina_song_learned(2) then
	  song_played = 1
	elseif played_note[t] == 1 and played_note[t + 1] == 2 and played_note[t + 2] == 0 and played_note[t + 3] == 1 and played_note[t + 4] == 2 and played_note[t + 5] == 0 and self.game:is_ocarina_song_learned(3) then
	  song_played = 2
	elseif played_note[t] == 0 and played_note[t + 1] == 3 and played_note[t + 2] == 1 and played_note[t + 3] == 0 and played_note[t + 4] == 3 and played_note[t + 5] == 1 and self.game:is_ocarina_song_learned(4) then
	  song_played = 3
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 1 and played_note[t + 3] == 4 and played_note[t + 4] == 3 and played_note[t + 5] == 1 and self.game:is_ocarina_song_learned(5) then
	  song_played = 4
	elseif played_note[t] == 2 and played_note[t + 1] == 0 and played_note[t + 2] == 3 and played_note[t + 3] == 2 and played_note[t + 4] == 0 and played_note[t + 5] == 3 and self.game:is_ocarina_song_learned(6) then
	  song_played = 5
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 1 and played_note[t + 3] == 2 and played_note[t + 4] == 1 and played_note[t + 5] == 2 and self.game:is_ocarina_song_learned(7) then
	  song_played = 6
	elseif played_note[t] == 0 and played_note[t + 1] == 4 and played_note[t + 2] == 3 and played_note[t + 3] == 0 and played_note[t + 4] == 4 and played_note[t + 5] == 3 and self.game:is_ocarina_song_learned(8) then
	  song_played = 7
	elseif played_note[t] == 4 and played_note[t + 1] == 1 and played_note[t + 2] == 2 and played_note[t + 3] == 0 and played_note[t + 4] == 2 and played_note[t + 5] == 0 and self.game:is_ocarina_song_learned(9) then
	  song_played = 8
	elseif played_note[t] == 3 and played_note[t + 1] == 4 and played_note[t + 2] == 3 and played_note[t + 3] == 4 and played_note[t + 4] == 0 and played_note[t + 5] == 3 and played_note[t + 6] == 0 and played_note[t + 7] == 3 and self.game:is_ocarina_song_learned(10) then
	  song_played = 9
	elseif played_note[t] == 4 and played_note[t + 1] == 0 and played_note[t + 2] == 4 and played_note[t + 3] == 3 and played_note[t + 4] == 4 and played_note[t + 5] == 0 and played_note[t + 6] == 1 and played_note[t + 7] == 3 and self.game:is_ocarina_song_learned(11) then
	  song_played = 10
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 0 and played_note[t + 3] == 0 and played_note[t + 4] == 2 and self.game:is_ocarina_song_learned(12) then
	  song_played = 11
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 4 and played_note[t + 3] == 0 and played_note[t + 4] == 3 and played_note[t + 5] == 4 and self.game:is_ocarina_song_learned(13) then
	  song_played = 12
	elseif played_note[t] == 2 and played_note[t + 1] == 0 and played_note[t + 2] == 0 and played_note[t + 3] == 4 and played_note[t + 4] == 2 and played_note[t + 5] == 0 and played_note[t + 6] == 3 and self.game:is_ocarina_song_learned(14) then
	  song_played = 13
	elseif played_note[t] == 4 and played_note[t + 1] == 3 and played_note[t + 2] == 0 and played_note[t + 3] == 4 and played_note[t + 4] == 3 and played_note[t + 5] == 0 and played_note[t + 6] == 1 and played_note[t + 7] == 0 and self.game:is_ocarina_song_learned(15) then
	  song_played = 14
	elseif played_note[t] == 1 and played_note[t + 1] == 0 and played_note[t + 2] == 1 and played_note[t + 3] == 0 and played_note[t + 4] == 2 and played_note[t + 5] == 1 and self.game:is_ocarina_song_learned(16) then
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
	  sol.audio.play_sound("items/ocarina/song/"..self.game.indexed_song_to_learn)
	  self:play_song(self.game.indexed_song_to_learn)
    end)
  end
end

function ocarina_manager:song_is_error()
    self:clear_note_played_if_error()
	played_note = {}
	sol.audio.play_sound(song_error)
	self.disable_input = true
	sol.timer.start(self, 1000, function()
	  self.error = true
	  self.avoid_restart = true
  end)
end

function ocarina_manager:play_song(index)
-- this part is used to play song, no matter if learning or not
  if not self.playing_ocarina then self.playing_ocarina = true end
-- used for learning
  if song_played ~= nil then 
    self:start_learn_song(song_played)
	self.playing_ocarina = true
  else
    self:clear_note_played_if_error()  
	self.can_control = false
    self:start_learn_song(self.game.indexed_song_to_learn)
  end  
  
  sol.timer.start(self, song_delay, function()
    self.ocarina_se1:set_text_key("ocarina.you_played."..song_name_type)
	self.ocarina_se2:set_text_key("quest_status.caption.ocarina_song_"..(song_played or self.game.indexed_song_to_learn)  + 1)
	self.ocarina_se2:set_color({color[0], color[1], color[2]})
	self.can_draw_text = true
	sol.timer.start(self, 2000, function()
	  if self.game.learning_new_song then
	    ocarina_manager:learned_song(self.game.indexed_song_to_learn)
	  else
	    self:start_song_effect(song_played)
		self:on_finished()
	  end
	end)
  end)
time_between_note[0] = 1
delay = 1
end

function ocarina_manager:learned_song(index)
sol.audio.play_music(nil)
sol.audio.set_music_volume(self.game:get_value("old_volume"))
  sol.timer.start(self, learning_song_delay - (song_delay * 1.50), function()
    self.game:start_dialog("_ocarina."..index..".learned", function()
	  self.game:set_ocarina_song_learned(index, true)
      sol.audio.play_music("cutscene/song_learned", function()
        for teacher in self.game:get_map():get_entities("ocarina_teacher") do
		  teacher:on_song_learned(index)
		end
	  end)
	end)
    self:on_finished()
  end)
end

function ocarina_manager:retrieve_song_to_learn(index)
    if index == 0 then
      note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 2,1,0,2,1,0
	  time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 650, 820, 540, 1500, 820, 540
	  song_delay = 5980; song_name_type = 1; color[0] = 255; color[1] = 0; color[2] = 255; learning_song_delay = 9620
	elseif index == 1 then -- Soaring
	  note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 4,3,0,1,0,2
	  time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 120, 120, 120, 120, 140, 120
	  song_delay = 2500; song_name_type = 0; color[0] = 255; color[1] = 255; color[2] = 255; learning_song_delay = 3750
	elseif index == 2 then -- Epona
	  note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 1,2,0,1,2,0
	  time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 300, 300, 300, 1500, 300, 300
	  song_delay = 4540; song_name_type = 0; color[0] = 255; color[1] = 255; color[2] = 255; learning_song_delay = 7050
	elseif index == 3 then -- Sun Song
	  note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 0,3,1,0,3,1
	  time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 200, 200, 200, 800, 200, 200
	  song_delay = 3500; song_name_type = 0; color[0] = 255; color[1] = 255; color[2] = 0; learning_song_delay = 4850
	elseif index == 4 then -- Storm
	  note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 4,3,1,4,3,1
	  time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 200, 200, 200, 800, 200, 200
	  song_delay = 3500; song_name_type = 0; color[0] = 0; color[1] = 0; color[2] = 255; learning_song_delay = 4800
	elseif index == 5 then -- Apaisement
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 2,0,3,2,0,3
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 600, 600, 600, 700, 600, 600
	 song_delay = 4250; song_name_type = 0; color[0] = 255; color[1] = 0; color[2] = 255; learning_song_delay = 6850
	elseif index == 6 then -- Ode of Byrna
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 4,3,1,2,1,2
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 400, 400, 400, 600, 300, 300
	 song_delay = 3500; song_name_type = 2; color[0] = 255; color[1] = 255; color[2] = 255; learning_song_delay = 6000
	elseif index == 7 then -- Song on Time
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 0,4,3,0,4,3
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 400, 600, 1200, 600, 600, 1200 
	 song_delay = 5000; song_name_type = 0; color[0] = 0; color[1] = 0; color[2] = 255; learning_song_delay = 10500
	elseif index == 8 then -- Wood
  	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 4,1,2,0,2,0
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 300, 300, 300, 1600, 300, 300 
	 song_delay = 5000; song_name_type = 0; color[0] = 0; color[1] = 255; color[2] = 0; learning_song_delay = 15700
	elseif index == 9 then -- Fire
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5], note_to_memorize[6], note_to_memorize[7] = 3,4,3,4,0,3,0,3
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4], time_between_note[5], time_between_note[6], time_between_note[7] = 250, 250, 250, 250, 250, 250, 250, 250
	 song_delay = 5000; song_name_type = 0; color[0] = 255; color[1] = 0; color[2] = 0; learning_song_delay = 18500
	elseif index == 10 then -- Earth
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5], note_to_memorize[6], note_to_memorize[7] = 4,0,4,3,4,0,1,3
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4], time_between_note[5], time_between_note[6], time_between_note[7] = 1000, 1000, 600, 1000, 600, 600, 600, 600
     song_delay = 7000; song_name_type = 0; color[0] = 139; color[1] = 69; color[2] = 19; learning_song_delay = 24700
	elseif index == 11 then -- Water
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4] = 4,3,0,0,2
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4] = 600, 600, 600, 600, 600
	  song_delay = 4500; song_name_type = 1; color[0] = 0; color[1] = 0; color[2] = 255; learning_song_delay = 17450
	elseif index == 12 then -- Spirit
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 4,3,4,0,3,4
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4], time_between_note[5] = 800, 800, 400, 350, 775, 800
	 song_delay = 6000; song_name_type = 0; color[0] = 255; color[1] = 165; color[2] = 0; learning_song_delay = 22000
	elseif index == 13 then -- Shadow
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5], note_to_memorize[6] = 2,0,0,4,2,0,3
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4], time_between_note[5], time_between_note[6] = 500, 600, 600, 300, 300, 300, 300
     song_delay = 6500; song_name_type = 0; color[0] = 255; color[1] = 0; color[2] = 255; learning_song_delay = 20200
	elseif index == 14 then -- Air
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5], note_to_memorize[6], note_to_memorize[7] = 4,3,0,4,3,0,1,0
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3], time_between_note[4], time_between_note[5], time_between_note[6], time_between_note[7] = 200, 200, 200, 1000, 200, 200, 200, 1000
	 song_delay = 5000; song_name_type = 1; color[0] = 0; color[1] = 255; color[2] = 255; learning_song_delay = 21000
	elseif index == 15 then -- Light
	 note_to_memorize[0], note_to_memorize[1], note_to_memorize[2], note_to_memorize[3], note_to_memorize[4], note_to_memorize[5] = 1,0,1,0,2,1
	 time_between_note[0], time_between_note[1], time_between_note[2], time_between_note[3],time_between_note[4], time_between_note[5] = 225, 225, 800, 225, 250, 225 
	 song_delay = 5000; song_name_type = 0; color[0] = 255; color[1] = 255; color[2] = 0; learning_song_delay = 16400
	end 
self:start_learn_song()
end

function ocarina_manager:start_learn_song(index)
  if not self.song_played and self.game.learning_new_song then
    if self.game.indexed_song_to_learn >= 0 and self.game.indexed_song_to_learn <= 7 then
	  self.ocarina_se1:set_text_key("ocarina.learn.memorize_this."..self.game.indexed_song_to_learn) 
	  self.can_draw_text = true
	  text_x = 220
	else
	  self.ocarina_se1:set_text_key("ocarina.learn.memorize_this.type."..song_name_type)
	  self.ocarina_se2:set_text_key("quest_status.caption.ocarina_song_"..self.game.indexed_song_to_learn + 1)
	  self.can_draw_text = true
	end
  end

  sol.timer.start(self, delay_new, function()
	sol.timer.start(self, time_between_note[0], function()
	   button[0]:fade_in(15)
	   if not self.song_played then self:simulate_ocarina(note_to_memorize[0]) end
	   sol.timer.start(self, time_between_note[1], function()
	     button[1]:fade_in(15)
		 if not self.song_played then self:simulate_ocarina(note_to_memorize[1]) end
	     sol.timer.start(self, time_between_note[2], function()
	       button[2]:fade_in(15)
		   if not self.song_played then self:simulate_ocarina(note_to_memorize[2]) end
		   sol.timer.start(self, time_between_note[3], function()
	         button[3]:fade_in(15)
			 if not self.song_played then self:simulate_ocarina(note_to_memorize[3]) end
			 sol.timer.start(self, time_between_note[4], function()
	           button[4]:fade_in(15)
			   if not self.song_played then self:simulate_ocarina(note_to_memorize[4]) end
			   if note_to_memorize[5] == nil and not self.song_played then --check if the next note is valid
				 self:repeat_if_not_done()
			   end
			    if note_to_memorize[5] ~= nil then 
			     sol.timer.start(self, time_between_note[5], function()
					button[5]:fade_in(15)
					if not self.song_played then self:simulate_ocarina(note_to_memorize[5]) end
					 if note_to_memorize[6] == nil and not self.song_played  then --check if the next note is valid
					   self:repeat_if_not_done()
					 end
					if note_to_memorize[6] ~= nil then 
						sol.timer.start(self, time_between_note[6], function()
						  button[6]:fade_in(15)
				          if note_to_memorize[7] == nil and not self.song_played  then --check if the next note is valid
					        self:repeat_if_not_done()
					      end
						  if not self.song_played then self:simulate_ocarina(note_to_memorize[6]) end
						  if note_to_memorize[7] ~= nil then 
							  sol.timer.start(self, time_between_note[7], function()
								button[7]:fade_in(15)
								if not self.song_played then self:simulate_ocarina(note_to_memorize[7]); self:repeat_if_not_done() end
								
							  end)
						  end
					  end)
					end
			     end)
			    end
			  end)
		   end)
		 end)
	   end)
	end)
  end)
  
end

function ocarina_manager:repeat_if_not_done()
	if time_played ~= 1 then
	  sol.timer.start(self, 2500, function()
	    self:clear_note_played_if_error()
	    self:start_learn_song(self.game.indexed_song_to_learn)
	    time_played = 1
		delay_new = 0
		time_between_note[0] = 0
	  end)
	elseif time_played == 1 then
	   sol.timer.start(self, 2500, function()
	     if sustain ~= nil then sustain:stop() end
	     self.can_control = true
		 self.ocarina_se1:set_text_key("ocarina.learn.play_with.0")
		 text_x = 200
		 --Restore the default soundfont to ocarina because we are controlling the hero
		 self.game.ocarina_soundfont = "ocarina"
		 self:clear_note_played_if_error()
	   end)
	end
end

function ocarina_manager:start_song_effect(index)
  if index == 0 then -- Zelda's Lullaby
  	if not self.game:get_map():has_entity("ocarina_zelda") then
		self:return_no_effect()
	else
      for entities in self.game:get_map():get_entities("ocarina_zelda") do
	    entities:on_zelda_lullaby_interaction()
	  end
	end
  elseif index == 1 then -- Song of Soaring
    self.game:start_soaring_menu()
  elseif index == 2 then -- Epona's song
    if self.game:get_value("got_epona") then -- If we have the horse
	  local hero_x, hero_y, hero_layer = self.game:get_hero():get_position()
	  local direction = self.game:get_hero():get_direction() % 2
	  local spawn_point_x, spawn_point_y
	  local type_of = "wall" or "deep_water"
	  
	  	if self.game:get_map():get_ground(hero_x + 32, hero_y, hero_layer) == type_of then
		   spawn_point_x, spawn_point_y = -380, math.random(0,240)		
		elseif self.game:get_map():get_ground(hero_x - 32, hero_y, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = 380, math.random(0,240)
		elseif self.game:get_map():get_ground(hero_x, hero_y - 32, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = math.random(0,320), 300
		elseif self.game:get_map():get_ground(hero_x, hero_y - 32, hero_layer) == type_of then
		    spawn_point_x, spawn_point_y = math.random(0,320), -300
		end
	  if not self.game:get_map():has_entity("epona") and not self.game.no_horse_possible then -- if we are in a valid place
	    local epona = self.game:get_map():create_custom_entity({
		model = "object/horse/epona",
		x = hero_x + spawn_point_x,
		y = hero_y + spawn_point_y,
		layer = hero_layer,
		direction = direction
		})
	  self.game:stop_ocarina()
	  else
	    self.game:get_map():get_entity("epona"):set_position(hero_x + spawn_point_x, hero_y, spawn_point_y)
		local target = sol.movement.create("target")
		target:set_target(hero_x, hero_y)
	    target:start(self.game:get_map():get_entity("epona"))
	  end
	else
     self:return_no_effect()
	end
  elseif index == 3 then -- Sun's Song
    if self.game:get_map():get_world() ~= "outside" then
	  self:return_no_effect()
	else
	  if not self.game.has_played_sun_song then
	  self.game:set_time_flow(20)
	  self.game.has_played_sun_song = true
	  end
	  self.game:stop_ocarina()
	end
  elseif index == 4 then -- Song of Storm
    if self.game:get_map():get_world() ~= "outside" then
      self:return_no_effect()
	else
	  -- self.game:start_storm(song_of_storm)
	end
  elseif index == 5 then -- healing
	if self.game:get_map():has_entity("ocarina_healing") then
		for heal in self.game:get_map():get_entities("ocarina_healing") do
	      local distance = self.game:get_hero():get_distance(heal)
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
	if self.game:get_map():has_entity("ocarina_byrna") then
		for heal in self.game:get_map():get_entities("ocarina_byrna") do
	      local distance = self.game:get_hero():get_distance(heal)
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
    if self.game:get_map():has_entity("block_of_time") then
		for block in self.game:get_map():get_entities("ocarina_song_of_time") do
	      local distance = self.game:get_hero():get_distance(block)
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
     self.game:start_dialog("_ocarina."..index..".played", function(answer)
	    if answer == 1 then
		  --start the animation and warp
		else
		  self.game:stop_ocarina()
		end
	 end)
  end
end

function ocarina_manager:return_no_effect()
  	self.game:start_dialog("_ocarina.played_but_no_effect.0", function()
	  self.game:stop_ocarina()
	end)
end

function ocarina_manager:on_command_pressed(command)
  local handled = true
  if self.can_play then
     if not self.game.learning_new_song and song_played == nil then
		  for k, input in pairs(input_array) do
			if command == input then
			  sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..input)
			    sustain = sol.timer.start(183, function()
				  if self.game:is_command_pressed(input) and not self.game:is_command_pressed("attack") then
			      sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..input)
				  return true
				  else
				  return false
				  end
				end)
			  played_note[#played_note + 1] = k
			  self:check_session()
			  return played_note
			elseif command == "attack" then
			  if sustain ~= nil then sustain:stop() end
			  self:on_finished()
			  self.game:stop_ocarina()
			end
			handled = true
		  end
		  
      elseif self.can_control and self.game.learning_new_song and self.disable_input and self.avoid_restart and not self.song_played then
	  
	    if command == "action" then
		    self.disable_input = false
			self.avoid_restart = false
			sol.audio.play_sound("common/dialog/ocarina_restart")
		end
		handled = true
		
	  elseif self.can_control and self.game.learning_new_song and not self.disable_input and not self.song_played then
	-- Learning a song, you can't cancel the phase
		  for k, input in pairs(input_array) do
				if command == input then
				  sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..input)
					sustain = sol.timer.start(183, function()
					  if self.game:is_command_pressed(input) or self.song_played then
					  sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..input)
					  return true
					  end
					end)
				  played_note[#played_note + 1] = k
				  
				  for k, l in ipairs(played_note) do
					button[#button + 1] = k
					button[k - 1]:fade_in(15)
				  end 
				  
				  self:check_learning_session()
				  return played_note
				end
				handled = true
			end
	   end
  end
end

function ocarina_manager:simulate_ocarina(pointer)
  local value
  if pointer == 0 then value = "right" 
  elseif pointer == 1 then value = "up" 
  elseif pointer == 2 then value = "left" 
  elseif pointer == 3 then value = "down" 
  elseif pointer == 4 then value = "action"
  end 
  
  if self.game.ocarina_soundfont == "ocarina" then sfont_delay = 183
  elseif self.game.ocarina_soundfont == "malon" then sfont_delay = 80 end
  
  
  if sustain ~= nil then sustain:stop() end
  sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..value)
  if self.game.ocarina_soundfont ~= "harp" then
	sustain = sol.timer.start(sfont_delay, function()
	   sol.audio.play_sound("/items/ocarina/soundfont/"..self.game.ocarina_soundfont.."/"..value)
	   return true
	end)
  end
end

function ocarina_manager:on_finished()
  played_note = {}
  note_to_memorize = {}
  time_between_note = {}
  self.can_play = false
  self.song_played = false
  self.game.indexed_song_to_learn = nil
  self.game.ocarina_soundfont = nil
  self.game.learning_new_song = false
  song_played = nil
  self.disable_input = false
  song_delay = 0
  self.playing_ocarina = false
  self.can_draw_text = false
end

function ocarina_manager:clear_note_played_if_error()
  if button[0] ~= nil then button[0]:set_opacity(0) end 
  if button[1] ~= nil then button[1]:set_opacity(0) end 
  if button[2] ~= nil then button[2]:set_opacity(0) end 
  if button[3] ~= nil then button[3]:set_opacity(0) end 
  if button[4] ~= nil then button[4]:set_opacity(0) end 
  if button[5] ~= nil then button[5]:set_opacity(0) end 
  if button[6] ~= nil then button[6]:set_opacity(0) end 
  if button[7] ~= nil then button[7]:set_opacity(0) end 
end

function ocarina_manager:on_draw(dst_surface)

  if self.playing_ocarina then
    self.ocarina_box:draw(dst_surface, 27, 157)
  end
  
  if self.can_draw_text then
    self.ocarina_se1:draw(dst_surface, text_x, 167)
    self.ocarina_se2:draw(dst_surface, 154, 167)
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