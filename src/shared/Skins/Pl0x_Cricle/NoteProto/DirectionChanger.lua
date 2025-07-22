local imgkeys =
{
		"rbxassetid://8392736620",
		"rbxassetid://8392736620",
		"rbxassetid://8392736620",
		"rbxassetid://8392736620"
}

local note = script.Parent
local img = note.ImageLabel
local track = note.Parent
local index = tonumber(string.sub(track.Name,string.len(track.Name)))
img.Image = imgkeys[index]
