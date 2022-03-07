local Knit = require(game.ReplicatedStorage.Packages.Knit)

local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

Knit.AddControllers(game.ReplicatedStorage.Controllers)
EnvironmentSetup:initial_setup()

Knit.Start():andThen(function()
	print("Knit successfully started(client)")
end):catch(function(err)
	warn(err)
end)
