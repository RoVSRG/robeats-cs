local Players = game:GetService("Players")

local function updatePlayerCount()
	local pc = #Players:GetPlayers()
	script.Parent.PlayersOnline.Text = tostring(pc)
	print(`[MainMenu.VisualHandler] UPDATED PLAYER COUNT: {pc}`)
end

Players.PlayerAdded:Connect(updatePlayerCount)
updatePlayerCount()
