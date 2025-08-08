local Rating = {}

local function getDifficultyMultiplier(rate: number, baseDifficulty: number)
    if not rate then
        return 1
    end

	if not baseDifficulty then
		error("baseDifficulty is required")
	end

	local TOP_DIFFICULTY = 60

    -- Normalize difficulty to [0, 1] across the 1-80 scale
    local normalizedDifficulty = math.clamp(baseDifficulty / TOP_DIFFICULTY, 0, 1)

    -- Use a difficulty-dependent exponent. For hard songs, amplify the effect of rate;
    -- for easy songs, dampen it. This works symmetrically for r>1 and r<1.
	-- Calibrated from anchors: 63@1.1->~71, 47@1.3->~62, 4@2x->~6
	local EXP_MIN_UP = 0.55  -- very easy songs
	local EXP_MAX_UP = 1.57  -- hardest songs

	local exponent = EXP_MIN_UP + (EXP_MAX_UP - EXP_MIN_UP) * normalizedDifficulty

    return rate ^ exponent
end

local function calculateRating(rate: number, accuracy: number, difficulty: number)
    local BASE_ACCURACY = 97 -- Base accuracy for rating calculation

    return getDifficultyMultiplier(rate, difficulty) * ((accuracy/BASE_ACCURACY)^4) * difficulty
end

local function getRainbowRating()
	return 57
end

local function isRainbow(rating: number)
	return rating >= getRainbowRating()
end

Rating.calculateRating = calculateRating
Rating.getDifficultyMultiplier = getDifficultyMultiplier
Rating.isRainbow = isRainbow
Rating.getRainbowRating = getRainbowRating

return Rating