--[[
  TODO:
   - Update the following code such that it includes "Skill Rating/SR" as a leaderstat, the players country code as a stat, and the players rank as a stat, make sure it is sorted by skill rating.
]]

-- Creating a new leaderboard
return function(player)
  local leaderstats = Instance.new("Folder")
  -- 'leaderstats' is a reserved name Roblox recognizes for creating a leaderboard
  leaderstats.Name = "leaderstats"
  leaderstats.Parent = player

  -- Skill Rating/SR stat
  local srStat = Instance.new("IntValue")
  srStat.Name = "Skill Rating"
  srStat.Value = 0
  srStat.Parent = leaderstats

  -- Country Code stat
  local countryStat = Instance.new("StringValue")
  countryStat.Name = "Country"
  countryStat.Value = "" -- Set this to player's country code elsewhere
  countryStat.Parent = leaderstats

  -- Rank stat
  local rankStat = Instance.new("IntValue")
  rankStat.Name = "Rank"
  rankStat.Value = 0
  rankStat.Parent = leaderstats

  return leaderstats
end