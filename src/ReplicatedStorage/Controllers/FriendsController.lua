local Flipper = require(game.ReplicatedStorage.Packages.Flipper)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local FriendsController = Knit.CreateController { Name = "FriendsController" }

function FriendsController:KnitInit()
    self.Friends = {}
    
    pcall(function()
        local pages = game.Players:GetFriendsAsync(game.Players.LocalPlayer.UserId)

        while true do
            table.foreachi(pages:GetCurrentPage(), function(i, friend)
                table.insert(self.Friends, friend.Id)
            end)

            if pages.IsFinished then
                break
            end

            pages:AdvanceToNextPageAsync()
        end
    end)
end

function FriendsController:IsFriend(id)
    return if table.find(self.Friends, id) then true else false
end

return FriendsController