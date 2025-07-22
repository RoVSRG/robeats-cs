--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8415137920",
		"rbxassetid://8415137920",
		"rbxassetid://8415137920",
		"rbxassetid://8415137920"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
