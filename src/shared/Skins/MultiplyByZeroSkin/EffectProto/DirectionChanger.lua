--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8427317817",
		"rbxassetid://8427317817",
		"rbxassetid://8427317817",
		"rbxassetid://8427317817"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
