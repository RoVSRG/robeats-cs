--EFFECT PROTO VERSION!

local imgkeys =
{
	"rbxassetid://3391789312",
	"rbxassetid://3391789556",
	"rbxassetid://3391789742",
	"rbxassetid://3391790049"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
