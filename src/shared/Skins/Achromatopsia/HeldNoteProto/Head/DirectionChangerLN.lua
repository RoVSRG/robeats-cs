--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8388670880",
		"rbxassetid://8388674520",
		"rbxassetid://8388678127",
		"rbxassetid://8388679572"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
