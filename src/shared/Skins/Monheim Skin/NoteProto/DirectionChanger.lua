local imgkeys =
{
		"rbxassetid://10895191505",
		"rbxassetid://10895194295",
		"rbxassetid://10895194295",
		"rbxassetid://10895191505"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
