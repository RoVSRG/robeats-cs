local SDK = require(game.ReplicatedStorage:WaitForChild("SDK"))
local Function = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Function"))
local Protect = require(game.ServerScriptService:WaitForChild("Protect"))
local Leaderstats = require(game.ServerScriptService:WaitForChild("Leaderstats"))
local Remotes = game.ReplicatedStorage.Remotes

local Events = game.ServerScriptService.Events

local Queue = require(game.ServerScriptService:WaitForChild("Queue"))

local function mergeTables(...)
	local result = {}
	for _, tbl in ipairs({ ... }) do
		if type(tbl) == "table" then
			for k, v in pairs(tbl) do
				result[k] = v
			end
		end
	end
	return result
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

	-- Build payload to match your backend schema
	local submissionId = string.format(
		"%d_%d_%d",
		player.UserId,
		tick() * 1000, -- milliseconds for uniqueness
		math.random(1000, 9999) -- additional randomness
	)

	local payload = {
		user = {
			userId = player.UserId,
			name = player.Name,
		},
		payload = mergeTables(scoreData, {
			rate = settings.rate,
			hash = settings.hash,
			submissionId = submissionId,
			timestamp = tick(),
		}),
	}

	-- Try synchronous request first using SDK
	local user = payload.user
	local scorePayload = payload.payload

	local success, response = pcall(function()
		return SDK.Scores.submit(user, scorePayload)
	end)

	if success and response and response.success then
		-- Immediate success - apply profile data
		if response.profile then
			Leaderstats.update(player, response.profile)
			Events.PlayerUpdated:Fire(player, response.profile)
		end
		print(player.Name .. " submitted a score (immediate)")
	elseif success and response and not response.success then
		-- Request succeeded but server returned error
		-- Don't queue these as they likely won't succeed on retry
		warn(string.format("Score submission failed for %s: %s", player.Name, response.error or "Unknown error"))
	else
		-- Network/connection failure - queue with callback for retry
		Queue.addToQueue(SDK.Scores.submit, user, scorePayload, function(queuedResponse)
			-- Callback when queued request succeeds
			if queuedResponse and queuedResponse.success and queuedResponse.profile then
				Events.PlayerUpdated:Fire(player, queuedResponse.profile)
				print(player.Name .. " submitted a score (queued)")
			end
		end)
		print(player.Name .. " score submission queued (connection failed)")
	end

	return nil
end)

local getLeaderboard = Function.create(function(player, hash)
	if not hash or type(hash) ~= "string" then
		error("Invalid hash provided for leaderboard retrieval by " .. player.Name)
	end

	local result = SDK.Scores.getLeaderboard(hash, player.UserId)
	return result
end)

local getYourScores = Function.create(function(player)
	local result = SDK.Scores.getUserBest(player.UserId)
	return result
end)

local getGlobalLeaderboard = Function.create(function(player)
	local result = SDK.Players.getTop()
	return result
end)

local getProfile = Function.create(function(player)
	local result = SDK.Players.getProfile(tostring(player.UserId))
	return result
end)

Remotes.Functions.SubmitScore.OnServerInvoke = Protect.wrap(submitScore)
Remotes.Functions.GetLeaderboard.OnServerInvoke = Protect.wrap(getLeaderboard)
Remotes.Functions.GetYourScores.OnServerInvoke = Protect.wrap(getYourScores)
Remotes.Functions.GetGlobalLeaderboard.OnServerInvoke = Protect.wrap(getGlobalLeaderboard)
Remotes.Functions.GetProfile.OnServerInvoke = Protect.wrap(getProfile)

game:GetService("Players").PlayerAdded:Connect(function(player)
	print("Player added: " .. player.Name)

	Queue.addToQueue(SDK.Players.join, player.UserId, player.Name)

	print("Player " .. player.Name .. " has joined.")
end)
