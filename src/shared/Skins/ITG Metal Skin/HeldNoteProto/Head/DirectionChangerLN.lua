--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8790185322",
		"rbxassetid://8790155129",
		"rbxassetid://8790156219",
		"rbxassetid://8790157165"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
