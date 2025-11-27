local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Transient = require(ReplicatedStorage.State.Transient)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function Profile(props)
	local profileData, setProfileData = useState(Transient.profile:get())
	local size = props.Size or UDim2.fromScale(0.3, 0.15)
	local position = props.Position or UDim2.fromScale(0.99, 0.02)
	local anchorPoint = props.AnchorPoint or Vector2.new(1, 0)
	local cornerRadius = props.CornerRadius or UDim.new(0, 4)
	local backgroundColor = props.BackgroundColor3 or Color3.fromRGB(17, 17, 17)

	useEffect(function()
		local disconnect = Transient.profile:on(function(newData)
			setProfileData(newData)
		end)
		return disconnect
	end, {})

	return e("Frame", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", { CornerRadius = cornerRadius }),
		
		ProfileImage = e("ImageLabel", {
			Size = UDim2.fromScale(0.25, 0.8), -- Square-ish
			Position = UDim2.fromScale(0.05, 0.1),
			Image = profileData.avatar,
			BackgroundTransparency = 1,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) -- Circle
		}),
		
		InfoContainer = e("Frame", {
			Size = UDim2.fromScale(0.65, 1),
			Position = UDim2.fromScale(0.32, 0),
			BackgroundTransparency = 1,
		}, {
			Username = e("TextLabel", {
				Text = profileData.name,
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.fromOffset(0, 5),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			Rank = e("TextLabel", {
				Text = profileData.rank,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 28),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			Tier = e("TextLabel", {
				Text = profileData.tier,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 46),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			Rating = e("TextLabel", {
				Text = string.format("%0.2f", profileData.rating),
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 215, 0), -- Gold
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 64),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			-- XP Progress Bar
			XPFrame = e("Frame", {
				Size = UDim2.new(1, 0, 0, 4),
				Position = UDim2.new(0, 0, 1, -20),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderSizePixel = 0,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 2) }),

				XPBar = e("Frame", {
					Size = UDim2.new(profileData.xpProgress or 0, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 167, 36), -- Orange
					BorderSizePixel = 0,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 2) }),
				}),
			}),

			Stats = e("TextLabel", {
				Text = string.format("%%: %.2f | # Played: %d", profileData.accuracy, profileData.playCount),
				TextSize = 11,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.new(0, 0, 1, -14),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			}),
		})
	})
end

return Profile
