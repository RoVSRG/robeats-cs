local imgkeys =
	{
		"rbxassetid://6869613442",
		"rbxassetid://6869613253",
		"rbxassetid://6869613511",
		"rbxassetid://6869613357"
	}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
