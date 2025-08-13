return function(player)
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

  return leaderstats
end