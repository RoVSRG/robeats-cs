local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local Transient = require(ReplicatedStorage.State.Transient)

local e = React.createElement

local function defaultProfile()
	local localPlayer = Players.LocalPlayer

	return {
		name = localPlayer and (localPlayer.DisplayName or localPlayer.Name) or "Player",
		rank = "Unranked",
		accuracy = 0,
		playCount = 0,
		tier = "Unrated",
		rating = 0,
		xpProgress = 0,
		avatar = nil,
	}
end

local function Profile(props)
	local profileData, setProfileData = React.useState(Transient.profile:get() or defaultProfile())

	React.useEffect(function()
		local disconnect = Transient.profile:on(function(newData)
			if newData then
				setProfileData(newData)
			end
		end)
		return disconnect
	end, {})

	React.useEffect(function()
		-- Populate avatar if missing using Roblox thumbnail
		if profileData.avatar or not Players.LocalPlayer then
			return
		end

		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				Players.LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)

		if success then
			setProfileData(function(prev)
				prev = prev or defaultProfile()
				return {
					avatar = content,
					name = prev.name,
					rank = prev.rank,
					accuracy = prev.accuracy,
					playCount = prev.playCount,
					tier = prev.tier,
					rating = prev.rating,
					xpProgress = prev.xpProgress,
				}
			end)
		end
	end, { profileData.avatar })

	local data = profileData or defaultProfile()
	local xpProgress = math.clamp(data.xpProgress or 0, 0, 1)

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
			Image = data.avatar or "",
			BackgroundColor3 = Color3.fromRGB(11, 11, 11),
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextLabel, {
			Position = UDim2.new(0.29, 0, 0.06, 0),
			Size = UDim2.new(0.5, 0, 0.25, 0),
			Text = data.name or "",
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
			Text = data.rank or "",
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
			Text = string.format("%%: %.2f | # Played: %d", data.accuracy or 0, data.playCount or 0),
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
			Text = data.tier or "",
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
			Text = string.format("%.2f", data.rating or 0),
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
				Size = UDim2.new(xpProgress, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 167, 36),
				BorderSizePixel = 0,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

return Profile
