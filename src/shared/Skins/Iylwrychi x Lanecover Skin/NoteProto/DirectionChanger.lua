local imgkeys =
{
		"rbxassetid://8546319716",
		"rbxassetid://8546322413",
		"rbxassetid://8546324843",
		"rbxassetid://8546327230"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
