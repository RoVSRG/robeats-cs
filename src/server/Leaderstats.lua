local Leaderstats = {}

function Leaderstats.create(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local rankLeaderstat = Instance.new("StringValue")
	rankLeaderstat.Name = "Rank"
	rankLeaderstat.Value = "#?"
	rankLeaderstat.Parent = leaderstats

	local ratingLeaderstat = Instance.new("IntValue")
	ratingLeaderstat.Name = "Rating"
	ratingLeaderstat.Value = 0
	ratingLeaderstat.Parent = leaderstats

	local countryLeaderstat = Instance.new("StringValue")
	countryLeaderstat.Name = "Country"
	countryLeaderstat.Value = "??"
	countryLeaderstat.Parent = leaderstats

	local rank = player:FindFirstChild("rank")

	return leaderstats
end

function Leaderstats.update(player, profile)
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		leaderstats.Rank.Value = "#" .. profile.rank
		leaderstats.Rating.Value = profile.rating
	end
end

return Leaderstats
