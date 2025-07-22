local imgkeys =
{
		"rbxassetid://8613839510",
		"rbxassetid://8613841485",
		"rbxassetid://8613841485",
		"rbxassetid://8613839510"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
