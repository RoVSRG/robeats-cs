--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://3075538622",
		"rbxassetid://3075538622",
		"rbxassetid://3075538622",
		"rbxassetid://3075538622"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
