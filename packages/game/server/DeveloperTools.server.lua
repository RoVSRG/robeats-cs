local HttpService = game:GetService("HttpService")
local Development = game.ReplicatedStorage.Remotes.Development

Development.SaveSongChanges.OnServerEvent:Connect(function(player, hash, delta)
	-- Handle the song data sent from the client
	print("Received song data from player:", player.Name)
	print("Song data:", delta)

	local response = HttpService:RequestAsync({
		Url = "http://localhost:3001/save",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({
			hash = hash,
			delta = delta,
		}),
	})

	print(response.Body)
end)
