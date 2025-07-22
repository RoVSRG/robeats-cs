local imgkeys =
{
		"rbxassetid://10537068540",
		"rbxassetid://10537079037",
		"rbxassetid://13635762334",
		"rbxassetid://10537086503"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
