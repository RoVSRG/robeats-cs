local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ChatService
local RunService

local TagService = Knit.CreateService {
    Name = "TagService";
    Client = {};
}

function TagService:KnitInit()
    ChatService = require(game:GetService("ServerScriptService"):WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
    RunService = game:GetService("RunService")
end

function TagService:AddTag(player, title, color)
    local speaker
    print(speaker)

    while not speaker do
        speaker = ChatService:GetSpeaker(player.Name)
        wait(1)
    end

    speaker:SetExtraData("Tags", {{ TagText = title, TagColor = color }})
    speaker:SetExtraData("ChatColor", color)
    speaker:SetExtraData("NameColor", color)
    print(speaker)
end

return TagService