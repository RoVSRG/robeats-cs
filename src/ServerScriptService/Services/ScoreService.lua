local Knit = require(game.ReplicatedStorage.Packages.Knit)

local DataStoreService = require(game.ReplicatedStorage.Packages.DataStoreService)
local LocalizationService = game:GetService("LocalizationService")

local DataSerializer = require(game.ReplicatedStorage.Packages.DataSerializer)

local GraphDataStore = DataStoreService:GetDataStore("GraphDataStore")

local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local Tiers = require(game.ReplicatedStorage.Tiers)

local RunService
local HttpService

local PermissionsService
local MatchmakingService
local RateLimitService
local AuthService
local StateService

local Llama
local Raxios
local Hook
local FormatHelper

-- the player wins against a map when they get >=96 accuracy
local ACCURACY_WIN_THRESHOLD = 96

local ScoreService = Knit.CreateService({
    Name = "ScoreService",
    Client = {}
})

local url = require(game.ServerScriptService.URLs)

function ScoreService:KnitInit()
    RunService = game:GetService("RunService")
    HttpService = game:GetService("HttpService")

    PermissionsService = Knit.GetService("PermissionsService")
    MatchmakingService = Knit.GetService("MatchmakingService")
    RateLimitService = Knit.GetService("RateLimitService")
    AuthService = Knit.GetService("AuthService")
    StateService = Knit.GetService("StateService")

    Llama = require(game.ReplicatedStorage.Packages.Llama)    
    Raxios = require(game.ReplicatedStorage.Packages.Raxios)
end

function ScoreService:PopulateUserProfile(player, override)
    local state = StateService.Store:getState()

    if state.profiles[tostring(player.UserId)] and not override then
        return
    end

    local profile = self:GetProfile(player)

    if Llama.Dictionary.count(profile) > 0 and not profile.error then
        if typeof(profile.Rating) == "number" then
            profile.Rating = { Overall = profile.Rating }
        end

        StateService.Store:dispatch({ type = "addProfile", player = player, profile = profile })

        local leaderstats = player:FindFirstChild("leaderstats")

        local rating
        local rank
        local tier
        local wlstreak

        if leaderstats then
            rating = leaderstats:FindFirstChild("Rating")
            rank = leaderstats:FindFirstChild("Rank")
            tier = leaderstats:FindFirstChild("Tier")
            wlstreak = leaderstats:FindFirstChild("Win/Loss")
        else
            leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"

            rating = Instance.new("StringValue")
            rating.Name = "Rating"

            rank = Instance.new("StringValue")
            rank.Name = "Rank"

            tier = Instance.new("StringValue")
            tier.Name = "Tier"

            wlstreak = Instance.new("StringValue")
            wlstreak.Name = "Win/Loss"

            rating.Parent = leaderstats
            rank.Parent = leaderstats
            tier.Parent = leaderstats
            wlstreak.Parent = leaderstats

            leaderstats.Parent = player
        end

        rating.Value = if profile.RankedMatchesPlayed >= 10 then string.format("%d", profile.GlickoRating) else "???"
        rank.Value = "#" .. profile.Rank
        wlstreak.Value = math.abs(profile.WinStreak) .. if profile.WinStreak > 0 then " W" elseif profile.WinStreak < 0 then " L" else ""

        local tierInfo = Tiers:GetTierFromRating(profile.GlickoRating)

        if tierInfo then
            tier.Value = string.sub(tierInfo.name, 1, 1)

            if tierInfo.division then
                tier.Value = tier.Value .. tierInfo.division
            end
        end
    end
end

function ScoreService:KnitStart()
    local function onPlayerAdded(player)
        self:PopulateUserProfile(player)
    end

    game.Players.PlayerAdded:Connect(onPlayerAdded)
    game.Players.PlayerRemoving:Connect(function(player)
        local state = StateService.Store:getState()

        if state.profiles[tostring(player.UserId)] then
            StateService.Store:dispatch({ type = "removeProfile", player = player })
        end
    end)

    table.foreachi(game.Players:GetPlayers(), function(_, player)
        task.spawn(onPlayerAdded, player)
    end)

    Hook = require(game.ServerScriptService.DiscordWebhook).new(AuthService.WebhookURL.id, AuthService.WebhookURL.token)
    FormatHelper = Hook:GetFormatHelper()
end

function ScoreService:_GetGraphKey(userId, songMD5Hash)
    return string.format("Graph(%s%s)", userId, songMD5Hash)
end

function ScoreService:GetPlayerScores(userId, limit)
    local documents = Raxios.get(url "/scores/player", {
        query = { userid = userId, auth = AuthService.APIKey }
    }):json()

    for _, score in ipairs(documents) do
        if typeof(score.Rating) == "number" or typeof(score.Rating) == "nil" then
            score.Rating = { Overall = score.Rating or 0 }
        end
    end

    return documents
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

function ScoreService:GetProfile(player, userId)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetProfile", 2) then
        local profile = Raxios.get(url "/profiles", {
            query = { userid = userId or player.UserId, auth = AuthService.APIKey }
        }):json()

        if typeof(profile.Rating) == "number" then
            return { error = "No scores found" }
        end

        return profile
    end

    return {}
end

function ScoreService.Client:SubmitScore(player, data)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "SubmitScore", 1) then
        local country

        pcall(function()
            country = LocalizationService:GetCountryRegionForPlayerAsync(player)
        end)
        
        local response = Raxios.post(url "/scores", {
            query = {
                userid = player.UserId,
                auth = AuthService.APIKey
            },
            data = {
                UserId = player.UserId,
                PlayerName = player.Name,
                Rating = data.Rating,
                Score = data.Score,
                Marvelouses = data.Marvelouses,
                Perfects = data.Perfects,
                Greats = data.Greats,
                Goods = data.Goods, 
                Bads = data.Bads,
                Misses = data.Misses,
                Mean = data.Mean or 0,
                Accuracy = data.Accuracy,   
                Rate = data.Rate,
                MaxChain = data.MaxChain,
                SongMD5Hash = data.SongMD5Hash,
                Mods = data.Mods,
                CountryRegion = country
            }
        }):json()

        local match = MatchmakingService:GetMatch(player)

        if match then
            local profile = MatchmakingService:HandleMatchResult(player, if data.Accuracy >= ACCURACY_WIN_THRESHOLD then MatchmakingService.WIN else MatchmakingService.LOSS)

            local template = [[
                MMR: %d
                RD: %0.2f
                Sigma: %0.4f
            ]]

            print(string.format(template, profile.GlickoRating, profile.RD, profile.Sigma))
        end

        ScoreService:PopulateUserProfile(player, true)

        local message = Hook:NewMessage()
        local embed = message:NewEmbed()
        local playStatsField = embed:NewField()
        local spreadField = embed:NewField()

        local key = SongDatabase:get_key_for_hash(data.SongMD5Hash)
        local songArtist = SongDatabase:get_artist_for_key(key)
        local songTitle = SongDatabase:get_title_for_key(key)

        --MESSAGE
        message:SetUsername('SCOREMASTER')
        message:SetTTS(false)
        
        --EMBED
        embed:SetURL("https://www.roblox.com/users/" .. player.UserId .."/profile")
        embed:SetTitle(string.format("%s played %s - %s [%0.2fx rate]", player.Name, songArtist, songTitle, data.Rate / 100))
        embed:SetThumbnailIconURL(string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", player.UserId))
        embed:SetColor3(Color3.fromRGB(math.random(0, 255), math.random(0, 255),math.random(0, 255)))
        embed:AppendFooter("this is a certified hood classic") -- we must protect this at all costs

        --PLAYSTATSFIELD
        playStatsField:SetName("Play Stats")
        playStatsField:AppendLine("Rating: " .. FormatHelper:CodeblockLine(string.format("%0.2f", data.Rating.Overall)))-- yeet
        playStatsField:AppendLine("Score: " .. FormatHelper:CodeblockLine(data.Score))
        playStatsField:AppendLine("Accuracy : " .. FormatHelper:CodeblockLine(string.format("%0.2f%%", data.Accuracy)))
        playStatsField:AppendLine("Mean: " .. FormatHelper:CodeblockLine(string.format("%0.2f", data.Mean)))

        spreadField:SetName("Spread Data")
        spreadField:AppendLine("Marvelouses: " .. FormatHelper:CodeblockLine(data.Marvelouses))-- yeet
        spreadField:AppendLine("Perfects: " .. FormatHelper:CodeblockLine(data.Perfects))
        spreadField:AppendLine("Greats: " .. FormatHelper:CodeblockLine(data.Greats))
        spreadField:AppendLine("Goods: " .. FormatHelper:CodeblockLine(data.Goods))
        spreadField:AppendLine("Bads: " .. FormatHelper:CodeblockLine(data.Bads))
        spreadField:AppendLine("Misses: " .. FormatHelper:CodeblockLine(data.Misses))

        message:Send()

        print("Webhook posted")

        return response.pb
    end

    return false
end

function ScoreService.Client:GetReplay(player, userId, hash)
    assert(typeof(hash) == "string", "You did not include a hash!")

    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetReplay", 2) then
        local replay = Raxios.get(url "/scores/replay", {
            query = {
                auth = AuthService.APIKey,
                hash = hash,
                userid = userId
            }
        }):json()

        if replay.success == false then
            return
        end

        return DataSerializer.Deserialize(replay)
    end
end

function ScoreService.Client:SubmitReplay(player, hash, replay)
    assert(typeof(hash) == "string", "You did not include a hash!")

    if RateLimitService:CanProcessRequestWithRateLimit(player, "SubmitReplay", 2) then
        Raxios.post(url "/scores/replay", {
            query = {
                auth = AuthService.APIKey,
                hash = hash,
                userid = player.UserId
            },
            data = DataSerializer.Serialize(replay)
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
        local scores = Raxios.get(url "/scores", {
            query = { hash = songMD5Hash, limit = limit, rate = songRate, auth = AuthService.APIKey }
        }):json()

        for _, score in ipairs(scores) do
            if typeof(score.Rating) == "number" or typeof(score.Rating) == "nil" then
                score.Rating = { Overall = score.Rating or 0 }
            end
        end

        return scores
    end

    return {}, false
end

function ScoreService.Client:GetProfile(player, userId)
    return ScoreService:GetProfile(player, userId)
end

function ScoreService.Client:GetGlobalLeaderboard(player, country)
    if RateLimitService:CanProcessRequestWithRateLimit(player, "GetGlobalLeaderboard", 3) then
        local leaderboard = Raxios.get(url "/profiles/top", {
            query = { auth = AuthService.APIKey, country = country }
        }):json()

        for _, slot in ipairs(leaderboard) do
            if typeof(slot.Rating) == "number" or typeof(slot.Rating) == "nil" then
                slot.Rating = { Overall = slot.Rating or 0 }
            end
        end

        return leaderboard
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
