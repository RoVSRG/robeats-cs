local Remotes = game.ReplicatedStorage.Remotes
local MultiplayerInfo = script.Parent.MultiplayerInfo

MultiplayerInfo.LeaveJoinRoom.MouseButton1Click:Connect(function()
	Remotes.Functions.CreateRoom:InvokeServer()
end)