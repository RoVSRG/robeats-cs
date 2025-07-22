local imgkeys =
{
		"rbxassetid://13635383073",
		"rbxassetid://13635383308",
		"rbxassetid://13635383308",
		"rbxassetid://13635383073"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
