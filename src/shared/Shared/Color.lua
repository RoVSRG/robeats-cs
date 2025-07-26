local Lerp = require(game.ReplicatedStorage.Libraries.Lerp)

local COLOR_BASE_H = 229
local COLOR_BASE_S = 67
local COLOR_BASE_V = 92

local function calculateDifficultyColor(alpha)
	local offset = Lerp.lerp(0, 280, math.clamp(alpha, 0, 1))
	
	return Color3.fromHSV(((COLOR_BASE_H - offset) % 360) / 360, COLOR_BASE_S / 100, COLOR_BASE_V / 100)
end

return {
    calculateDifficultyColor = calculateDifficultyColor,
    BASE_H = COLOR_BASE_H,
    BASE_S = COLOR_BASE_S,
    BASE_V = COLOR_BASE_V,
}