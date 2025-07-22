--LONG NOTE PROTO VERSION!

local imgkeys =
{
		"rbxassetid://12188474810",
		"rbxassetid://12188471227",
		"rbxassetid://12188471227",
		"rbxassetid://12188474810"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
