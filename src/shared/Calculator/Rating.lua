local Rating = {}

local function calculateRating(rate: number, accuracy: number, difficulty: number)
    local BASE_ACCURACY = 97 -- Base accuracy for rating calculation
	local rateMult = 1

	if rate then
		if rate >= 1 then
			rateMult = 1 + (rate-1) * 0.6
		else
			rateMult = 1 + (rate-1) * 2
		end
	end

	return rateMult * ((accuracy/BASE_ACCURACY)^4) * difficulty
end

Rating.calculateRating = calculateRating

return Rating