local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local function weightingPercentage(x)
	if x == 100 then return 110
    elseif x >= 90 then return -116640 + (64595/18)*x - (9937/270)*x^2 + (17/135)*x^3
    elseif x >= 85 then return 6040 - (851/6)*x + (5/6)*x^2
    elseif x >= 75 then return 0.5*x - 37.5
    else return 0 end
end

local Rating = {}

function Rating:get_rating(difficulty, accuracy)
    local rating = {
        Stream = 0,
        Stamina = 0,
        Jack = 0,
        Chordjack = 0,
        Jumpstream = 0,
        Handstream = 0,
        Technical = 0,
        Overall = 0
    }

    for skillset, value in pairs(difficulty) do
        rating[skillset] = value * weightingPercentage(accuracy) / 100
    end
 
    rating.Rate = nil

	return rating
end

function Rating:get_rating_from_song_key(song_key, accuracy, rate)
	local difficulty = SongDatabase:get_difficulty_for_key(song_key, rate)

	return self:get_rating(difficulty, accuracy)
end

return Rating
