local imgkeys =
{
		"rbxassetid://8721640970",
		"rbxassetid://8721643597",
		"rbxassetid://8721645696",
		"rbxassetid://8721648078"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
