local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ThumbnailType = Enum.ThumbnailType.HeadShot
local ThumbnailSize = Enum.ThumbnailSize.Size420x420

local GetProfile = game.ReplicatedStorage.Remotes.Functions.GetProfile

local Transient = require(game.ReplicatedStorage.State.Transient)

local profile = script.Parent:WaitForChild("Profile")
local imageLabel = profile:WaitForChild("ProfileImage")
local usernameLabel = profile:WaitForChild("Username")
local rankLabel = profile:WaitForChild("Rank")
local tierLabel = profile:WaitForChild("Tier")
local ratingLabel = profile:WaitForChild("Rating")
local nextTierLabel = profile:WaitForChild("NextTier")
local xpFrame = profile:WaitForChild("XPFrame")
local xpBar = xpFrame:WaitForChild("XPBar")

-- Set profile image
local function setProfilePicture()
	local userId = player.UserId
	local thumbUrl = Players:GetUserThumbnailAsync(userId, ThumbnailType, ThumbnailSize)
	imageLabel.Image = thumbUrl
	Transient.profile.playerAvatarUrl:set(thumbUrl)
end

-- Update UI from Transient state
local function updateProfileUI()
	usernameLabel.Text = Transient.profile.playerUsername:get()
	rankLabel.Text = Transient.profile.playerRank:get()
	tierLabel.Text = Transient.profile.playerTier:get()
	ratingLabel.Text = string.format("%.2f", Transient.profile.playerRating:get())
	imageLabel.Image = Transient.profile.playerAvatarUrl:get()

	-- Update XP bar width
	local progress = Transient.profile.xpProgress:get()
	xpBar.Size = UDim2.new(progress, 0, 1, 0)
end

-- Listen to state changes and update UI
Transient.profile.playerUsername:on(updateProfileUI)
Transient.profile.playerRank:on(updateProfileUI)
Transient.profile.playerTier:on(updateProfileUI)
Transient.profile.playerRating:on(updateProfileUI)
Transient.profile.playerAvatarUrl:on(updateProfileUI)
Transient.profile.xpProgress:on(updateProfileUI)

-- Initialize profile data on script start
local function initProfile()
	-- Set initial username
	Transient.profile.playerUsername:set(player.DisplayName or player.Name)

	-- Set initial profile picture
	setProfilePicture()

	local response = GetProfile:InvokeServer()
	local profile = response.result.profile

	-- Set default values (these would typically come from a server call)
	Transient.profile.playerRank:set("#" .. profile.rank)
	Transient.profile.playerTier:set("Coming soon")
	Transient.profile.playerRating:set(profile.rating)
	Transient.profile.xpProgress:set(0)

	-- Initial UI update
	updateProfileUI()
end

-- Initialize on script start
initProfile()
