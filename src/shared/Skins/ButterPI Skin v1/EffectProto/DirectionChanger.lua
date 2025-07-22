--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://",
		"rbxassetid://",
		"rbxassetid://",
		"rbxassetid://"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
