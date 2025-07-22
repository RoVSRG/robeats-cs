--LONG NOTE PROTO VERSION!

local imgkeys =
{
	"rbxassetid://9127606995",
	"rbxassetid://9127609666",
	"rbxassetid://9127610914",
	"rbxassetid://9127612278"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
