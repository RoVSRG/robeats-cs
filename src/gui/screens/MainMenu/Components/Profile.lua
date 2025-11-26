local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Transient = require(ReplicatedStorage.State.Transient)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function Profile(props)
	local profileData, setProfileData = useState(Transient.profile:get())

	useEffect(function()
		local disconnect = Transient.profile:on(function(newData)
			setProfileData(newData)
		end)
		return disconnect
	end, {})

	return e("Frame", {
		Size = UDim2.fromScale(0.3, 0.15),
		Position = UDim2.fromScale(0.99, 0.02),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(17, 17, 17),
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		
		ProfileImage = e("ImageLabel", {
			Size = UDim2.fromScale(0.25, 0.8), -- Square-ish
			Position = UDim2.fromScale(0.05, 0.1),
			Image = profileData.avatar,
			BackgroundTransparency = 1,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(1, 0) }) -- Circle
		}),
		
		InfoContainer = e("Frame", {
			Size = UDim2.fromScale(0.65, 0.8),
			Position = UDim2.fromScale(0.32, 0.1),
			BackgroundTransparency = 1,
		}, {
			ListLayout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			
			Username = e("TextLabel", {
				Text = profileData.name,
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromScale(1, 0.3),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			
			RankInfo = e("TextLabel", {
				Text = string.format("%s | %s", profileData.rank, profileData.tier),
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),
			
			Rating = e("TextLabel", {
				Text = string.format("Rating: %.2f", profileData.rating),
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 215, 0), -- Gold
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 3,
			}),
			
			Stats = e("TextLabel", {
				Text = string.format("Acc: %.2f%% | Plays: %d", profileData.accuracy, profileData.playCount),
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 4,
			}),
		})
	})
end

return Profile
