local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Development = game.ReplicatedStorage.Remotes.Development

-- Simple guard: only allow in Studio for now
Development.SaveSongChanges.OnServerEvent:Connect(function(player, hash, delta)
	if not RunService:IsStudio() then
		warn("[DevTools] SaveSongChanges blocked outside Studio")
		return
	end

	print("[DevTools] Received metadata delta from", player.Name, hash)

	local response = HttpService:RequestAsync({
		Url = "http://localhost:3001/save",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({ hash = hash, delta = delta }),
	})

	print("[DevTools] Save response:", response.StatusCode, response.Body)

	-- TODO: Optionally notify clients to refresh metadata for that song hash
end)
