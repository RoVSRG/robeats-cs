local Lerp = require(game.ReplicatedStorage.Libraries.Lerp)

local Rating = require(game.ReplicatedStorage.Calculator.Rating)

local COLOR_BASE_H = 229
local COLOR_BASE_S = 67
local COLOR_BASE_V = 92

local function calculateDifficultyColor(rating)
    local alpha = rating / Rating.getRainbowRating()

	local offset = Lerp.lerp(0, 290, math.clamp(alpha, 0, 1))
    
    local value = COLOR_BASE_V

    if alpha > 0 then
        value -= math.clamp(Lerp.lerp(0, COLOR_BASE_V, (alpha - 1) * 3), 0, COLOR_BASE_V)
    end
	
	return Color3.fromHSV(((COLOR_BASE_H - offset) % 360) / 360, COLOR_BASE_S / 100, value / 100)
end

return {
    calculateDifficultyColor = calculateDifficultyColor,
    BASE_H = COLOR_BASE_H,
    BASE_S = COLOR_BASE_S,
    BASE_V = COLOR_BASE_V,
}