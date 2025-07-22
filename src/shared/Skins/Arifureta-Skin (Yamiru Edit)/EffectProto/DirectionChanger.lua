--EFFECT PROTO VERSION!

local imgkeys =
{
		"rbxassetid://9067354062",
		"rbxassetid://9067343193",
		"rbxassetid://9067329499",
		"rbxassetid://9067352891"
}

local effect = script.Parent
local track = effect.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
effect.Image = imgkeys[index]
