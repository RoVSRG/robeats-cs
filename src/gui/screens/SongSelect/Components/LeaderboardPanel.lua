local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local useTransient = require(ReplicatedStorage.hooks.useTransient)
local Transient = require(ReplicatedStorage.State.Transient)
local SongDatabase = require(ReplicatedStorage.SongDatabase)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local GetLeaderboard = ReplicatedStorage.Remotes.Functions.GetLeaderboard

-- Toggle states for future implementation
local showLocalScores = false
local ratingFilter = "Rating" -- "Rating", "Friends", "All"

--[[
	LeaderboardPanel - Displays leaderboard for selected song

	Subscribes to Transient.song.selected and fetches scores
]]
local function LeaderboardPanel(props)
	local selectedSongId = useTransient("song.selected")
	local leaderboardData, setLeaderboardData = useState(nil)
	local isLoading, setIsLoading = useState(false)

	-- Fetch leaderboard when song changes
	useEffect(function()
		if not selectedSongId then
			setLeaderboardData(nil)
			return
		end

		setIsLoading(true)

		-- Get song hash for leaderboard fetch
		local songData = SongDatabase:GetSongByKey(selectedSongId)
		if not songData or not songData.MD5Hash then
			setIsLoading(false)
			return
		end

		-- Debounce to avoid spamming server
		local debounceTime = 0.8
		task.delay(debounceTime, function()
			-- Check if song is still selected
			if Transient.song.selected:get() ~= selectedSongId then
				return
			end

			-- Fetch leaderboard from server
			local _, response = pcall(function()
				return GetLeaderboard:InvokeServer(songData.MD5Hash)
			end)

			print("Leaderboard response:", response, response and response.result and #response.result.leaderboard)

			if response and response.success and response.result then
				setLeaderboardData(response.result)
			else
				setLeaderboardData(nil)
			end

			setIsLoading(false)
		end)
	end, { selectedSongId })

	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(0.28691363, 0.6625),
		Position = props.position or UDim2.fromScale(0.35406363, 0.0125),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),

		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		-- Header
		-- Header = e(UI.TextLabel, {
		-- 	Text = "Leaderboard",
		-- 	Size = UDim2.new(1, 0, 0, 25),
		-- 	BackgroundTransparency = 1,
		-- 	TextColor3 = Color3.fromRGB(255, 255, 255),
		-- 	TextSize = 18,
		-- 	TextXAlignment = Enum.TextXAlignment.Left,
		-- 	Font = UI.Theme.fonts.bold,
		-- 	LayoutOrder = 1,
		-- }),

		-- Loading state
		Loading = isLoading and e(UI.TextLabel, {
			Text = "Loading...",
			Size = UDim2.fromScale(1, 0.8),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 3,
		}),

		-- No selection state
		NoSelection = not selectedSongId and not isLoading and e(UI.TextLabel, {
			Text = "Select a song to view leaderboard",
			Size = UDim2.fromScale(1, 0.8),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 3,
		}),

		-- Leaderboard entries (reduced height to make room for bottom controls)
		Entries = leaderboardData and leaderboardData.leaderboard and e("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -90),
			Position = UDim2.new(0, 0, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		}, {
			UI.FlexItem({ Mode = Enum.UIFlexMode.Fill }),

			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3),
			}),

			-- Render top entries (archive-style slots)
			Entries = React.createElement(
				React.Fragment,
				nil,
				(function()
					local entries = {}
					local leaderboard = leaderboardData.leaderboard or {}

					for i, entry in ipairs(leaderboard) do
						if i <= 10 then -- Show top 10
							local isLocalPlayer = tostring(entry.user_id) == tostring(game.Players.LocalPlayer.UserId)
							local rate = (tonumber(entry.rate) or 100) / 100

							entries["Entry_" .. i] = e(UI.Frame, {
								Size = UDim2.new(1, 0, 0, 45),
								BackgroundColor3 = Color3.fromRGB(20, 20, 20),
								BackgroundTransparency = 0.85,
								BorderSizePixel = 2,
								BorderColor3 = Color3.fromRGB(27, 42, 53),
								LayoutOrder = i,
							}, {
								Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 9) }),
								Padding = e(UI.UIPadding, {
									PaddingLeft = UDim.new(0, 6),
									PaddingRight = UDim.new(0, 6),
									PaddingTop = UDim.new(0, 4),
									PaddingBottom = UDim.new(0, 4),
								}),

								-- Avatar thumbnail
								Avatar = e(UI.ImageLabel, {
									Size = UDim2.fromOffset(31, 31),
									Position = UDim2.fromScale(0, 0.5),
									AnchorPoint = Vector2.new(0, 0.5),
									Image = entry.user_id and string.format(
										"rbxthumb://type=AvatarHeadShot&id=%s&w=150&h=150",
										entry.user_id
									) or "",
									BackgroundColor3 = Color3.fromRGB(30, 30, 30),
								}, {
									Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
								}),

								-- Data container
								Data = e(UI.Frame, {
									Size = UDim2.new(1, -40, 1, 0),
									Position = UDim2.fromOffset(38, 0),
									BackgroundTransparency = 1,
								}, {
									-- Player name with rank
									Player = e(UI.TextLabel, {
										Text = string.format("%d. %s", i, entry.player_name or "Unknown"),
										Size = UDim2.new(0.7, 0, 0, 14),
										Position = UDim2.fromScale(0, 0.08),
										BackgroundTransparency = 1,
										TextColor3 = isLocalPlayer and Color3.fromRGB(62, 184, 255)
											or Color3.fromRGB(214, 214, 214),
										TextSize = 13,
										TextScaled = false,
										TextXAlignment = Enum.TextXAlignment.Left,
										TextStrokeTransparency = 0,
										Font = Enum.Font.GothamBold,
									}),

									-- Primary stats row
									Primary = e(UI.Frame, {
										Size = UDim2.new(1, 0, 0, 13),
										Position = UDim2.fromScale(0, 0.48),
										BackgroundTransparency = 1,
									}, {
										Layout = e(UI.UIListLayout, {
											FillDirection = Enum.FillDirection.Horizontal,
											VerticalAlignment = Enum.VerticalAlignment.Center,
											Padding = UDim.new(0, 6),
										}),

										-- Rating/Accuracy text
										PrimaryText = e(UI.TextLabel, {
											Text = string.format(
												"%.2f SR | %.2f%%",
												tonumber(entry.rating) or 0,
												tonumber(entry.accuracy) or 0
											),
											Size = UDim2.fromOffset(120, 13),
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(255, 255, 255),
											TextSize = 10,
											TextXAlignment = Enum.TextXAlignment.Left,
											TextStrokeTransparency = 0,
											Font = Enum.Font.GothamMedium,
											LayoutOrder = 1,
										}),

										-- Rate badge
										Rate = rate ~= 1
											and e(UI.TextLabel, {
												Text = string.format("%.2fx", rate),
												Size = UDim2.fromOffset(31, 12),
												BackgroundColor3 = Color3.fromRGB(158, 0, 63),
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextSize = 9,
												Font = Enum.Font.GothamBold,
												LayoutOrder = 2,
											}, {
												Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
											}),
									}),

									-- Score display
									Score = e(UI.TextLabel, {
										Text = string.format("%d", tonumber(entry.score) or 0),
										Size = UDim2.new(0.4, 0, 0, 10),
										Position = UDim2.new(1, 0, 0.08, 0),
										AnchorPoint = Vector2.new(1, 0),
										BackgroundTransparency = 1,
										TextColor3 = Color3.fromRGB(180, 180, 180),
										TextSize = 10,
										TextXAlignment = Enum.TextXAlignment.Right,
										TextStrokeTransparency = 0,
										Font = Enum.Font.GothamMedium,
									}),
								}),
							})
						end
					end

					return entries
				end)()
			),
		}),

		-- Best score label (bottom-center, absolute positioning)
		BestLabel = leaderboardData and leaderboardData.best and e(UI.TextLabel, {
			Text = string.format(
				"Best: %.2f SR | %.2f%% | %.2fx",
				tonumber(leaderboardData.best.rating) or 0,
				tonumber(leaderboardData.best.accuracy) or 0,
				(tonumber(leaderboardData.best.rate) or 100) / 100
			),
			Size = UDim2.new(0.66, 0, 0, 20),
			Position = UDim2.new(0.5, 0, 1, -25),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 2,
		}),

		-- Local toggle button (bottom-left, hidden initially)
		LocalToggle = false and e(UI.TextButton, {
			Text = "View Local Scores",
			Size = UDim2.new(0.277, 0, 0, 22),
			Position = UDim2.new(0.01, 0, 1, -24),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 10,
			Font = UI.Theme.fonts.body,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Visible = false,
			[React.Event.MouseButton1Click] = function()
				-- Toggle local/online scores (future implementation)
				warn("Local scores toggle - not implemented")
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
		}),

		-- Rating toggle button (bottom-right, hidden initially)
		RatingToggle = false and e(UI.TextButton, {
			Text = "Rating ▼",
			Size = UDim2.new(0.277, 0, 0, 22),
			Position = UDim2.new(0.99, 0, 1, -24),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 10,
			Font = UI.Theme.fonts.body,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Visible = false,
			[React.Event.MouseButton1Click] = function()
				-- Cycle through rating filters (future implementation)
				warn("Rating filter toggle - not implemented")
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
		}),
	})
end

return LeaderboardPanel
