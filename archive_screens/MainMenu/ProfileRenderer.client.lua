local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Pfp = require(game.ReplicatedStorage.Shared.Pfp)

local GetProfile = game.ReplicatedStorage.Remotes.Functions.GetProfile

local Transient = require(game.ReplicatedStorage.State.Transient)

local profile = script.Parent:WaitForChild("Profile")
local imageLabel = profile:WaitForChild("ProfileImage")
local usernameLabel = profile:WaitForChild("Username")
local rankLabel = profile:WaitForChild("Rank")
local tierLabel = profile:WaitForChild("Tier")
local ratingLabel = profile:WaitForChild("Rating")
local xpFrame = profile:WaitForChild("XPFrame")
local xpBar = xpFrame:WaitForChild("XPBar")
local stats = profile:WaitForChild("Stats")

-- Update UI from Transient state
local function refresh()
	local profileData = Transient.profile:get()
	usernameLabel.Text = profileData.name
	rankLabel.Text = profileData.rank
	tierLabel.Text = profileData.tier
	ratingLabel.Text = string.format("%0.2f", profileData.rating)
	imageLabel.Image = profileData.avatar
	stats.Text = string.format("%%: %.2f | # Played: %d", profileData.accuracy, profileData.playCount)

	-- Update XP bar width
	local progress = profileData.xpProgress
	xpBar.Size = UDim2.new(progress, 0, 1, 0)
end

-- Listen to state changes and update UI
Transient.profile:on(refresh)

-- Initialize profile data on script start
local function initProfile()
	local response = GetProfile:InvokeServer()
	local profile = response.result

	-- Update profile using the setter function
	Transient.updateProfile(
		player,
		Pfp.getPfp(player.UserId),
		"Coming soon",
		"#" .. profile.rank,
		profile.rating,
		profile.accuracy or 0,
		profile.playCount or 0
	)

	-- Initial UI update
	refresh()
end

-- Initialize on script start
initProfile()
