--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8405729170",
		"rbxassetid://8405677535",
		"rbxassetid://8405736047",
		"rbxassetid://8405742072"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
