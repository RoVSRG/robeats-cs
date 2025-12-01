local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local MultiplayerSongInfo = require(script.Parent.MultiplayerSongInfo)

local e = React.createElement

--[[
	MultiplayerPanel - Multiplayer room UI

	Shows:
	- Room info and custom field
	- Player list and controls
	- Song info with rate controls
	- Leave/Join button
]]
local function MultiplayerPanel(props)
	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(0.33575, 1),
		Position = props.position or UDim2.fromScale(0.64219815, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Room info label (top) - Position (0.018, 0.0125), Size (0.964, 0.05)
		RoomInfo = e(UI.TextLabel, {
			Text = "",
			Size = UDim2.fromScale(0.9636363, 0.05),
			Position = UDim2.fromScale(0.0181818, 0.0125),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.ArialBold,
		}),

		-- Room custom field - Position (0.5, 0) AnchorPoint (0.5, 0), Size (0.964, 0.05), Visible = false
		RoomCustomField = e(UI.TextBox, {
			Text = "",
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromScale(0.9636363, 0.05),
			Position = UDim2.fromScale(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
			Visible = false,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Players info panel - Position (0.018, 0.0625), Size (0.964, 0.6625)
		PlayersInfo = e(UI.Frame, {
			Size = UDim2.fromScale(0.9636363, 0.6625),
			Position = UDim2.fromScale(0.0181818, 0.0625),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			BorderSizePixel = 0,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),

			-- Players window (scrolling frame for player list)
			PlayersWindow = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, {
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5),
				}),
			}),

			-- Control buttons (hidden by default)
			PasswordInput = e(UI.TextBox, {
				Text = "",
				PlaceholderText = "Password",
				Size = UDim2.fromScale(0.396, 0.09),
				Position = UDim2.fromScale(0, 0.91),
				BackgroundColor3 = Color3.fromRGB(35, 35, 35),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),

			KickButton = e(UI.TextButton, {
				Text = "Kick",
				Size = UDim2.fromScale(0.151, 0.09),
				Position = UDim2.fromScale(0.41, 0.91),
				BackgroundColor3 = Color3.fromRGB(150, 50, 50),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),

			TransferHostButton = e(UI.TextButton, {
				Text = "Transfer Host",
				Size = UDim2.fromScale(0.377, 0.09),
				Position = UDim2.fromScale(0.623, 0.91),
				BackgroundColor3 = Color3.fromRGB(70, 120, 180),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),
		}),

		-- Song info with rate controls - Position (0.018, 0.7375), Size (0.964, 0.1625)
		SongInfo = e(MultiplayerSongInfo, {
			size = UDim2.fromScale(0.9636363, 0.1625),
			position = UDim2.fromScale(0.0181818, 0.7375),
		}),

		-- Leave/Join room button - Position (0.02, 0.913), Size (0.724, 0.075), Visible = false
		LeaveJoinRoom = e(UI.TextButton, {
			Text = "Create Room",
			Size = UDim2.fromScale(0.724, 0.075),
			Position = UDim2.fromScale(0.02, 0.913),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 20,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			BorderSizePixel = 2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Active = false,
			Selectable = false,
			Visible = false,
			[React.Event.MouseButton1Click] = function()
				warn("Create/Join room - not implemented")
			end,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),
	})
end

return MultiplayerPanel
