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
		Size = props.size or UDim2.new(0.35, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),

		-- Room info label (top)
		RoomInfo = e(UI.TextLabel, {
			Text = "No Multiplayer Session",
			Size = UDim2.new(0.964, 0, 0, 20),
			Position = UDim2.new(0.018, 0, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.bold,
		}),

		-- Room custom field (below room info)
		RoomCustomField = e(UI.TextBox, {
			Text = "",
			PlaceholderText = "Room settings...",
			Size = UDim2.new(0.964, 0, 0, 25),
			Position = UDim2.new(0.018, 0, 0, 25),
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			TextColor3 = Color3.fromRGB(200, 200, 200),
			PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.body,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			e(UI.UIPadding, {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		}),

		-- Players info panel (middle section)
		PlayersInfo = e(UI.Frame, {
			Size = UDim2.new(0.964, 0, 0.662, 0),
			Position = UDim2.new(0.018, 0, 0, 55),
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BorderSizePixel = 0,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
			Padding = e(UI.UIPadding, {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),

			-- Players window (scrolling frame for player list)
			PlayersWindow = e("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -40),
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

				-- Placeholder message
				Placeholder = e(UI.TextLabel, {
					Text = "No active multiplayer session",
					Size = UDim2.new(1, 0, 0, 60),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(120, 120, 120),
					TextSize = 13,
					Font = UI.Theme.fonts.body,
					LayoutOrder = 1,
				}),
			}),

			-- Control buttons at bottom
			PasswordInput = e(UI.TextBox, {
				Text = "",
				PlaceholderText = "Password",
				Size = UDim2.new(0.396, 0, 0, 26),
				Position = UDim2.new(0, 0, 1, -28),
				BackgroundColor3 = Color3.fromRGB(35, 35, 35),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
				TextSize = 11,
				Font = UI.Theme.fonts.body,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
				e(UI.UIPadding, {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),
			}),

			KickButton = e(UI.TextButton, {
				Text = "Kick",
				Size = UDim2.new(0.151, 0, 0, 26),
				Position = UDim2.new(0.41, 0, 1, -28),
				BackgroundColor3 = Color3.fromRGB(150, 50, 50),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),

			TransferHostButton = e(UI.TextButton, {
				Text = "Transfer Host",
				Size = UDim2.new(0.377, 0, 0, 26),
				Position = UDim2.new(0.623, 0, 1, -28),
				BackgroundColor3 = Color3.fromRGB(70, 120, 180),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Visible = false,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),
		}),

		-- Song info with rate controls (bottom section)
		MultiplayerSongInfoPanel = e(MultiplayerSongInfo, {
			size = UDim2.new(0.964, 0, 0.162, 0),
			position = UDim2.new(0.018, 0, 0.737, 0),
		}),

		-- Leave/Join room button (very bottom)
		LeaveJoinRoom = e(UI.TextButton, {
			Text = "Join Room",
			Size = UDim2.new(0.724, 0, 0, 30),
			Position = UDim2.new(0.018, 0, 0.913, 0),
			BackgroundColor3 = Color3.fromRGB(60, 180, 73),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
			Font = UI.Theme.fonts.bold,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = function()
				-- Join/Leave room logic (future implementation)
				warn("Join/Leave room - not implemented")
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),
	})
end

return MultiplayerPanel
