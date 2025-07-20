--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://9091849117",
		"rbxassetid://9091854351",
		"rbxassetid://9091856234",
		"rbxassetid://9091858017"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
