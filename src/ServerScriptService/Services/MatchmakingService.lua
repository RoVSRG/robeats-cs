local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local MatchmakingService = Knit.CreateService {
    Name = "MatchmakingService";
    Client = {};
}

MatchmakingService.WIN = "win"
MatchmakingService.LOSS = "loss"

local RateLimitService
local AuthService
local ScoreService

local Raxios

local url = require(game.ServerScriptService.URLs)

local matches = {}

function MatchmakingService:KnitStart()
    AuthService = Knit.GetService("AuthService")
    RateLimitService = Knit.GetService("RateLimitService")
    ScoreService = Knit.GetService("ScoreService")

    Raxios = require(game.ReplicatedStorage.Packages.Raxios)

    game.Players.PlayerRemoving:Connect(function(player)
        if matches[player] then
            self:HandleMatchResult(player, MatchmakingService.LOSS)
        end
    end)
end

function MatchmakingService.Client:ReportMatch(player, data)
    if RateLimitService:CanProcessRequestWithRateLimit("ReportMatch", player, 3) then
        if not matches[player] then
            matches[player] = data
        end
    end
end

function MatchmakingService:RemoveMatch(player)
    matches[player] = nil
end

function MatchmakingService:GetMatch(player)
    return matches[player]
end

function MatchmakingService:HandleMatchResult(player, result)
    if RateLimitService:CanProcessRequestWithRateLimit("ReportMatch", player, 1) then
        local match = matches[player]

        if match then
            local result = Raxios.post(url "/matchmaking/result", {
                query = {
                    userid = player.UserId,
                    result = result,
                    hash = match.SongMD5Hash,
                    rate = match.Rate,
                    auth = AuthService.APIKey
                }
            }):json()

            self:RemoveMatch(player)

            return result
        else
            warn("No match found!")
        end
    end
end

function MatchmakingService.Client:GetMatch(player, mmr)
    if RateLimitService:CanProcessRequestWithRateLimit("GetMatch", player, 3) then
        local matches = Raxios.get(url "/maps/difficulty", {
            query = { closest = mmr },
            auth = AuthService.APIKey
        }):json()

        local match

        for _, m in matches do
            local songKey = SongDatabase:get_key_for_hash(m.SongMD5Hash)

            if songKey ~= SongDatabase:invalid_songkey() then
                local songLength = SongDatabase:get_song_length_for_key(songKey, m.Rate / 100)

                if songLength >= 60000 and songLength <= 300000 and m.Rate <= 140 then
                    match = m
                    break
                end
            end
        end

        return match
    end
end

function MatchmakingService.Client:ReportLeftEarly(player)
    local result = MatchmakingService:HandleMatchResult(player, MatchmakingService.LOSS)

    if result and Llama.Dictionary.count(result) > 0 then
        ScoreService:PopulateUserProfile(player, true)
    end

    return result
end

return MatchmakingService