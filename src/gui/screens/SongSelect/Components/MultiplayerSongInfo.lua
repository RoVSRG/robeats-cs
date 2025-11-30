local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local useTransient = require(ReplicatedStorage.hooks.useTransient)
local useValSetter = require(ReplicatedStorage.hooks.useValSetter)
local Transient = require(ReplicatedStorage.State.Transient)
local SongDatabase = require(ReplicatedStorage.SongDatabase)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

--[[
	MultiplayerSongInfo - Song info panel for multiplayer with rate controls

	Displayed inside MultiplayerInfo panel
	Shows: Song name, difficulty, length, max rating, and rate selector
]]
local function MultiplayerSongInfo(props)
	local selectedSongId = useTransient("song.selected")
	local rate = useTransient("song.rate")
	local setRate = useValSetter(Transient.song.rate)

	local songData, setSongData = useState(nil)

	-- Update song data when selection changes
	useEffect(function()
		if selectedSongId then
			local data = SongDatabase:GetSongByKey(selectedSongId)
			setSongData(data)
		else
			setSongData(nil)
		end
	end, { selectedSongId })

	-- Rate control handlers
	local function incrementRate()
		local newRate = math.min(200, rate + 5)
		setRate(newRate)
	end

	local function decrementRate()
		local newRate = math.max(50, rate - 5)
		setRate(newRate)
	end

	-- Calculate song duration in minutes:seconds
	local songLength = ""
	if songData and songData.SongLength then
		local minutes = math.floor(songData.SongLength / 60)
		local seconds = math.floor(songData.SongLength % 60)
		songLength = string.format("%d:%02d", minutes, seconds)
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.new(0.964, 0, 0.162, 0),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		Position = props.position,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),

		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		}),

		-- Song name
		SongNameInfo = songData and e(UI.TextLabel, {
			Text = songData.SongName or "No Song Selected",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.bold,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
		}),

		-- Difficulty + rating
		SongDiffInfo = songData and e(UI.TextLabel, {
			Text = string.format("Difficulty: %d", songData.Difficulty or 0),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 2,
		}),

		-- Song length
		SongLengthInfo = songData and e(UI.TextLabel, {
			Text = string.format("Length: %s", songLength ~= "" and songLength or "Unknown"),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 3,
		}),

		-- Rate selector
		RateSelector = e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}),

			Label = e(UI.TextLabel, {
				Text = "Rate:",
				Size = UDim2.new(0, 40, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = UI.Theme.fonts.body,
				LayoutOrder = 1,
			}),

			SubtractButton = e(UI.TextButton, {
				Text = "-",
				Size = UDim2.new(0, 28, 0, 28),
				BackgroundColor3 = Color3.fromRGB(57, 57, 57),
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 16,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				[React.Event.MouseButton1Click] = decrementRate,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			RateInfo = e(UI.TextLabel, {
				Text = string.format("%d%%", rate),
				Size = UDim2.new(0, 50, 0, 28),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 12,
				Font = UI.Theme.fonts.body,
				BorderSizePixel = 0,
				LayoutOrder = 3,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			AddButton = e(UI.TextButton, {
				Text = "+",
				Size = UDim2.new(0, 28, 0, 28),
				BackgroundColor3 = Color3.fromRGB(57, 57, 57),
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 16,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = 4,
				[React.Event.MouseButton1Click] = incrementRate,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),

		-- No selection placeholder
		NoSelection = not songData and e(UI.TextLabel, {
			Text = "No song selected",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 12,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 1,
		}),
	})
end

return MultiplayerSongInfo
