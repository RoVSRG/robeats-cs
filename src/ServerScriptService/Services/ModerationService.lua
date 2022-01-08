local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local ModerationService = Knit.CreateService {
    Name = "ModerationService";
    Client = {};
}

local PermissionsService
local AuthService

local Raxios

local url = require(game.ServerScriptService.URLs)

function ModerationService:OnPlayerAdded(player)
    -- Check if the user's account age is too young to join the game

    if player.AccountAge < 2 then
        player:Kick(string.format("Your account must be older than 2 days to join this game. %d days left", 2 - player.AccountAge))
    end

    -- Query to see if the user is banned

    local ban = Raxios.get(url "/bans", {
        query = { userid = player.UserId, auth = AuthService.APIKey }
    }):json()

    if ban then
        player:Kick(ban.Reason)
    end
end


function ModerationService:KnitStart()
    PermissionsService = Knit.GetService("PermissionsService")
    AuthService = Knit.GetService("AuthService")

    Raxios = require(game.ReplicatedStorage.Packages.Raxios)
    
    game.Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    for _, player in pairs(game.Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
end

function ModerationService:BanUser(userId, reason)
    pcall(Raxios.post, url "/bans", {
        query = {
            userid = userId,
            reason = reason,
            auth = AuthService.APIKey
        }
    })

    local player = game.Players:GetPlayerByUserId(userId)

    if player then
        player:Kick(reason)
    end
end

function ModerationService.Client:BanUser(moderator, userId, reason)
    if PermissionsService:HasModPermissions(moderator) then
        if moderator.UserId == userId then
            warn("You can't do that silly")
            return
        end

        ModerationService:BanUser(userId, reason .. " | Moderator: ".. moderator.Name)
    end
end

function ModerationService.Client:KickUser(moderator, userId, reason)
    if PermissionsService:HasModPermissions(moderator) then
        if moderator.UserId == userId then
            warn("N O P E")
            return
        end
        
        local player = game.Players:GetPlayerByUserId(userId)

        if player then
            player:Kick(reason .. " | Moderator: " .. moderator.Name)
        end
    end
end

return ModerationService