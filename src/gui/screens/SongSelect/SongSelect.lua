local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

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

	Layout matches archive_screens/SongSelect exactly:
	- Root: 831x433 px, centered
	- SongSelection: Position (0, 0), Size (0.354, 1.0)
	- Leaderboard: Position (0.354, 0.0125), Size (0.287, 0.6625)
	- SongInfo: Position (0.354, 0.675), Size (0.287, 0.325)
	- MultiplayerInfo: Position (0.642, 0), Size (0.336, 1.0)
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
			return
		end

		SPUtil:attach_sound(rbx, "Select")
		warn("Play button clicked - Gameplay screen not implemented yet")
	end

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Main container: 831x433 px, centered
		Container = e(UI.Frame, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(831, 433),
			BackgroundTransparency = 1,
		}, {
			-- Column 1: SongSelection (left) - Position (0, 0), Size (0.354, 1.0)
			SongSelection = e(SongList, {
				position = UDim2.fromScale(0, 0),
				size = UDim2.fromScale(0.35406363, 1),
			}),

			-- Leaderboard (middle top) - Position (0.354, 0.0125), Size (0.287, 0.6625)
			Leaderboard = e(LeaderboardPanel, {
				position = UDim2.fromScale(0.35406363, 0.0125),
				size = UDim2.fromScale(0.28691363, 0.6625),
			}),

			-- SongInfo (middle bottom) - Position (0.354, 0.675), Size (0.287, 0.325)
			SongInfo = e(SongInfoPanel, {
				position = UDim2.fromScale(0.35406363, 0.675),
				size = UDim2.fromScale(0.28691363, 0.325),
			}),

			-- MultiplayerInfo (right) - Position (0.642, 0), Size (0.336, 1.0)
			MultiplayerInfo = e(MultiplayerPanel, {
				position = UDim2.fromScale(0.64219815, 0),
				size = UDim2.fromScale(0.33575, 1),
			}),

			-- BackButton - Position (0.006, 0.9125), Size (0.074, 0.075)
			BackButton = e(UI.TextButton, {
				Text = "Back",
				Position = UDim2.fromScale(0.00591696, 0.9125),
				Size = UDim2.fromScale(0.07447545, 0.075),
				BackgroundColor3 = backHover and Color3.fromRGB(209, 57, 57) or Color3.fromRGB(199, 47, 47),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 22,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = false,
				BorderSizePixel = 2,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				[React.Event.MouseButton1Click] = handleBack,
				[React.Event.MouseEnter] = function()
					setBackHover(true)
				end,
				[React.Event.MouseLeave] = function()
					setBackHover(false)
				end,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			-- PlayButton - Position (0.648, 0.9125), Size (0.324, 0.075)
			PlayButton = e(UI.TextButton, {
				Text = "Play",
				Position = UDim2.fromScale(0.64830273, 0.9125),
				Size = UDim2.fromScale(0.32378626, 0.075),
				BackgroundColor3 = playHover and Color3.fromRGB(50, 230, 50) or Color3.fromRGB(0, 255, 0),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 22,
				Font = Enum.Font.GothamMedium,
				AutoButtonColor = false,
				BorderSizePixel = 2,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				[React.Event.MouseButton1Click] = handlePlay,
				[React.Event.MouseEnter] = function()
					setPlayHover(true)
				end,
				[React.Event.MouseLeave] = function()
					setPlayHover(false)
				end,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			-- Options button - Position (0.354, 0.683), Size (0.287, 0.055)
			Options = e(OptionsButton, {
				position = UDim2.fromScale(0.354, 0.683),
				size = UDim2.fromScale(0.28697723, 0.05457427),
			}),

			-- Mods button - Position (0.528, 0.683), Size (0.112, 0.055), Visible = false
			Mods = e(ModsButton, {
				position = UDim2.fromScale(0.528, 0.683),
				size = UDim2.fromScale(0.112, 0.055),
				visible = false,
			}),

			-- Unranked disclaimer - Position (0.08, 1.03), Size (705, 40)
			UnrankedDisclaimerBanner = isUnranked and e(UnrankedDisclaimer, {
				position = UDim2.fromScale(0.08039248, 1.0300233),
				size = UDim2.fromOffset(705, 40),
			}),
		}),
	})
end

return SongSelect
