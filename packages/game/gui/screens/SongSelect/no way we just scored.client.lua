local Transient = require(game.ReplicatedStorage.State.Transient)

while not Transient.initialized do
	task.wait()
end

local Bindables = game.ReplicatedStorage.Bindables

Transient.profile:on(function(profile, previousProfile)
	if previousProfile.rating ~= profile.rating then
		Bindables.CreateNotification:Fire(
			string.format("Rating updated: +%0.2f (%0.2f)", profile.rating - previousProfile.rating, profile.rating),
			"info"
		)
	end
end)
