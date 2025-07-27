local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local container = script.Parent:WaitForChild("SongButtonContainer")
local listLayout = container:WaitForChild("List")

local ScreenChief = require(ReplicatedStorage.Modules.ScreenChief)
local templates = ScreenChief:GetTemplates("SongSelect")
local songTemplate = templates:FindFirstChild("SongButton")

local Transient = require(ReplicatedStorage.State.Transient)
local SongDatabase = require(ReplicatedStorage:WaitForChild("SongDatabase"))

local SPUtil = require(ReplicatedStorage.Shared.SPUtil)

-- Helper to clamp text width using MaxVisibleGraphemes
local function calculateVisibleGraphemes(text, textSize, font, maxWidth)
	for i = 1, string.len(text) do
		local substring = string.sub(text, 1, i)
		local textDimensions = TextService:GetTextSize(substring, textSize, font, Vector2.new(math.huge, math.huge))
		if textDimensions.X > maxWidth then
			return i - 1
		end
	end
	return string.len(text) + 1
end

-- Bind click handler to update Transient state
local function hookButton(button, id)
	button.MouseButton1Click:Connect(function()
		Transient.song.selected:set(id)
	end)
	
	
	SPUtil:attach_sound(button, "Select")
end

-- Creates a single UI button for a song
local function createSongButton(songData)
	local button = songTemplate:Clone()
	button.Visible = true
	button.BackgroundColor3 = songData.Color
	button.SongID.Value = songData.ID
	button.Parent = container

	-- Build text
	local text = string.format(
		"[%s] %s - %s",
		math.floor(songData.Difficulty + 0.5),
		songData.ArtistName or "Unknown",
		songData.SongName or "Unknown"
	)

	hookButton(button, songData.ID)

	-- Defer setting text so AbsoluteSize is correct
	task.defer(function()
		local maxWidth = button.AbsoluteSize.X
		local maxGraphemes = calculateVisibleGraphemes(text, button.TextSize, button.Font, maxWidth)

		button.Text = text
		button.MaxVisibleGraphemes = maxGraphemes
	end)

	-- Expand container scroll area
	container.CanvasSize += UDim2.fromOffset(0, button.Size.Y.Offset)
end

-- When SongDatabase adds a song, make a button for it
SongDatabase.SongAdded.Event:Connect(function(songData)
	createSongButton(songData)
end)
