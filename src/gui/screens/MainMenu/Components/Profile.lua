local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local Transient = require(ReplicatedStorage.State.Transient)

local e = React.createElement

local function Profile(props)
	local profileData, setProfileData = React.useState(Transient.profile:get() or {})

	React.useEffect(function()
		local disconnect = Transient.profile:on(function(newData)
			setProfileData(newData or {})
		end)
		return disconnect
	end, {})

	return e(UI.Frame, {
		Size = props.Size or UDim2.new(0.3, 0, 0.15, 0),
		Position = props.Position or UDim2.new(0.99, 0, 0.02, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(1, 0),
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(17, 17, 17),
		BorderSizePixel = 0,
	}, {
		e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

		e(UI.ImageLabel, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0.015, 0, 0.5, 0),
			Size = UDim2.new(0.6, 0, 0.9, 0),
			Image = profileData.avatar or "",
			BackgroundColor3 = Color3.fromRGB(11, 11, 11),
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.29, 0, 0.06, 0),
			Size = UDim2.new(0.5, 0, 0.25, 0),
			Text = profileData.name or "",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.825, 0, 0.06, 0),
			Size = UDim2.new(0.155, 0, 0.25, 0),
			Text = profileData.rank or "",
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.29, 0, 0.32, 0),
			Size = UDim2.new(0.5, 0, 0.15, 0),
			Text = string.format("%%: %.2f | # Played: %d", profileData.accuracy or 0, profileData.playCount or 0),
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.48, 0, 0.65, 0),
			Size = UDim2.new(0.5, 0, 0.15, 0),
			Text = profileData.tier or "",
			Font = Enum.Font.Gotham,
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.296, 0, 0.6201, 0),
			Size = UDim2.new(0.281, 0, 0.187, 0),
			Text = string.format("%.2f", profileData.rating or 0),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),

		e(UI.Frame, {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0.28, 0, 0.925, 0),
			Size = UDim2.new(0.7, 0, 0.075, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			e(UI.Frame, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(profileData.xpProgress or 0, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 167, 36),
				BorderSizePixel = 0,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

return Profile
