local imgkeys =
{
		"rbxassetid://9860379730",
		"rbxassetid://9860375595",
		"rbxassetid://9860382195",
		"rbxassetid://9860397822"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
