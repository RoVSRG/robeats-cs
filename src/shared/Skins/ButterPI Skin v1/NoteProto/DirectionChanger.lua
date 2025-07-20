local imgkeys =
{
		"rbxassetid://8441669470",
		"rbxassetid://8441669470",
		"rbxassetid://8441669470",
		"rbxassetid://8441669470"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
