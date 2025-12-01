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
			local success, response = pcall(function()
				return GetLeaderboard:InvokeServer(songData.MD5Hash)
			end)

			if success and response and response.leaderboard then
				setLeaderboardData(response)
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
		Header = e(UI.TextLabel, {
			Text = "Leaderboard",
			Size = UDim2.new(1, 0, 0, 25),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.bold,
			LayoutOrder = 1,
		}),


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
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3),
			}),

			-- Render top entries
			Entries = React.createElement(React.Fragment, nil, (function()
				local entries = {}
				local leaderboard = leaderboardData.leaderboard or {}

				for i, entry in ipairs(leaderboard) do
					if i <= 10 then -- Show top 10
						entries["Entry_" .. i] = e(UI.Frame, {
							Size = UDim2.new(1, -10, 0, 30),
							BackgroundColor3 = Color3.fromRGB(45, 45, 45),
							BorderSizePixel = 0,
							LayoutOrder = i,
						}, {
							Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
							Padding = e(UI.UIPadding, {
								PaddingLeft = UDim.new(0, 8),
								PaddingRight = UDim.new(0, 8),
							}),

							Name = e(UI.TextLabel, {
								Text = string.format("#%d. %s", i, entry.player_name),
								Size = UDim2.new(0.5, 0, 1, 0),
								Position = UDim2.fromScale(0, 0),
								BackgroundTransparency = 1,
								TextColor3 = entry.user_id == game.Players.LocalPlayer.UserId
									and Color3.fromRGB(62, 184, 255)
									or Color3.fromRGB(200, 200, 200),
								TextSize = 12,
								TextXAlignment = Enum.TextXAlignment.Left,
								Font = UI.Theme.fonts.body,
							}),

							Stats = e(UI.TextLabel, {
								Text = string.format("%.2f SR | %.2f%%", entry.rating, entry.accuracy),
								Size = UDim2.new(0.5, 0, 1, 0),
								Position = UDim2.fromScale(0.5, 0),
								BackgroundTransparency = 1,
								TextColor3 = Color3.fromRGB(180, 180, 180),
								TextSize = 11,
								TextXAlignment = Enum.TextXAlignment.Right,
								Font = UI.Theme.fonts.body,
							}),
						})
					end
				end

				return entries
			end)()),
		}),

		-- Best score label (bottom-center, absolute positioning)
		BestLabel = leaderboardData and leaderboardData.best and e(UI.TextLabel, {
			Text = string.format(
				"Best: %.2f SR | %.2f%% | %.2fx",
				leaderboardData.best.rating,
				leaderboardData.best.accuracy,
				leaderboardData.best.rate / 100
			),
			Size = UDim2.new(0.66, 0, 0, 20),
			Position = UDim2.new(0.5, 0, 1, -25),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = UI.Theme.fonts.body,
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
