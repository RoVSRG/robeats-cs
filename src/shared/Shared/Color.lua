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

local function getSpreadRichText(ma, p, g, go, b, m)
    return string.format(
		    "Spread: <font color='rgb(255, 255, 255)'>%s</font>"
            .. " / <font color='rgb(235, 220, 13)'>%s</font>"
            .. " / <font color='rgb(57, 192, 16)'>%s</font>"
            .. " / <font color='rgb(25, 62, 250)'>%s</font>"
            .. " / <font color='rgb(174, 22, 194)'>%s</font>"
            .. " / <font color='rgb(190, 30, 30)'>%s</font>",
	    tostring(ma), tostring(p), tostring(g), tostring(go), tostring(b), tostring(m))
end

return {
	getSpreadRichText = getSpreadRichText,
    calculateDifficultyColor = calculateDifficultyColor,
    BASE_H = COLOR_BASE_H,
    BASE_S = COLOR_BASE_S,
    BASE_V = COLOR_BASE_V,
}