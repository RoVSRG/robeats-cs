local track = tonumber(string.match(script.Parent.Parent.Parent.Name, "Track(%d)"))

local ttr = {
	90,
	0,
	180,
	270
}

script.Parent.Rotation = ttr[track]