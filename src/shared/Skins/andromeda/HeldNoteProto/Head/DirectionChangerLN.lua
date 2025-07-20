

local imgkeys =
	{
		{id = "rbxassetid://", rotation = 90},
		{id = "rbxassetid://", rotation = 0},
		{id = "rbxassetid://", rotation = 180},
		{id = "rbxassetid://", rotation = -90}
	}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name, string.len(track.Name)))
img.Image = imgkeys[index].id
img.Rotation = imgkeys[index].rotation
