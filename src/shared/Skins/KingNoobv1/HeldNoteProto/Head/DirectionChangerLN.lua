--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://13680990125",
		"rbxassetid://13680992024",
		"rbxassetid://13680993655",
		"rbxassetid://13680995027"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
