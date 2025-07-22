--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://8895421356",
		"rbxassetid://8895425826",
		"rbxassetid://8895430210",
		"rbxassetid://8895428011"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
