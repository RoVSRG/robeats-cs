--EFFECT PROTO VERSION!

local imgkeys =
{
	"rbxassetid://3391749386",
	"rbxassetid://3391749579",
	"rbxassetid://3391750533",
	"rbxassetid://3391750719"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
