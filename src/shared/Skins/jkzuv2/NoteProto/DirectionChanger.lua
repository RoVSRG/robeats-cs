local imgkeys =
{
		"rbxassetid://11695265403",
		"rbxassetid://11695140234",
		"rbxassetid://11695140234",
		"rbxassetid://11695265403"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
