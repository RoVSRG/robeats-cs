local Transient = require(game.ReplicatedStorage.State.Transient)

local FX = require(game.ReplicatedStorage.Modules.FX)

while not Transient.initialized do
	task.wait()
end

local Bindables = game.ReplicatedStorage.Bindables

Transient.profile:on(function(profile, previousProfile)
	if previousProfile.rating ~= profile.rating then
		FX.PlaySound("LevelUp")

		Bindables.CreateNotification:Fire(
			string.format("Rating updated: +%0.2f (%0.2f)", profile.rating - previousProfile.rating, profile.rating),
			"info"
		)
	end

	if previousProfile.rank ~= profile.rank then
		Bindables.CreateNotification:Fire(
			string.format(
				"Rank updated: #%d -> #%d (+%d)",
				previousProfile.rank,
				profile.rank,
				previousProfile.rank - profile.rank
			),
			"info"
		)
	end
end)
