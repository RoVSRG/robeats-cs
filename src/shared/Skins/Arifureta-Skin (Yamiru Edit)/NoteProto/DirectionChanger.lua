local imgkeys =
{
		"rbxassetid://9064043868",
		"rbxassetid://9064046619",
		"rbxassetid://9064050002",
		"rbxassetid://9064051798"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
