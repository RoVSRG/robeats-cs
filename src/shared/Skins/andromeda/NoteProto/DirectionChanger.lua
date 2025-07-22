local imgkeys =
	{
		{id = "rbxassetid://15399215349", rotation = 90},
		{id = "rbxassetid://15399215349", rotation = 0},
		{id = "rbxassetid://15399215349", rotation = 180},
		{id = "rbxassetid://15399215349", rotation = -90}
	}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name, string.len(track.Name)))
img.Image = imgkeys[index].id
img.Rotation = imgkeys[index].rotation
