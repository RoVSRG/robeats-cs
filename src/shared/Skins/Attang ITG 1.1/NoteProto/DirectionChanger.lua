local imgkeys =
{
		"rbxassetid://10737341759",
		"rbxassetid://10737381142",
		"rbxassetid://10737375286",
		"rbxassetid://10737378773"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
