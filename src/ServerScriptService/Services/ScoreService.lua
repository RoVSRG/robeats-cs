local Knit = require(game.ReplicatedStorage.Packages.Knit)

local DataStoreService = require(game.ReplicatedStorage.Packages.DataStoreService)
local LocalizationService = game:GetService("LocalizationService")

local GraphDataStore = DataStoreService:GetDataStore("GraphDataStore")

local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local RunService

local PermissionsService
local ModerationService
local RateLimitService
local AuthService

local Raxios

local ScoreService = Knit.CreateService({
    Name = "ScoreService",
    Client = {}
})

local url = require(game.ServerScriptService.URLs)

function ScoreService:KnitInit()
    RunService = game:GetService("RunService")

    PermissionsService = Knit.GetService("PermissionsService")
    ModerationService = Knit.GetService("ModerationService")
    RateLimitService = Knit.GetService("RateLimitService")
    AuthService = Knit.GetService("AuthService")

    Raxios = require(game.ReplicatedStorage.Packages.Raxios)
end

function ScoreService:_GetGraphKey(userId, songMD5Hash)
    return string.format("Graph(%s%s)", userId, songMD5Hash)
end

function ScoreService:GetPlayerScores(userId, limit)
    local documents = Raxios.get(url "/scores/player", {
        query = { userid = userId, auth = AuthService.APIKey }
    })

    return documents:json()
end

function ScoreService:CalculateRating(scores)
    local rating = 0;
    local maxNumOfScores = math.min(#scores, 25);

    for i = 1, maxNumOfScores do
        if i > 10 then
            rating = rating + scores[i].Rating * 1.5
        else
            rating = rating + scores[i].Rating;
        end
    end

    return math.floor((100 * rating) / 30) / 100
end

function ScoreService:CalculateAverageAccuracy(scores)
    local accuracy = 0

    for _, score in ipairs(scores) do
        accuracy += score.Accuracy
    end

    return accuracy / #scores
end

function ScoreService:IsBanned(player)
    return Raxios.get(url "/bans", {
        userid = player.UserId,
        auth = AuthService.APIKey
    })
end

function ScoreService.Client:SubmitScore(player, songMD5Hash, rating, score, marvelouses, perfects, greats, goods, bads, misses, accuracy, maxChain, mean, rate, mods)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "SubmitScore", 1) then
        Raxios.post(url "/scores", {
            query = {
                userid = player.UserId,
                auth = AuthService.APIKey
            },
            data = {
                UserId = player.UserId,
                PlayerName = player.Name,
                Rating = rating,
                Score = score,
                Marvelouses = marvelouses,
                Perfects = perfects,
                Greats = greats,
                Goods = goods,
                Bads = bads,
                Misses = misses,
                Mean = mean,
                Accuracy = accuracy,
                Rate = rate,
                MaxChain = maxChain,
                SongMD5Hash = songMD5Hash,
                Mods = mods
            }
        })
    end
end

function ScoreService.Client:SubmitGraph(player, songMD5Hash, graph)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "SubmitGraph", 1) then
        local key = ScoreService:_GetGraphKey(player.UserId, songMD5Hash)

        GraphDataStore:SetAsync(key, graph)
    end
end

function ScoreService.Client:GetGraph(player, userId, songMD5Hash)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetGraph", 2) then
        local key = ScoreService:_GetGraphKey(userId, songMD5Hash)
        return GraphDataStore:GetAsync(key)
    end
    
    return {}
end

function ScoreService.Client:GetScores(player, songMD5Hash, limit, songRate)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetScores", 2) then
        return Raxios.get(url "/scores", {
            query = { hash = songMD5Hash, limit = limit, rate = songRate, auth = AuthService.APIKey }
        }):json()
    end

    return {}, false
end

function ScoreService.Client:GetProfile(player)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetProfile", 2) then
        return Raxios.get(url "/profiles", {
            query = { userid = player.UserId, auth = AuthService.APIKey }
        }):json()
    end

    return {}
end

function ScoreService.Client:GetGlobalLeaderboard(player)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetGlobalLeaderboard", 3) then
        return Raxios.get(url "/profiles/top", {
            query = { auth = AuthService.APIKey }
        }):json()
    end

    return {}
end

function ScoreService.Client:GetPlayerScores(player, userId)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetPlayerScores", 2) then
        return ScoreService:GetPlayerScores(userId or player.UserId)
    end
end

function ScoreService.Client:DeleteScore(moderator, objectId)
    if RateLimitService:CanProcessRequestWithRateLimit(moderator, "DeleteScore", 4) and PermissionsService:HasModPermissions(moderator) then
        return Raxios.delete(url "/scores", {
            query = { id = objectId, auth = AuthService.APIKey }
        }):json()
    end
end

return ScoreService
