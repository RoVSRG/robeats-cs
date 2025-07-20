local imgkeys =
{
		"rbxassetid://9091782440",
		"rbxassetid://9091787401",
		"rbxassetid://9091790188",
		"rbxassetid://9091792434"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
