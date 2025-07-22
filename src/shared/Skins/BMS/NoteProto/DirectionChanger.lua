local imgkeys =
{
		"rbxassetid://8863356590",
		"rbxassetid://8863361112",
		"rbxassetid://8863361112",
		"rbxassetid://8863356590"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
