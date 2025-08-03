local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)

local Remotes = game.ReplicatedStorage.Remotes
local MultiplayerInfo = script.Parent.MultiplayerInfo

local Rooms = workspace:WaitForChild("MultiplayerRooms")
local templates = ScreenChief:GetTemplates("SongSelect")

Rooms.ChildAdded:Connect(function(room)
	local roomName = room.RoomName.Value
	local roomTemplate = templates.Room:Clone()
	roomTemplate.Name = roomName
	roomTemplate.Parent = MultiplayerInfo.RoomsList

	roomTemplate.RoomName.Text = roomName
	roomTemplate.MapName.Text = room.MapName.Value or "Unknown Map"
	roomTemplate.PlayRate.Text = "Play Rate: " .. (room.PlayRate.Value or "1.0")
end)

MultiplayerInfo.LeaveJoinRoom.MouseButton1Click:Connect(function()
	Remotes.Functions.CreateRoom:InvokeServer()
end)