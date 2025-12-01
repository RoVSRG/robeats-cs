local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local Game = require(ReplicatedStorage.State.Game)
local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Color = require(ReplicatedStorage.Shared.Color)
local Rating = require(ReplicatedStorage.Calculator.Rating)
local SPUtil = require(ReplicatedStorage.Shared.SPUtil)

local e = React.createElement
local useState = React.useState
local useMemo = React.useMemo
local useContext = React.useContext

-- Grade colors
local GRADE_COLORS = {
	SS = Color3.fromRGB(255, 255, 100),
	S = Color3.fromRGB(255, 200, 50),
	A = Color3.fromRGB(0, 255, 100),
	B = Color3.fromRGB(50, 150, 255),
	C = Color3.fromRGB(180, 100, 255),
	D = Color3.fromRGB(255, 100, 100),
	F = Color3.fromRGB(150, 150, 150),
}

--[[
	Results - Post-gameplay results screen

	Displays:
	- Letter grade (SS/S/A/B/C/D/F)
	- Score, accuracy, rating
	- Max combo
	- Judgement breakdown (MA/P/G/GO/B/M)
	- Song info
	- Retry and Back buttons
]]
local function Results()
	local screenContext = useContext(ScreenContext)
	local retryHover, setRetryHover = useState(false)
	local backHover, setBackHover = useState(false)

	-- Get results from Game state
	local results = Game.results

	-- If no results, redirect to song select
	if not results then
		React.useEffect(function()
			screenContext.switchScreen("SongSelect")
		end, {})
		return nil
	end

	-- Get song data
	local songData = useMemo(function()
		if results.songKey then
			return SongDatabase:GetSongByKey(results.songKey)
		end
		return nil
	end, { results.songKey })

	-- Calculate colors
	local gradeColor = GRADE_COLORS[results.grade] or GRADE_COLORS.F
	local accuracyColor = Color.calculateDifficultyColor(results.accuracy / 2)
	local ratingColor = Color.calculateDifficultyColor(results.rating)
	local isRainbow = Rating.isRainbow(results.rating)

	-- Rainbow effect for high ratings
	local rainbowHue, setRainbowHue = useState(0)
	React.useEffect(function()
		if not isRainbow then return end

		local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			setRainbowHue(function(prev)
				local newHue = prev + 0.04 * dt * 60
				if newHue > 1 then newHue = newHue - 1 end
				return newHue
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, { isRainbow })

	local displayRatingColor = isRainbow and Color3.fromHSV(rainbowHue, 0.35, 1) or ratingColor

	local function handleRetry()
		screenContext.switchScreen("Gameplay")
	end

	local function handleBack()
		Game.results = nil
		screenContext.switchScreen("SongSelect")
	end

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(15, 15, 20),
	}, {
		-- Main container
		Container = e(UI.Frame, {
			Size = UDim2.fromOffset(700, 500),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 16) }),

			-- Title
			Title = e(UI.TextLabel, {
				Text = "RESULTS",
				Size = UDim2.new(1, 0, 0, 50),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 28,
				Font = Enum.Font.GothamBold,
			}),

			-- Song info
			SongInfo = songData and e(UI.TextLabel, {
				Text = string.format("%s - %s", songData.ArtistName or "Unknown", songData.SongName or "Unknown"),
				Size = UDim2.new(1, 0, 0, 25),
				Position = UDim2.fromScale(0, 0.1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextSize = 16,
				Font = Enum.Font.GothamMedium,
			}),

			-- Rate display
			RateInfo = e(UI.TextLabel, {
				Text = string.format("Rate: %.2fx", (results.rate or 100) / 100),
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.fromScale(0, 0.15),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
			}),

			-- Grade display (large, center-left)
			GradeContainer = e(UI.Frame, {
				Size = UDim2.fromOffset(200, 200),
				Position = UDim2.fromScale(0.15, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 35, 40),
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 12) }),
				Grade = e(UI.TextLabel, {
					Text = results.grade or "F",
					Size = UDim2.fromScale(1, 0.7),
					Position = UDim2.fromScale(0, 0.1),
					BackgroundTransparency = 1,
					TextColor3 = gradeColor,
					TextSize = 100,
					Font = Enum.Font.GothamBold,
				}),
				AccuracyLabel = e(UI.TextLabel, {
					Text = string.format("%.2f%%", results.accuracy or 0),
					Size = UDim2.fromScale(1, 0.2),
					Position = UDim2.fromScale(0, 0.75),
					BackgroundTransparency = 1,
					TextColor3 = accuracyColor,
					TextSize = 24,
					Font = Enum.Font.GothamBold,
				}),
			}),

			-- Stats panel (center-right)
			StatsPanel = e(UI.Frame, {
				Size = UDim2.fromOffset(250, 200),
				Position = UDim2.fromScale(0.55, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 35, 40),
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 12) }),
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 8),
				}),
				Padding = e(UI.UIPadding, {
					PaddingLeft = UDim.new(0, 20),
					PaddingTop = UDim.new(0, 15),
				}),

				-- Score
				ScoreRow = e(UI.Frame, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, {
					Label = e(UI.TextLabel, {
						Text = "Score",
						Size = UDim2.fromScale(0.4, 1),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 14,
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Value = e(UI.TextLabel, {
						Text = string.format("%d", results.score or 0),
						Size = UDim2.fromScale(0.6, 1),
						Position = UDim2.fromScale(0.4, 0),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 18,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				-- Rating
				RatingRow = e(UI.Frame, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					Label = e(UI.TextLabel, {
						Text = "Rating",
						Size = UDim2.fromScale(0.4, 1),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 14,
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Value = e(UI.TextLabel, {
						Text = string.format("%.2f", results.rating or 0),
						Size = UDim2.fromScale(0.6, 1),
						Position = UDim2.fromScale(0.4, 0),
						BackgroundTransparency = 1,
						TextColor3 = displayRatingColor,
						TextSize = 18,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				-- Max Combo
				ComboRow = e(UI.Frame, {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, {
					Label = e(UI.TextLabel, {
						Text = "Max Combo",
						Size = UDim2.fromScale(0.4, 1),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 14,
						Font = Enum.Font.GothamMedium,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Value = e(UI.TextLabel, {
						Text = string.format("%d", results.maxCombo or 0),
						Size = UDim2.fromScale(0.6, 1),
						Position = UDim2.fromScale(0.4, 0),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(255, 200, 50),
						TextSize = 18,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),
			}),

			-- Judgement breakdown
			JudgementPanel = e(UI.Frame, {
				Size = UDim2.fromOffset(200, 150),
				Position = UDim2.fromScale(0.85, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(35, 35, 40),
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 12) }),
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 4),
				}),
				Padding = e(UI.UIPadding, {
					PaddingLeft = UDim.new(0, 15),
					PaddingTop = UDim.new(0, 10),
				}),
				MA = e(UI.TextLabel, {
					Text = string.format("Marvelous: %d", results.marvelous or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),
				P = e(UI.TextLabel, {
					Text = string.format("Perfect: %d", results.perfect or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(235, 220, 13),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}),
				G = e(UI.TextLabel, {
					Text = string.format("Great: %d", results.great or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(57, 192, 16),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 3,
				}),
				GO = e(UI.TextLabel, {
					Text = string.format("Good: %d", results.good or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(25, 62, 250),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 4,
				}),
				B = e(UI.TextLabel, {
					Text = string.format("Bad: %d", results.bad or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(174, 22, 194),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 5,
				}),
				M = e(UI.TextLabel, {
					Text = string.format("Miss: %d", results.miss or 0),
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(190, 30, 30),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 6,
				}),
			}),

			-- Action buttons
			ButtonContainer = e(UI.Frame, {
				Size = UDim2.new(1, -40, 0, 50),
				Position = UDim2.new(0.5, 0, 1, -20),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
			}, {
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 20),
				}),
				RetryButton = e(UI.TextButton, {
					Text = "Retry",
					Size = UDim2.fromOffset(150, 45),
					BackgroundColor3 = retryHover and Color3.fromRGB(50, 230, 50) or Color3.fromRGB(0, 200, 100),
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 20,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 1,
					[React.Event.MouseButton1Click] = handleRetry,
					[React.Event.MouseEnter] = function() setRetryHover(true) end,
					[React.Event.MouseLeave] = function() setRetryHover(false) end,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
				BackButton = e(UI.TextButton, {
					Text = "Back",
					Size = UDim2.fromOffset(150, 45),
					BackgroundColor3 = backHover and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 2,
					[React.Event.MouseButton1Click] = handleBack,
					[React.Event.MouseEnter] = function() setBackHover(true) end,
					[React.Event.MouseLeave] = function() setBackHover(false) end,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
			}),
		}),
	})
end

return Results
