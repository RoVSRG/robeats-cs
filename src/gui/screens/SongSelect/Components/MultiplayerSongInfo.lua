local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local useTransient = require(ReplicatedStorage.hooks.useTransient)
local useValSetter = require(ReplicatedStorage.hooks.useValSetter)
local Transient = require(ReplicatedStorage.State.Transient)
local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Rating = require(ReplicatedStorage.Calculator.Rating)
local Color = require(ReplicatedStorage.Shared.Color)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

--[[
	MultiplayerSongInfo - Song info panel for multiplayer with rate controls

	Archive structure (MultiplayerInfo/SongInfo):
	- SongNameInfo: Position (0.01887, 0), Size (0.9622641, 0.38461539)
	- MaxRating: Position (0.01887, 0.3587871), Size (0.9622641, 0.17087779)
	- SongDiffInfo: Position (0.01887, 0.5384615), Size (0.9622641, 0.23076923)
	- SongLengthInfo: Position (0.01887, 0.7384615), Size (0.9622641, 0.23076923)
	- RateSelector: Position (0.5849056, 0.4307692), Size (0.3962264, 0.4615384)
		- Subtract: Position (0, 0), Size (0.4761904, 0.5), Red
		- Add: Position (0.523809, 0), Size (0.4761904, 0.5), Green
		- RateInfo: Position (0, 0.6), Size (1, 0.5)
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

	-- Calculate song duration in minutes:seconds (Length is in ms, scaled by rate)
	local songLength = ""
	if songData and songData.Length then
		local lengthSeconds = (songData.Length / 1000) / (rate / 100)
		local minutes = math.floor(lengthSeconds / 60)
		local seconds = math.floor(lengthSeconds % 60)
		songLength = string.format("%d:%02d", minutes, seconds)
	end

	-- Calculate difficulty adjusted by rate using proper multiplier
	local baseDifficulty = songData and (songData.Difficulty or 0) or 0
	local adjustedDifficulty = Rating.getDifficultyMultiplier(rate / 100, baseDifficulty) * baseDifficulty

	-- Calculate max rating (100% accuracy at current rate)
	local maxRating = songData and Rating.calculateRating(rate / 100, 100, baseDifficulty) or 0

	-- Check if rainbow effect should be applied
	local isDifficultyRainbow = Rating.isRainbow(adjustedDifficulty)
	local isMaxRatingRainbow = Rating.isRainbow(maxRating)

	-- Rainbow hue state for cycling effect
	local rainbowHue, setRainbowHue = useState(0)

	-- Rainbow cycling effect
	useEffect(function()
		if not isDifficultyRainbow and not isMaxRatingRainbow then
			return
		end

		local connection = RunService.Heartbeat:Connect(function(dt)
			setRainbowHue(function(prev)
				local newHue = prev + 0.04 * dt * 60 -- ~0.04 per frame at 60fps
				if newHue > 1 then
					newHue = newHue - 1
				end
				return newHue
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, { isDifficultyRainbow, isMaxRatingRainbow })

	-- Calculate colors
	local difficultyColor = isDifficultyRainbow
		and Color3.fromHSV(rainbowHue, 0.35, 1)
		or Color.calculateDifficultyColor(adjustedDifficulty)

	local maxRatingColor = isMaxRatingRainbow
		and Color3.fromHSV(rainbowHue, 0.35, 1)
		or Color.calculateDifficultyColor(maxRating)

	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(0.9636363, 0.1625),
		Position = props.position or UDim2.fromScale(0.0181818, 0.7375),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),

		-- SongNameInfo - Position (0.01887, 0), Size (0.9622641, 0.38461539)
		-- Format: "Map: [difficulty][HARD] artist - title (charter)"
		SongNameInfo = songData and e(UI.TextLabel, {
			Text = string.format(
				"Map: [%d] %s - %s (%s)",
				math.floor((songData.Difficulty or 0) + 0.5),
				songData.ArtistName or "Unknown",
				songData.SongName or "Unknown",
				songData.CharterName or "Unknown"
			),
			Position = UDim2.fromScale(0.01886792, 0),
			Size = UDim2.fromScale(0.9622641, 0.38461539),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextStrokeTransparency = 0.5,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			BorderSizePixel = 0,
		}),

		-- MaxRating - Position (0.01887, 0.3587871), Size (0.9622641, 0.17087779)
		MaxRating = songData and e(UI.TextLabel, {
			Text = string.format("Max Rating: %.2f", maxRating),
			Position = UDim2.fromScale(0.01886819, 0.3587871),
			Size = UDim2.fromScale(0.9622641, 0.17087779),
			BackgroundTransparency = 1,
			TextColor3 = maxRatingColor,
			TextSize = 11,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- SongDiffInfo - Position (0.01887, 0.5384615), Size (0.9622641, 0.23076923)
		SongDiffInfo = songData and e(UI.TextLabel, {
			Text = string.format("Difficulty: %.2f", adjustedDifficulty),
			Position = UDim2.fromScale(0.01886792, 0.5384615),
			Size = UDim2.fromScale(0.9622641, 0.23076923),
			BackgroundTransparency = 1,
			TextColor3 = difficultyColor,
			TextSize = 11,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- SongLengthInfo - Position (0.01887, 0.7384615), Size (0.9622641, 0.23076923)
		SongLengthInfo = songData and e(UI.TextLabel, {
			Text = string.format("Map Length: %s", songLength ~= "" and songLength or "0:00"),
			Position = UDim2.fromScale(0.01886792, 0.7384615),
			Size = UDim2.fromScale(0.9622641, 0.23076923),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			TextStrokeTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- RateSelector - Position (0.5849056, 0.4307692), Size (0.3962264, 0.4615384)
		RateSelector = e(UI.Frame, {
			Position = UDim2.fromScale(0.5849056, 0.4307692),
			Size = UDim2.fromScale(0.3962264, 0.4615384),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			-- Subtract button - Position (0, 0), Size (0.4761904, 0.5), Red
			Subtract = e(UI.TextButton, {
				Text = "-0.05",
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(0.4761904, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 0, 0),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = true,
				BorderSizePixel = 0,
				[React.Event.MouseButton1Click] = decrementRate,
			}),

			-- Add button - Position (0.523809, 0), Size (0.4761904, 0.5), Green
			Add = e(UI.TextButton, {
				Text = "+0.05",
				Position = UDim2.fromScale(0.523809, 0),
				Size = UDim2.fromScale(0.4761904, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 255, 0),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = true,
				BorderSizePixel = 0,
				[React.Event.MouseButton1Click] = incrementRate,
			}),

			-- RateInfo - Position (0, 0.6), Size (1, 0.5)
			RateInfo = e(UI.TextLabel, {
				Text = string.format("Song Rate: %.2fx", rate / 100),
				Position = UDim2.fromScale(0, 0.6),
				Size = UDim2.fromScale(1, 0.5),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextStrokeTransparency = 0.5,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				Font = Enum.Font.GothamMedium,
				BorderSizePixel = 0,
			}),
		}),

		-- No selection placeholder
		NoSelection = not songData and e(UI.TextLabel, {
			Text = "No song selected",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
		}),
	})
end

return MultiplayerSongInfo
