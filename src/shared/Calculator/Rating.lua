local Rating = {}

local function getDifficultyMultiplier(rate)
	if not rate then
		return 1
	end
	
	local multiplier = 1
	
	if rate >= 1 then
		multiplier = 1 + (rate - 1) * 1.1
	else
		multiplier = 1 + (rate - 1) * 2
	end
	
	return multiplier
end

local function calculateRating(rate: number, accuracy: number, difficulty: number)
    local BASE_ACCURACY = 97 -- Base accuracy for rating calculation

	return getDifficultyMultiplier(rate) * ((accuracy/BASE_ACCURACY)^4) * difficulty
end

local function getRainbowRating()
	return 60
end

local function isRainbow(rating: number)
	return rating >= getRainbowRating()
end

Rating.calculateRating = calculateRating
Rating.getDifficultyMultiplier = getDifficultyMultiplier
Rating.isRainbow = isRainbow
Rating.getRainbowRating = getRainbowRating

return Rating