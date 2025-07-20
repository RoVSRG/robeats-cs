--LONG NOTE PROTO VERSION!

local imgkeys =
{
	"rbxassetid://3391773905",
	"rbxassetid://3391774300",
	"rbxassetid://3391774622",
	"rbxassetid://3391774843"
}

local note = script.Parent
local fullbody = note.Parent
local img = note.ImageLabel
local track = fullbody.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
