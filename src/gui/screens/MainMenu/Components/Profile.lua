local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Transient = require(ReplicatedStorage.State.Transient)
local UI = require(ReplicatedStorage.Util.UI)

local useState = React.useState
local useEffect = React.useEffect

local function Profile(props)
	local profileData, setProfileData = useState(Transient.profile:get())

	useEffect(function()
		local disconnect = Transient.profile:on(function(newData)
			setProfileData(newData)
		end)

		return disconnect
	end, {})

	local size = props.Size or UDim2.new(0.3, 0, 0.15, 0)
	local position = props.Position or UDim2.new(0.99, 0, 0.02, 0)
	local anchorPoint = props.AnchorPoint or Vector2.new(1, 0)
	local bgColor = props.BackgroundColor3 or Color3.fromRGB(17, 17, 17)

	return UI.Frame({
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = bgColor,
		BorderSizePixel = 0,
		children = {
			UI.Corner({ CornerRadius = UDim.new(0, 4) }),

			ProfileImage = UI.Image({
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.015, 0, 0.5, 0),
				Size = UDim2.new(0.6, 0, 0.9, 0),
				Image = profileData.avatar,
				BackgroundColor3 = Color3.fromRGB(11, 11, 11),
				children = {
					UI.Corner({ CornerRadius = UDim.new(0, 4) }),
				},
			}),

			Username = UI.Text({
				Position = UDim2.new(0.29, 0, 0.06, 0),
				Size = UDim2.new(0.5, 0, 0.25, 0),
				Text = profileData.name,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Rank = UI.Text({
				Position = UDim2.new(0.825, 0, 0.06, 0),
				Size = UDim2.new(0.155, 0, 0.25, 0),
				Text = profileData.rank,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			Stats = UI.Text({
				Position = UDim2.new(0.29, 0, 0.32, 0),
				Size = UDim2.new(0.5, 0, 0.15, 0),
				Text = string.format("%%: %.2f | # Played: %d", profileData.accuracy, profileData.playCount),
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Tier = UI.Text({
				Position = UDim2.new(0.48, 0, 0.65, 0),
				Size = UDim2.new(0.5, 0, 0.15, 0),
				Text = profileData.tier,
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			Rating = UI.Text({
				Position = UDim2.new(0.296, 0, 0.6201, 0),
				Size = UDim2.new(0.281, 0, 0.187, 0),
				Text = string.format("%.2f", profileData.rating),
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			XPFrame = UI.Frame({
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0.28, 0, 0.925, 0),
				Size = UDim2.new(0.7, 0, 0.075, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				children = {
					UI.Corner({ CornerRadius = UDim.new(0, 4) }),
					UI.Frame({
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(profileData.xpProgress or 0, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(255, 167, 36),
						BorderSizePixel = 0,
						children = {
							UI.Corner({ CornerRadius = UDim.new(0, 4) }),
						},
					}),
				},
			}),
		},
	})
end

return Profile
