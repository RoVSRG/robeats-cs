local Http = require(game.ServerScriptService:WaitForChild("Utils"):WaitForChild("Http"))
local Protect = require(game.ServerScriptService:WaitForChild("Protect"))
local Remotes = game.ReplicatedStorage.Remotes

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

	local success, result = pcall(function()
		return Http.post("/scores", {
			json = payload,
		})
	end)

	if not success then
		warn("Failed to send score for " .. player.Name .. ": " .. tostring(result))
		return { success = false, error = "Internal request failed" }
	end

	if not result.success then
		warn("Backend rejected score for " .. player.Name .. ": " .. tostring(result.body))
		return { success = false, error = result.body }
	end

	print(player.Name .. " submitted a score successfully!")
	return { success = true }
end

Remotes.Functions.SubmitScore.OnServerInvoke = Protect.wrap(submitScore)

game:GetService("Players").PlayerAdded:Connect(function(player)
    Http.post("/players/join", {
        json = {
            userId = player.UserId,
            name = player.Name,
        }
    })

    print("Player " .. player.Name .. " has joined.")
end)