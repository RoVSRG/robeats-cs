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
	usernameLabel.Text = Transient.profile.name:get()
	rankLabel.Text = Transient.profile.rank:get()
	tierLabel.Text = Transient.profile.tier:get()
	ratingLabel.Text = string.format("%0.2f", Transient.profile.rating:get())
	imageLabel.Image = Transient.profile.avatar:get()
	stats.Text =
		string.format("%%: %.2f | # Played: %d", Transient.profile.accuracy:get(), Transient.profile.playCount:get())

	-- Update XP bar width
	local progress = Transient.profile.xpProgress:get()
	xpBar.Size = UDim2.new(progress, 0, 1, 0)
end

-- Listen to state changes and update UI
for _, val in ipairs(Transient.profile) do
	val:on(refresh)
end

-- Initialize profile data on script start
local function initProfile()
	-- Set initial username
	Transient.profile.name:set(player.DisplayName or player.Name)
	Transient.profile.avatar:set(Pfp.getPfp(player.UserId))

	local response = GetProfile:InvokeServer()
	local profile = response.result

	-- Set default values (these would typically come from a server call)
	Transient.profile.rank:set("#" .. profile.rank)
	Transient.profile.tier:set("Coming soon")
	Transient.profile.rating:set(profile.rating)
	Transient.profile.xpProgress:set(0)
	Transient.profile.accuracy:set(profile.accuracy or 0)
	Transient.profile.playCount:set(profile.playCount or 0)

	-- Initial UI update
	refresh()
end

-- Initialize on script start
initProfile()
