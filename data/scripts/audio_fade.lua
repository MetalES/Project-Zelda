function game:audio_fade_out()
sol.timer.start(10,function()
	local volume = 1
	volume = volume - 1
	if volume == 0 then return false end
	sol.audio.set_music_volume(volume)
return true
end)
end

-- Fade in audio

function game:audio_fade_in()
sol.timer.start(10,function()
	local volume = volume + 2
	if volume == self:get_value("old_volume") then return false end
	sol.audio.set_music_volume(volume)
return true
end)
end