--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8463518038",
		"rbxassetid://8463518038",
		"rbxassetid://8463518038",
		"rbxassetid://8463518038"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
