local Transient = require(game.ReplicatedStorage.State.Transient)

print("Watching song hash changes...")

local DEBOUNCE = 0.8

function onSongHashChanged(hash)
	print("Current song hash: " .. hash)
end

Transient.song.hash:on(function(hash)
	task.delay(DEBOUNCE, function()
		if hash ~= Transient.song.hash:get() then
			return
		end

		onSongHashChanged(hash)
	end)
end)
