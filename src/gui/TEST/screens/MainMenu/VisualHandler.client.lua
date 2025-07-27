local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ThumbnailType = Enum.ThumbnailType.HeadShot
local ThumbnailSize = Enum.ThumbnailSize.Size420x420

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
end

-- Main function to update profile UI
local function updateProfile(data)
	usernameLabel.Text = player.DisplayName or player.Name
	rankLabel.Text = "#" .. tostring(data.Rank or 0)
	tierLabel.Text = string.format("Tier %d - %s", data.Tier or 0, data.TierName or "Unranked")
	ratingLabel.Text = string.format("%.2f", data.Rating or 0)
	nextTierLabel.Text = string.format("Tier %d - %s", data.NextTier or 0, data.NextTierName or "???")

	-- Update XP bar width
	local progress = math.clamp((data.XP or 0) / (data.XPGoal or 1), 0, 1)
	xpBar.Size = UDim2.new(progress, 0, 1, 0)
end

-- Example usage:
-- You’d usually get this data from a remote call
 updateProfile({
     Rank = 213,
     Tier = 10,
     TierName = "Legendary",
     Rating = 0,
     XP = 1400,
     XPGoal = 2000,
     NextTier = 11,
     NextTierName = "Mythic"
 })

-- Players count logic
Players.PlayerAdded:Connect(function()
	local pc = #Players:GetPlayers()
	script.Parent.PlayersOnline.Text = tostring(pc)
	print(`[MainMenu.VisualHandler] UPDATED PLAYER COUNT: {pc}`)
end)

-- Initial
setProfilePicture()
