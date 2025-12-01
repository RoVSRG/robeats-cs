local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local RobeatsGameWrapper = require(ReplicatedStorage.Modules.RobeatsGameWrapper)
local Transient = require(ReplicatedStorage.State.Transient)
local Game = require(ReplicatedStorage.State.Game)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useContext = React.useContext

-- Archive-exact colors for judgement grades
local JUDGEMENT_COLORS = {
	marvelous = Color3.fromRGB(255, 255, 255), -- White
	perfect = Color3.fromRGB(255, 255, 0), -- Yellow
	great = Color3.fromRGB(0, 255, 0), -- Green
	good = Color3.fromRGB(0, 165, 255), -- Blue (#00A5FF)
	bad = Color3.fromRGB(255, 0, 255), -- Magenta
	miss = Color3.fromRGB(255, 0, 0), -- Red
}

--[[
	Gameplay - Main gameplay screen

	Archive-accurate HUD layout:
	- MAWindow: Stats panel on right side (157x168px)
	- TimeBar: Progress bar at bottom with pink fill
	- BackButton: Red button below MAWindow
]]
local function Gameplay()
	local screenContext = useContext(ScreenContext)
	local gameWrapperRef = useRef(nil)

	-- Game state
	local gameState, setGameState = useState("loading")
	local isPaused, setIsPaused = useState(false)

	-- Stats state
	local score, setScore = useState(0)
	local accuracy, setAccuracy = useState(100)
	local combo, setCombo = useState(0)
	local maxCombo, setMaxCombo = useState(0)
	local judgements, setJudgements = useState({
		marvelous = 0,
		perfect = 0,
		great = 0,
		good = 0,
		bad = 0,
		miss = 0,
	})
	local progress, setProgress = useState(0)
	local currentTimeMs, setCurrentTimeMs = useState(0)
	local songLengthMs, setSongLengthMs = useState(0)

	-- Initialize game on mount
	useEffect(function()
		local songKey = Transient.song.selected:get()
		local rate = Transient.song.rate:get()

		if not songKey then
			warn("[Gameplay] No song selected, returning to SongSelect")
			screenContext.switchScreen("SongSelect")
			return
		end

		-- Create game wrapper
		local gameWrapper = RobeatsGameWrapper.new()
		gameWrapperRef.current = gameWrapper

		-- Subscribe to events
		local connections = {}

		table.insert(
			connections,
			gameWrapper.stateChanged:Connect(function(newState)
				setGameState(newState)
			end)
		)

		table.insert(
			connections,
			gameWrapper.scoreChanged:Connect(function(stats)
				setScore(stats.score)
				setAccuracy(stats.accuracy)
				setCombo(stats.combo)
				setMaxCombo(stats.maxCombo)
				setJudgements({
					marvelous = stats.marvelous,
					perfect = stats.perfect,
					great = stats.great,
					good = stats.good,
					bad = stats.bad,
					miss = stats.miss,
				})
			end)
		)

		table.insert(
			connections,
			gameWrapper.updated:Connect(function(currentTime, songLength, _, prog)
				setProgress(prog)
				setCurrentTimeMs(currentTime or 0)
				setSongLengthMs(songLength or 0)
			end)
		)

		table.insert(
			connections,
			gameWrapper.songFinished:Connect(function(stats)
				-- Store results for Results screen
				Game.results = stats
				Game.results.songKey = songKey
				Game.results.rate = rate

				-- Small delay before transitioning
				task.delay(1, function()
					screenContext.switchScreen("Results")
				end)
			end)
		)

		-- Load and start song
		local loadSuccess = gameWrapper:loadSong({
			songKey = songKey,
			recordReplay = true,
		})

		if loadSuccess then
			gameWrapper:start()
		else
			warn("[Gameplay] Failed to load song")
			screenContext.switchScreen("SongSelect")
		end

		-- Cleanup on unmount
		return function()
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
			if gameWrapperRef.current then
				gameWrapperRef.current:destroy()
				gameWrapperRef.current = nil
			end
		end
	end, {})

	-- Handle pause input
	useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				local gw = gameWrapperRef.current
				if not gw then
					return
				end

				if gw:getState() == "playing" then
					gw:pause()
					setIsPaused(true)
				elseif gw:getState() == "paused" then
					gw:resume()
					setIsPaused(false)
				end
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	-- Pause menu handlers
	local function handleResume()
		local gw = gameWrapperRef.current
		if gw then
			gw:resume()
			setIsPaused(false)
		end
	end

	local function handleQuit()
		local gw = gameWrapperRef.current
		if gw then
			gw:stop()
		end
		screenContext.switchScreen("SongSelect")
	end

	-- Helper function to format time as M:SS
	local function formatTime(ms)
		local totalSeconds = math.floor(math.max(0, ms) / 1000)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60
		return string.format("%d:%02d", minutes, seconds)
	end

	-- Calculate total notes for graph bars
	local totalJudgements = judgements.marvelous
		+ judgements.perfect
		+ judgements.great
		+ judgements.good
		+ judgements.bad
		+ judgements.miss
	local function getGraphWidth(count)
		if totalJudgements == 0 then
			return 0
		end
		return count / totalJudgements
	end

	-- Helper to create a counter with graph bar (archive structure)
	local function createCounterWithGraph(count, color, yPosition)
		return e(UI.TextLabel, {
			Text = tostring(count),
			Size = UDim2.new(0.933, 0, 0.1, 0),
			Position = UDim2.fromScale(0.033, yPosition),
			BackgroundTransparency = 1,
			TextColor3 = color,
			TextSize = 16,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}, {
			-- Graph bar behind the count
			Graph = e(UI.Frame, {
				Size = UDim2.new(getGraphWidth(count), 0, 1, 0),
				BackgroundColor3 = color,
				BackgroundTransparency = 0.5,
				ZIndex = 1,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
			}),
		})
	end

	-- Helper to create a title label (archive structure)
	local function createTitle(text, color, yPosition)
		return e(UI.TextLabel, {
			Text = text,
			Size = UDim2.new(0.933, 0, 0.1, 0),
			Position = UDim2.fromScale(0.05, yPosition),
			BackgroundTransparency = 1,
			TextColor3 = color,
			TextSize = 16,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextStrokeTransparency = 1,
			ZIndex = 3,
		})
	end

	-- Helper to create a player slot (archive CompeteScreen structure)
	local function createPlayerSlot(slotIndex, playerData)
		local yPosition = (slotIndex - 1) * 0.2 -- 0%, 20%, 40%, 60%, 80%
		local isVisible = playerData ~= nil
		local playerName = playerData and playerData.name or ""
		local playerScore = playerData and playerData.score or 0
		local playerCombo = playerData and playerData.combo or 0
		local playerAccuracy = playerData and playerData.accuracy or 100
		local playerRating = playerData and playerData.rating or 0
		local userId = playerData and playerData.userId

		-- Format stats line: rating | score | accuracy%
		local statsText = string.format("%.2f | %d | %.2f%%", playerRating, playerScore, playerAccuracy)

		-- Get avatar thumbnail URL
		local avatarUrl = userId and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId) or ""

		return e(UI.Frame, {
			Size = UDim2.fromOffset(358, 58),
			Position = UDim2.fromScale(0, yPosition),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25), -- #191919
			Visible = isVisible,
			ZIndex = 10,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

			-- Left frame background
			Frame = e(UI.Frame, {
				Size = UDim2.fromOffset(89, 58),
				Position = UDim2.fromScale(0, 0),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				ZIndex = 0,
			}),

			-- Avatar
			Avatar = e(UI.ImageLabel, {
				Size = UDim2.fromOffset(48, 48),
				Position = UDim2.fromScale(0.014, 0.09),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Image = avatarUrl,
				ZIndex = 11,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
			}),

			-- Player name
			PlayerName = e(UI.TextLabel, {
				Text = playerName,
				Size = UDim2.fromOffset(200, 26),
				Position = UDim2.fromScale(0.229, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextStrokeTransparency = 0,
				TextScaled = true,
				ZIndex = 11,
			}),

			-- Stats (rating | score | accuracy%)
			Stats = e(UI.TextLabel, {
				Text = statsText,
				Size = UDim2.fromOffset(180, 31),
				Position = UDim2.fromScale(0.229, 0.455),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextStrokeTransparency = 0,
				ZIndex = 11,
			}),

			-- Combo
			Combo = e(UI.TextLabel, {
				Text = playerCombo .. "x",
				Size = UDim2.fromOffset(98, 25),
				Position = UDim2.fromScale(0.706, 0.457),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 24,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextStrokeTransparency = 0,
				ZIndex = 11,
			}),
		})
	end

	-- Get local player data for player slot display
	local localPlayer = Players.LocalPlayer
	local localPlayerData = {
		userId = localPlayer.UserId,
		name = localPlayer.DisplayName,
		score = score,
		combo = combo,
		accuracy = accuracy,
		rating = 0, -- TODO: Calculate play rating based on accuracy and song difficulty
	}

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- CompeteScreen: Player slots on left side (archive-accurate)
		-- Position: 0%, 30% from top
		-- Size: 358x403 pixels
		CompeteScreen = e(UI.Frame, {
			Size = UDim2.fromOffset(358, 403),
			Position = UDim2.fromScale(0, 0.3),
			BackgroundTransparency = 1,
			ZIndex = 10,
		}, {
			-- Player slot 1 (local player)
			Player1 = createPlayerSlot(1, localPlayerData),
			-- Player slots 2-5 (for multiplayer - hidden in singleplayer)
			Player2 = createPlayerSlot(2, nil),
			Player3 = createPlayerSlot(3, nil),
			Player4 = createPlayerSlot(4, nil),
			Player5 = createPlayerSlot(5, nil),
		}),

		-- MAWindow: Archive-accurate stats panel (right side)
		-- Position: 58.67% from left, 11.36% from top
		-- Size: 157x168 pixels
		MAWindow = e(UI.Frame, {
			Size = UDim2.fromOffset(157, 168),
			Position = UDim2.fromScale(0.5867, 0.114),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25), -- #191919
			ZIndex = 10,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

			-- Titles frame (left-aligned labels) - overlays Counters
			Titles = e(UI.Frame, {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 11,
			}, {
				TitleCorner = e(UI.UICorner, { CornerRadius = UDim.new(0, 3) }),
				-- "Acc %" label at top
				AccLabel = e(UI.TextLabel, {
					Text = "Acc %",
					Size = UDim2.new(0.933, 0, 0.167, 0),
					Position = UDim2.fromScale(0.033, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(185, 185, 185),
					TextSize = 20,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3,
				}),
				-- Judgement titles
				MarvelousTitle = createTitle("Marvelous", JUDGEMENT_COLORS.marvelous, 0.2),
				PerfectTitle = createTitle("Perfect", JUDGEMENT_COLORS.perfect, 0.333),
				GreatTitle = createTitle("Great", JUDGEMENT_COLORS.great, 0.467),
				GoodTitle = createTitle("Good", JUDGEMENT_COLORS.good, 0.6),
				BadTitle = createTitle("Bad", JUDGEMENT_COLORS.bad, 0.733),
				MissTitle = createTitle("Miss", JUDGEMENT_COLORS.miss, 0.867),
			}),

			-- Counters frame (right-aligned counts with graph bars)
			Counters = e(UI.Frame, {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 10,
			}, {
				-- Accuracy value at top (16.7% height)
				AccValue = e(UI.TextLabel, {
					Text = string.format("%.2f", accuracy),
					Size = UDim2.new(0.933, 0, 0.167, 0),
					Position = UDim2.fromScale(0.033, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextStrokeTransparency = 0,
				}),
				-- Judgement counters with graph bars
				MarvelousCount = createCounterWithGraph(judgements.marvelous, JUDGEMENT_COLORS.marvelous, 0.2),
				PerfectCount = createCounterWithGraph(judgements.perfect, JUDGEMENT_COLORS.perfect, 0.333),
				GreatCount = createCounterWithGraph(judgements.great, JUDGEMENT_COLORS.great, 0.467),
				GoodCount = createCounterWithGraph(judgements.good, JUDGEMENT_COLORS.good, 0.6),
				BadCount = createCounterWithGraph(judgements.bad, JUDGEMENT_COLORS.bad, 0.733),
				MissCount = createCounterWithGraph(judgements.miss, JUDGEMENT_COLORS.miss, 0.867),
			}),
		}),

		-- Back Button (below MAWindow) - archive: Y=1.0476 relative to MAWindow
		BackButton = e(UI.TextButton, {
			Size = UDim2.fromOffset(157, 28),
			Position = UDim2.new(0.5867, -1, 0.114, 176), -- X offset -1 matches archive's -0.56%
			BackgroundColor3 = Color3.fromRGB(255, 0, 4), -- Archive red
			TextColor3 = Color3.fromRGB(0, 0, 0),
			Text = "Back (no save)",
			TextSize = 20,
			Font = Enum.Font.GothamMedium,
			ZIndex = 10,
			[React.Event.MouseButton1Click] = handleQuit,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		-- TimeBar: Archive-accurate progress bar at bottom
		-- Position: Y=98.8%, Height=2.47%
		TimeBar = e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.fromRGB(44, 44, 44), -- #2C2C2C
			BackgroundTransparency = 0.6,
			ZIndex = 10,
		}, {
			-- PosBar: Progress fill (pink #FF0084)
			PosBar = e(UI.Frame, {
				Size = UDim2.fromScale(progress, 1),
				BackgroundColor3 = Color3.fromRGB(255, 0, 132), -- Archive pink
				BackgroundTransparency = 0.4,
			}),
			-- PosText: Time display above bar
			PosText = e(UI.TextLabel, {
				Text = formatTime(currentTimeMs),
				Size = UDim2.new(0.149, 0, 2.94, 0),
				Position = UDim2.new(0.007, 0, -3.24, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextStrokeTransparency = 0,
			}),
		}),

		-- Pause Menu Overlay
		PauseMenu = isPaused and e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			ZIndex = 100,
		}, {
			Container = e(UI.Frame, {
				Size = UDim2.fromOffset(300, 200),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				ZIndex = 101,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 12) }),
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 15),
				}),
				Title = e(UI.TextLabel, {
					Text = "PAUSED",
					Size = UDim2.fromOffset(200, 40),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 28,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 1,
				}),
				ResumeButton = e(UI.TextButton, {
					Text = "Resume",
					Size = UDim2.fromOffset(200, 40),
					BackgroundColor3 = Color3.fromRGB(0, 200, 100),
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 18,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 2,
					[React.Event.MouseButton1Click] = handleResume,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
				QuitButton = e(UI.TextButton, {
					Text = "Quit",
					Size = UDim2.fromOffset(200, 40),
					BackgroundColor3 = Color3.fromRGB(200, 50, 50),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					Font = Enum.Font.GothamBold,
					LayoutOrder = 3,
					[React.Event.MouseButton1Click] = handleQuit,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				}),
			}),
		}),

		-- Loading indicator
		Loading = gameState == "loading" and e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.7,
			ZIndex = 50,
		}, {
			Label = e(UI.TextLabel, {
				Text = "Loading...",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 24,
				Font = Enum.Font.GothamBold,
			}),
		}),
	})
end

return Gameplay
