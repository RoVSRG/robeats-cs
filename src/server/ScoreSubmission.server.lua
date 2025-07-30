local Http = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Http"))
local Protect = require(game.ServerScriptService:WaitForChild("Protect"))
local Remotes = game.ReplicatedStorage.Remotes

local Queue = require(game.ServerScriptService:WaitForChild("Queue"))

local function mergeTables(...)
    local result = {}
    for _, tbl in ipairs({...}) do
        if type(tbl) == "table" then
            for k, v in pairs(tbl) do
                result[k] = v
            end
        end
    end
    return result
end

local function submitScore(player, scoreData, settings)
	if type(scoreData) ~= "table" then
		warn("Invalid score data submitted by " .. player.Name)
		return { success = false, error = "Invalid data format" }
	end

    if settings == nil then
        warn("No settings provided for score submission by " .. player.Name)
        return
    end

	-- Build payload to match your backend schema
	local payload = {
		user = {
			userId = player.UserId,
			name = player.Name,
		},
		payload = mergeTables(scoreData, {
			rate = settings.rate,
			hash = settings.hash,
		}),
	}

	Queue.addToQueue(Http.post, "/scores", {
		json = payload,
	})

	print(player.Name .. " submitted a score")
	return { success = true }
end

local function getLeaderboard(player, hash)
	if not hash or type(hash) ~= "string" then
		return { success = false, error = "Invalid song hash" }
	end

	local success, result = pcall(function()
		return Http.get("/scores/leaderboard", {
			params = { hash = hash },
		})
	end)

	if not success then
		warn("Failed to fetch leaderboard for " .. player.Name .. ": " .. tostring(result))
		return { success = false, error = "Internal request failed" }
	end

	if not result.success then
		warn("Backend returned error for leaderboard: " .. tostring(result.body))
		return { success = false, error = result.body }
	end

	return { success = true, data = result.json() }
end

Remotes.Functions.SubmitScore.OnServerInvoke = Protect.wrap(submitScore)
Remotes.Functions.GetLeaderboard.OnServerInvoke = Protect.wrap(getLeaderboard)

game:GetService("Players").PlayerAdded:Connect(function(player)
	print("Player added: " .. player.Name)

	Queue.addToQueue(Http.post, "/players/join", {
		json = {
			userId = player.UserId,
			name = player.Name,
		}
	})

    print("Player " .. player.Name .. " has joined.")
end)