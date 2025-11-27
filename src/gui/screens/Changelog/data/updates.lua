--[[
	Changelog Updates Data

	Array of update entries displayed in the Changelog screen.
	Each entry has: version, title, lines (array of bullet points), color
]]

-- Helper for random silly colors (matching archive implementation)
local function randomColor()
	local h = math.random()
	local s = math.random(30, 50) / 100
	local v = math.random(60, 85) / 100
	return Color3.fromHSV(h, s, v)
end

return {
	{
		version = 1,
		title = "Absolute CINEMA",
		lines = {
			"We slapped this together over the course of a few weeks.",
			"Yes, you're welcome.",
			"Introduced bugs beyond your belief.",
		},
		color = randomColor(),
	},
	-- Add more updates here as needed
	-- {
	-- 	version = 2,
	-- 	title = "Another Update",
	-- 	lines = {
	-- 		"Fixed some bugs",
	-- 		"Added some features",
	-- 	},
	-- 	color = randomColor(),
	-- },
}
