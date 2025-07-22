--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8388616779",
		"rbxassetid://8388616779",
		"rbxassetid://8388616779",
		"rbxassetid://8388616779"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
