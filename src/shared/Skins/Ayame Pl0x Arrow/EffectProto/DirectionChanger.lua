--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8721746656",
		"rbxassetid://8721748123",
		"rbxassetid://8721753096",
		"rbxassetid://8721754742"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
