local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local Game = require(ReplicatedStorage.State.Game)
local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Color = require(ReplicatedStorage.Shared.Color)
local Rating = require(ReplicatedStorage.Calculator.Rating)
local NoteResult = require(ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local HitGraph = require(script.Parent.HitGraph)

local e = React.createElement
local useState = React.useState
local useMemo = React.useMemo
local useContext = React.useContext

-- Archive-exact colors for judgement grades
local JUDGEMENT_COLORS = {
	marvelous = Color3.fromRGB(255, 255, 255),
	perfect = Color3.fromRGB(255, 255, 0),
	great = Color3.fromRGB(0, 255, 0),
	good = Color3.fromRGB(0, 165, 255),
	bad = Color3.fromRGB(255, 0, 255),
	miss = Color3.fromRGB(255, 0, 0),
}

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

-- Calculate unstable rate (standard deviation of hit timing * 10)
local function calculateUnstableRate(hits)
	local timings = {}
	for _, hit in hits do
		if hit.judgement ~= NoteResult.Miss then
			table.insert(timings, hit.time_left)
		end
	end

	if #timings == 0 then
		return 0
	end

	local sum = 0
	for _, t in timings do
		sum += t
	end
	local mean = sum / #timings

	local variance = 0
	for _, t in timings do
		variance += (t - mean) ^ 2
	end

	return math.sqrt(variance / #timings) * 10
end

--[[
	Results - Post-gameplay results screen
]]
local function Results()
	local screenContext = useContext(ScreenContext)
	local retryHover, setRetryHover = useState(false)
	local backHover, setBackHover = useState(false)

	local results = Game.results

	if not results then
		React.useEffect(function()
			screenContext.switchScreen("SongSelect")
		end, {})
		return nil
	end

	local songData = useMemo(function()
		if results.songKey then
			return SongDatabase:GetSongByKey(results.songKey)
		end
		return nil
	end, { results.songKey })

	-- Colors
	local gradeColor = GRADE_COLORS[results.grade] or GRADE_COLORS.F
	local accuracyColor = Color.calculateDifficultyColor(results.accuracy / 2)
	local ratingColor = Color.calculateDifficultyColor(results.rating)
	local isRainbow = Rating.isRainbow(results.rating)

	-- Rainbow effect for high ratings
	local rainbowHue, setRainbowHue = useState(0)
	React.useEffect(function()
		if not isRainbow then
			return
		end

		local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
			setRainbowHue(function(prev)
				local newHue = prev + 0.04 * dt * 60
				if newHue > 1 then
					newHue = newHue - 1
				end
				return newHue
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, { isRainbow })

	local displayRatingColor = isRainbow and Color3.fromHSV(rainbowHue, 0.35, 1) or ratingColor

	-- Calculated stats
	local unstableRate = useMemo(function()
		return calculateUnstableRate(results.hits or {})
	end, { results.hits })

	local meanColor = useMemo(function()
		local mean = math.abs(results.mean or 0)
		if mean < 10 then
			return Color3.fromRGB(100, 255, 100)
		elseif mean < 25 then
			return Color3.fromRGB(255, 255, 100)
		elseif mean < 50 then
			return Color3.fromRGB(255, 180, 50)
		else
			return Color3.fromRGB(255, 100, 100)
		end
	end, { results.mean })

	-- Total judgements for graph bars
	local totalJudgements = (results.marvelous or 0)
		+ (results.perfect or 0)
		+ (results.great or 0)
		+ (results.good or 0)
		+ (results.bad or 0)
		+ (results.miss or 0)

	local function getGraphWidth(count)
		if totalJudgements == 0 then
			return 0
		end
		return count / totalJudgements
	end

	-- Helper: judgement row with graph bar (same style as gameplay)
	local function JudgementRow(props)
		return e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			LayoutOrder = props.order,
		}, {
			Label = e(UI.TextLabel, {
				Text = props.label,
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = props.color,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Value = e(UI.TextLabel, {
				Text = tostring(props.count),
				Size = UDim2.new(0.5, 0, 1, 0),
				Position = UDim2.fromScale(0.5, 0),
				BackgroundTransparency = 1,
				TextColor3 = props.color,
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2,
			}),
			-- Graph bar behind (gameplay style)
			Graph = e(UI.Frame, {
				Size = UDim2.new(getGraphWidth(props.count), 0, 1, 0),
				Position = UDim2.fromScale(1, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = props.color,
				BackgroundTransparency = 0.6,
				ZIndex = 1,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),
		})
	end

	-- Helper: stat row
	local function StatRow(props)
		return e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			LayoutOrder = props.order,
		}, {
			Label = e(UI.TextLabel, {
				Text = props.label,
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 13,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Value = e(UI.TextLabel, {
				Text = props.value,
				Size = UDim2.new(0.5, 0, 1, 0),
				Position = UDim2.fromScale(0.5, 0),
				BackgroundTransparency = 1,
				TextColor3 = props.color or Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})
	end

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
		-- Main container with vertical flex layout
		Container = e(UI.Frame, {
			Size = UDim2.fromOffset(660, 560),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(25, 25, 30),
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 16) }),
			Padding = e(UI.UIPadding, {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly,
				Padding = UDim.new(0, 12),
			}),

			-- Header: Player name + song info
			Header = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 2),
				}),
				Title = e(UI.TextLabel, {
					Text = string.format("%s's Play Stats", Players.LocalPlayer.Name),
					Size = UDim2.new(1, 0, 0, 24),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 30,
					Font = Enum.Font.GothamBold,
				}),
				SongInfo = songData and e(UI.TextLabel, {
					Text = string.format(
						"%s - %s  [%.2fx]",
						songData.ArtistName or "Unknown",
						songData.SongName or "Unknown",
						(results.rate or 100) / 100
					),
					Size = UDim2.new(1, 0, 0, 18),
					TextColor3 = Color3.fromRGB(150, 150, 150),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
				}),
			}),

			-- Rating Hero (prominent display)
			RatingHero = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 80),
				BackgroundColor3 = Color3.fromRGB(35, 35, 40),
				LayoutOrder = 2,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 12) }),
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 30),
				}),

				-- Grade
				GradeFrame = e(UI.Frame, {
					Size = UDim2.fromOffset(90, 70),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, {
					Grade = e(UI.TextLabel, {
						Text = results.grade or "F",
						Size = UDim2.new(1, 0, 0, 50),
						TextColor3 = gradeColor,
						TextSize = 56,
						Font = Enum.Font.GothamBold,
					}),
					Accuracy = e(UI.TextLabel, {
						Text = string.format("%.2f%%", results.accuracy or 0),
						Size = UDim2.new(1, 0, 0, 20),
						Position = UDim2.fromOffset(0, 50),
						TextColor3 = accuracyColor,
						TextSize = 16,
						Font = Enum.Font.GothamBold,
					}),
				}),

				-- Rating (hero element)
				RatingFrame = e(UI.Frame, {
					Size = UDim2.fromOffset(180, 70),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					UI.Layout({
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					Label = e(UI.TextLabel, {
						Text = "RATING",
						Size = UDim2.new(1, 0, 0, 16),
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 12,
						Font = Enum.Font.GothamMedium,
						LayoutOrder = 1,
					}),
					Value = e(UI.TextLabel, {
						Text = string.format("%.2f", results.rating or 0),
						Size = UDim2.new(1, 0, 0, 30),
						Position = UDim2.fromOffset(0, 16),
						TextColor3 = displayRatingColor,
						TextSize = 30,
						Font = Enum.Font.GothamBold,
						LayoutOrder = 2,
					}),
				}),

				-- Score
				ScoreFrame = e(UI.Frame, {
					Size = UDim2.fromOffset(140, 70),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, {
					UI.Layout({
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					Label = e(UI.TextLabel, {
						Text = "SCORE",
						Size = UDim2.new(1, 0, 0, 16),
						TextColor3 = Color3.fromRGB(150, 150, 150),
						TextSize = 12,
						Font = Enum.Font.GothamMedium,
						LayoutOrder = 1,
					}),
					Value = e(UI.TextLabel, {
						Text = string.format("%d", results.score or 0),
						Size = UDim2.new(1, 0, 0, 30),
						Position = UDim2.fromOffset(0, 20),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 24,
						Font = Enum.Font.GothamBold,
						LayoutOrder = 2,
					}),
				}),
			}),

			-- Stats Row (horizontal layout)
			StatsRow = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 140),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 12),
				}),

				-- Judgements panel (with graph bars)
				JudgementsPanel = e(UI.Frame, {
					Size = UDim2.fromOffset(200, 140),
					BackgroundColor3 = Color3.fromRGB(35, 35, 40),
					LayoutOrder = 1,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 10) }),
					Padding = e(UI.UIPadding, {
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8),
					}),
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						VerticalFlex = Enum.UIFlexAlignment.Fill,
						Padding = UDim.new(0, 2),
					}),

					Row1 = e(JudgementRow, {
						label = "Marvelous",
						count = results.marvelous or 0,
						color = JUDGEMENT_COLORS.marvelous,
						order = 1,
					}),
					Row2 = e(
						JudgementRow,
						{ label = "Perfect", count = results.perfect or 0, color = JUDGEMENT_COLORS.perfect, order = 2 }
					),
					Row3 = e(
						JudgementRow,
						{ label = "Great", count = results.great or 0, color = JUDGEMENT_COLORS.great, order = 3 }
					),
					Row4 = e(
						JudgementRow,
						{ label = "Good", count = results.good or 0, color = JUDGEMENT_COLORS.good, order = 4 }
					),
					Row5 = e(
						JudgementRow,
						{ label = "Bad", count = results.bad or 0, color = JUDGEMENT_COLORS.bad, order = 5 }
					),
					Row6 = e(
						JudgementRow,
						{ label = "Miss", count = results.miss or 0, color = JUDGEMENT_COLORS.miss, order = 6 }
					),
				}),

				-- Stats panel
				StatsPanel = e(UI.Frame, {
					Size = UDim2.fromOffset(180, 140),
					BackgroundColor3 = Color3.fromRGB(35, 35, 40),
					LayoutOrder = 2,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 10) }),
					Padding = e(UI.UIPadding, {
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
						PaddingTop = UDim.new(0, 12),
						PaddingBottom = UDim.new(0, 12),
					}),
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 6),
					}),

					Row1 = e(StatRow, {
						label = "Max Combo",
						value = tostring(results.maxCombo or 0),
						color = Color3.fromRGB(255, 200, 50),
						order = 1,
					}),
					Row2 = e(StatRow, {
						label = "Avg. Offset",
						value = string.format("%.1f ms", results.mean or 0),
						color = meanColor,
						order = 2,
					}),
					Row3 = e(
						StatRow,
						{ label = "Unstable Rate", value = string.format("%.2f", unstableRate), order = 3 }
					),
					Row4 = e(StatRow, {
						label = "Notes Hit",
						value = string.format("%d/%d", results.notesHit or 0, results.totalNotes or 0),
						order = 4,
					}),
				}),
			}),

			-- Hit Graph
			HitGraphPanel = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 100),
				BackgroundColor3 = Color3.fromRGB(35, 35, 40),
				LayoutOrder = 4,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 10) }),
				Title = e(UI.TextLabel, {
					Text = "Hit Timing",
					Size = UDim2.new(1, 0, 0, 18),
					Position = UDim2.fromOffset(10, 2),
					TextColor3 = Color3.fromRGB(120, 120, 120),
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				GraphContainer = e(UI.Frame, {
					Size = UDim2.new(1, -16, 1, -22),
					Position = UDim2.new(0.5, 0, 1, -4),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
				}, {
					Graph = e(HitGraph, {
						hits = results.hits or {},
						songLength = songData and songData.Length or 0,
						rate = (results.rate or 100) / 100,
					}),
				}),
			}),

			-- Buttons
			ButtonRow = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 45),
				BackgroundTransparency = 1,
				LayoutOrder = 5,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 16),
				}),
				RetryButton = e(UI.TextButton, {
					Text = "Retry",
					Size = UDim2.fromOffset(140, 42),
					BackgroundColor3 = retryHover and Color3.fromRGB(50, 230, 50) or Color3.fromRGB(0, 200, 100),
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 18,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 1,
					[React.Event.MouseButton1Click] = handleRetry,
					[React.Event.MouseEnter] = function()
						setRetryHover(true)
					end,
					[React.Event.MouseLeave] = function()
						setRetryHover(false)
					end,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
				BackButton = e(UI.TextButton, {
					Text = "Back",
					Size = UDim2.fromOffset(140, 42),
					BackgroundColor3 = backHover and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 2,
					[React.Event.MouseButton1Click] = handleBack,
					[React.Event.MouseEnter] = function()
						setBackHover(true)
					end,
					[React.Event.MouseLeave] = function()
						setBackHover(false)
					end,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
			}),
		}),
	})
end

return Results
