--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8411258207",
		"rbxassetid://8411260348",
		"rbxassetid://8411258899",
		"rbxassetid://8411260985"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
