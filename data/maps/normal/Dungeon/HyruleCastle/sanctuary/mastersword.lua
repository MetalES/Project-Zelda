local map = ...
local game = map:get_game()
local sprite = nil

function map:on_started()
  sol.audio.play_music("interiors/sealed_sanctuary")
  self:get_entity("king"):get_sprite():fade_out(2)
  if map:get_tileset() == "sealed_hyrule_castle" then
    game:set_time_flow(99999999999999999999999999999999)
  else
    game:set_time_flow(1000)
  end
end

local function sensor_interaction()
  if not game:get_value("king_speech_sanctuary") then
	  hero:freeze()
	  sol.audio.play_sound("characters/companion/spawn")
	  map:get_entity("king"):get_sprite():fade_in(40, function()
		game.display_cutscene_bars = true
		game:start_dialog("map.location.sanctuary.pull_out_sword", function()
		  sol.audio.play_sound("characters/companion/spawn")
		  map:get_entity("king"):get_sprite():fade_out(40, function()
		  game:set_value("king_speech_sanctuary", true)
		  game.dispose_cutscene_bars = true
		  hero:unfreeze()  
		  end)
		end) 
	  end)
  end
end

for sensors in map:get_entities("king_speech") do
  sensors.on_activated = function()
    sensor_interaction()
  end
end
