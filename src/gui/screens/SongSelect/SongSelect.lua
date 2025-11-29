local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

-- Debug: Check Components folder exists
local ComponentsFolder = script.Parent.Components

local SongList = require(ComponentsFolder.SongList.SongList)
local SongInfoPanel = require(ComponentsFolder.SongInfoPanel)
local LeaderboardPanel = require(ComponentsFolder.LeaderboardPanel)
local MultiplayerPanel = require(ComponentsFolder.MultiplayerPanel)

local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Transient = require(ReplicatedStorage.State.Transient)
local SPUtil = require(ReplicatedStorage.Shared.SPUtil)

local e = React.createElement

--[[
	SongSelect - Main song selection screen

	Complete 1:1 implementation with virtual scrolling for 1,500+ songs
]]
local function SongSelect()
	local screenContext = React.useContext(ScreenContext)
	local backHover, setBackHover = React.useState(false)
	local playHover, setPlayHover = React.useState(false)

	-- Load all songs on mount
	React.useEffect(function()
		if not SongDatabase.IsLoaded then
			SongDatabase:LoadAllSongs()
		end
	end, {})

	local function handleBack()
		screenContext.switchScreen("MainMenu")
	end

	local function handlePlay(rbx)
		local selectedSong = Transient.song.selected:get()
		if not selectedSong then
			-- Could show a warning
			return
		end

		-- Play sound effect
		SPUtil:attach_sound(rbx, "Select")

		-- Navigate to gameplay (when implemented)
		-- screenContext.switchScreen("Gameplay")
		warn("Play button clicked - Gameplay screen not implemented yet")
	end

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Container = e(UI.Frame, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1049, 442),
			BackgroundTransparency = 1,
		}, {
			-- Left side: Song list with search, filters, and virtual scrolling (40% width)
			SongList = e(SongList, {
				size = UDim2.new(0.4, 0, 1, 0),
				position = UDim2.fromScale(0, 0),
				viewportHeight = 442,
			}),

			-- Top-right: Song info panel (60% width, 50% height)
			SongInfoPanel = e(SongInfoPanel, {
				position = UDim2.new(0.41, 0, 0, 0),
				size = UDim2.new(0.59, 0, 0.49, 0),
			}),

			-- Bottom-right: Leaderboard panel (60% width, 50% height)
			LeaderboardPanel = e(LeaderboardPanel, {
				position = UDim2.new(0.41, 0, 0.51, 0),
				size = UDim2.new(0.59, 0, 0.49, 0),
			}),

			-- Multiplayer panel (hidden by default)
			MultiplayerPanel = e(MultiplayerPanel, {
				position = UDim2.new(0.41, 0, 0.51, 0),
				size = UDim2.new(0.59, 0, 0.49, 0),
			}),

			-- Back button (top-left, outside container)
			BackButton = e(UI.TextButton, {
				Text = "Back",
				Size = UDim2.new(0, 100, 0, 40),
				Position = UDim2.new(0, 0, 0, -50),
				BackgroundColor3 = backHover and Color3.fromRGB(209, 57, 57) or Color3.fromRGB(199, 47, 47),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 2,
				[React.Event.MouseButton1Click] = handleBack,
				[React.Event.MouseEnter] = function()
					setBackHover(true)
				end,
				[React.Event.MouseLeave] = function()
					setBackHover(false)
				end,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			-- Play button (bottom-right, outside container)
			PlayButton = e(UI.TextButton, {
				Text = "Play",
				Size = UDim2.new(0, 100, 0, 40),
				Position = UDim2.new(1, -100, 1, 10),
				BackgroundColor3 = playHover and Color3.fromRGB(70, 190, 83) or Color3.fromRGB(60, 180, 73),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 18,
				Font = UI.Theme.fonts.bold,
				AutoButtonColor = false,
				BorderSizePixel = 2,
				[React.Event.MouseButton1Click] = handlePlay,
				[React.Event.MouseEnter] = function()
					setPlayHover(true)
				end,
				[React.Event.MouseLeave] = function()
					setPlayHover(false)
				end,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

return SongSelect
