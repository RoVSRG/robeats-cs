local Protect = require(game.ServerScriptService:WaitForChild("Protect"))

local Remotes = game.ReplicatedStorage.Remotes

local function submitScore(player, scoreData)
    if type(scoreData) ~= "table" then
        warn("Invalid score data submitted by " .. player.Name)
        return
    end

    print(player.Name .. " submitted a score:", tostring(scoreData))
end

Remotes.Functions.SubmitScore.OnServerInvoke = Protect.wrap(submitScore)