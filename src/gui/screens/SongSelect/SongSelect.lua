local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local L = require(ReplicatedStorage.Components.LayoutUtils)

local ComponentsFolder = script.Parent.Components

local SongList = require(ComponentsFolder.SongList.SongList)
local SongInfoPanel = require(ComponentsFolder.SongInfoPanel)
local LeaderboardPanel = require(ComponentsFolder.LeaderboardPanel)
local MultiplayerPanel = require(ComponentsFolder.MultiplayerPanel)
local ModsButton = require(ComponentsFolder.ModsButton)
local OptionsButton = require(ComponentsFolder.OptionsButton)
local UnrankedDisclaimer = require(ComponentsFolder.UnrankedDisclaimer)

local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Transient = require(ReplicatedStorage.State.Transient)
local SPUtil = require(ReplicatedStorage.Shared.SPUtil)
local useTransient = require(ReplicatedStorage.hooks.useTransient)

local e = React.createElement

--[[
	SongSelect - Main song selection screen

	Complete 1:1 implementation with virtual scrolling for 1,500+ songs
]]
local function SongSelect()
	local screenContext = React.useContext(ScreenContext)
	local backHover, setBackHover = React.useState(false)
	local playHover, setPlayHover = React.useState(false)

	local selectedSongId = useTransient("song.selected")

	-- Load all songs on mount
	React.useEffect(function()
		if not SongDatabase.IsLoaded then
			SongDatabase:LoadAllSongs()
		end
	end, {})

	-- Check if selected song is unranked
	local isUnranked = React.useMemo(function()
		if selectedSongId then
			local songData = SongDatabase:GetSongByKey(selectedSongId)
			return songData and songData.Ranked == false
		end
		return false
	end, { selectedSongId })

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
			Size = UDim2.fromOffset(831, 433),
			BackgroundTransparency = 1,
		}, {
			-- Horizontal layout for 3 columns
			Layout = L.HList({ padding = 5 }),

			-- Column 1: Song list (35% width)
			SongList = e(SongList, {
				size = UDim2.new(0.35, 0, 1, 0),
				viewportHeight = 442,
			}),

			-- Column 2: Leaderboard + SongInfo vertical split (29% width)
			Column2 = e(UI.Frame, {
				Size = UDim2.new(0.29, 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, {
				-- Vertical layout for split
				Layout = L.VList({ padding = 5 }),

				-- Leaderboard (top 66%)
				LeaderboardPanel = e(LeaderboardPanel, {
					size = UDim2.new(1, 0, 0.66, 0),
				}),

				-- SongInfo (bottom 34%)
				SongInfoPanel = e(SongInfoPanel, {
					size = UDim2.new(1, 0, 0.34, 0),
				}),
			}),

			-- Column 3: Multiplayer panel (35% width)
			MultiplayerPanel = e(MultiplayerPanel, {
				size = UDim2.new(0.35, 0, 1, 0),
			}),

			-- Back button (bottom-left within container)
			BackButton = e(UI.TextButton, {
				Text = "Back",
				Size = UDim2.fromScale(0.074, 0.075),
				Position = UDim2.fromScale(0.006, 0.913),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = backHover and Color3.fromRGB(209, 57, 57) or Color3.fromRGB(199, 47, 47),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
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

			-- Play button (bottom within container)
			PlayButton = e(UI.TextButton, {
				Text = "Play",
				Size = UDim2.fromScale(0.324, 0.075),
				Position = UDim2.fromScale(0.324, 0.913),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = playHover and Color3.fromRGB(70, 190, 83) or Color3.fromRGB(60, 180, 73),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 16,
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

			-- Mods button (middle bottom)
			Mods = e(ModsButton, {
				size = UDim2.fromScale(0.112, 0.055),
				position = UDim2.fromScale(0.528, 0.683),
			}),

			-- Options button (middle bottom)
			Options = e(OptionsButton, {
				size = UDim2.fromScale(0.287, 0.055),
				position = UDim2.fromScale(0.354, 0.683),
			}),

			-- Unranked disclaimer (conditional)
			UnrankedDisclaimerBanner = isUnranked and e(UnrankedDisclaimer, {
				position = UDim2.fromScale(0.08, 0.85),
				size = UDim2.fromOffset(700, 40),
				visible = true,
			}),
		}),
	})
end

return SongSelect
