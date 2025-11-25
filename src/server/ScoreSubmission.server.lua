local SDK = require(game.ServerScriptService.Services.SDK)
local Function = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Function"))
local Protect = require(game.ServerScriptService:WaitForChild("Protect"))
local Leaderstats = require(game.ServerScriptService:WaitForChild("Leaderstats"))
local Remotes = game.ReplicatedStorage.Remotes

local Events = game.ServerScriptService.Events

local Queue = require(game.ServerScriptService:WaitForChild("Queue"))

-- Simple selective copy to avoid sending unexpected properties
local function buildScorePayload(scoreData)
	local allowed = {
		"rating",
		"score",
		"accuracy",
		"grade",
		"max_combo",
		"marvelous",
		"perfect",
		"great",
		"good",
		"bad",
		"miss",
		"rate",
		"mean",
		"hash",
	}
	local out = {}
	for _, key in ipairs(allowed) do
		if scoreData[key] ~= nil then
			out[key] = scoreData[key]
		end
	end

	-- Handle camelCase -> snake_case mapping from client stats (e.g., maxCombo -> max_combo)
	if scoreData.maxCombo ~= nil and out.max_combo == nil then
		out.max_combo = scoreData.maxCombo
	end
	return out
end

local submitScore = Function.create(function(player, scoreData, settings)
	if type(scoreData) ~= "table" then
		error("Invalid score data submitted by " .. player.Name)
	end

	if settings == nil then
		error("No settings provided for score submission by " .. player.Name)
	end

	-- Validate Overall Difficulty for ranked integrity
	if settings.overallDifficulty ~= 8 then
		error(
			"Scores can only be submitted with Overall Difficulty 8 for ranked play. Current OD: "
				.. tostring(settings.overallDifficulty or "unknown")
		)
	end

	-- Build payload per new generated SDK schema (PostRequestBody)
	-- PostRequestBody = { user: {...}, map: { hash: string }, payload: { rating, score, accuracy, grade, ... } }
	local payload = {
		user = {
			userId = player.UserId,
			name = player.Name,
		},
		map = { hash = settings.hash },
		payload = buildScorePayload(scoreData),
	}
	payload.payload.rate = settings.rate
	payload.payload.hash = settings.hash

	-- Try synchronous request first using SDK
	local user = payload.user
	local map = payload.map
	local scorePayload = payload.payload

	local success, response = pcall(function()
		return SDK.Scores.post({
			user = user,
			map = map,
			payload = scorePayload,
		})
	end)

	if success and response then
		if response.rank ~= nil then
			Leaderstats.update(player, response)
			Events.PlayerUpdated:Fire(player, response)
		end

		print(player.Name .. " submitted a score (immediate)")

		return response
	else
		Queue.addToQueue(function(u, m, p)
			local ok2, res2 = pcall(function()
				return SDK.Scores.post({ user = u, map = m, payload = p })
			end)
			if ok2 and res2 and res2.rank ~= nil then
				Events.PlayerUpdated:Fire(player, res2)
				print(player.Name .. " submitted a score (queued)")
			end
		end, user, map, scorePayload)
		print(player.Name .. " score submission queued (connection failed)")
	end

	return nil
end)

local getLeaderboard = Function.create(function(player, hash)
	if not hash or type(hash) ~= "string" then
		error("Invalid hash provided for leaderboard retrieval by " .. player.Name)
	end
	local result = SDK.Scores.getLeaderboard(hash, tostring(player.UserId))

	return result
end)

local getYourScores = Function.create(function(player)
	local result = SDK.Scores.getUserBest(tostring(player.UserId))
	return result
end)

local getGlobalLeaderboard = Function.create(function(player)
	local result = SDK.Players.getTop()
	return result
end)

local getProfile = Function.create(function(player)
	local result = SDK.Players.get(tostring(player.UserId))
	return result
end)

Remotes.Functions.SubmitScore.OnServerInvoke = Protect.wrap(submitScore)
Remotes.Functions.GetLeaderboard.OnServerInvoke = Protect.wrap(getLeaderboard)
Remotes.Functions.GetYourScores.OnServerInvoke = Protect.wrap(getYourScores)
Remotes.Functions.GetGlobalLeaderboard.OnServerInvoke = Protect.wrap(getGlobalLeaderboard)

-- unprotected
Remotes.Functions.GetProfile.OnServerInvoke = getProfile

game:GetService("Players").PlayerAdded:Connect(function(player)
	print("Player added: " .. player.Name)

	Queue.addToQueue(function(userId, name)
		SDK.Players.postJoin({ userId = userId, name = name })
	end, player.UserId, player.Name)

	print("Player " .. player.Name .. " has joined.")
end)
