local imgkeys =
{
		"rbxassetid://9860506107",
		"rbxassetid://9860507826",
		"rbxassetid://9860509154",
		"rbxassetid://9860510004"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
