--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8397062816",
		"rbxassetid://8397062816",
		"rbxassetid://8397062816",
		"rbxassetid://8397062816"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
