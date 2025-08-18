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

-- Auto-generated Players SDK - DO NOT EDIT MANUALLY
-- Generated at: 2025-08-18T01:49:01.654Z

local Http = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Http"))

local Players = {}

-- Join player to the system
function Players.join(userId, name)
	validateNumber(userId, "userId")
	validateString(name, "name")

	local config = {
		url = "/players/join",
		json = {
			userId = userId,
			name = name,
		},
	}

	local response = Http.post(config.url, config)

	if not response.success then
		error("Failed to join: " .. tostring(response.body))
	end

	return response.json()
end

-- Get player profile by userId
function Players.getProfile(userId)
	validateString(userId, "userId")

	local config = {
		url = "/players",
		params = {
			userId = tostring(userId),
		},
	}

	local response = Http.get(config.url, config)

	if not response.success then
		error("Failed to getProfile: " .. tostring(response.body))
	end

	return response.json()
end

-- Get top players by rating
function Players.getTop()

	local config = {
		url = "/players/top",
	}

	local response = Http.get(config.url, config)

	if not response.success then
		error("Failed to getTop: " .. tostring(response.body))
	end

	return response.json()
end

return Players
