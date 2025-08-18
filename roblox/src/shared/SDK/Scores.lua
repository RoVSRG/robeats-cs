-- Basic validation functions
local function validateString(value, name)
	assert(type(value) == "string", name .. " must be a string")
	return value
end

local function validateNumber(value, name)
	assert(type(value) == "number", name .. " must be a number")
	return value
end

local function validateBoolean(value, name)
	assert(type(value) == "boolean", name .. " must be a boolean")
	return value
end

local function validateEnumGrade(value, name)
	local validGrades = {F=true, D=true, C=true, B=true, A=true, S=true, SS=true}
	assert(validGrades[value], name .. " must be a valid grade (F, D, C, B, A, S, SS)")
	return value
end

-- Auto-generated Scores SDK - DO NOT EDIT MANUALLY
-- Generated at: 2025-08-18T01:54:53.214Z

local Http = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Http"))

local Scores = {}

-- Submit a score for a song
function Scores.submit(user, payload)
	-- TODO: Add validation for user (unknown)
	-- TODO: Add validation for payload (unknown)

	local config = {
		url = "/scores",
		json = {
			user = user,
			payload = payload,
		},
	}

	local response = Http.post(config.url, config)

	if not response.success then
		error("Failed to submit: " .. tostring(response.body))
	end

	return response.json()
end

-- Get leaderboard for a specific song
function Scores.getLeaderboard(hash, userId)
	validateString(hash, "hash")
	-- TODO: Add validation for userId (unknown)

	local config = {
		url = "/scores/leaderboard",
		params = {
			hash = tostring(hash),
			userId = tostring(userId),
		},
	}

	local response = Http.get(config.url, config)

	if not response.success then
		error("Failed to getLeaderboard: " .. tostring(response.body))
	end

	return response.json()
end

-- Get user's best scores across all songs
function Scores.getUserBest(userId)
	-- TODO: Add validation for userId (unknown)

	local config = {
		url = "/scores/user/best",
		params = {
			userId = tostring(userId),
		},
	}

	local response = Http.get(config.url, config)

	if not response.success then
		error("Failed to getUserBest: " .. tostring(response.body))
	end

	return response.json()
end

-- Get user's score history for a specific song
function Scores.getUserHistory(playerId, songKey)
	validateString(playerId, "playerId")
	validateString(songKey, "songKey")

	local config = {
		url = "/scores/" .. tostring(playerId) .. "/" .. tostring(songKey),
	}

	local response = Http.get(config.url, config)

	if not response.success then
		error("Failed to getUserHistory: " .. tostring(response.body))
	end

	return response.json()
end

return Scores
