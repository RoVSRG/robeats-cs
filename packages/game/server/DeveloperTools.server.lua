local Development = game.ReplicatedStorage.Remotes.Development

Development.SaveSongChanges.OnServerEvent:Connect(function(player, delta)
	-- Handle the song data sent from the client
	print("Received song data from player:", player.Name)
	print("Song data:", delta)
end)
