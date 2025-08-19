local ScreenChief = require(game:GetService("ReplicatedStorage").Modules.ScreenChief)
local Time = require(game:GetService("ReplicatedStorage").Libraries.Time)
local SongDatabase = require(game:GetService("ReplicatedStorage").SongDatabase)

local Pfp = require(game.ReplicatedStorage.Shared.Pfp)

local GetGlobalLeaderboard = game:GetService("ReplicatedStorage").Remotes.Functions.GetGlobalLeaderboard

local SlotTemplate = ScreenChief:GetTemplates("GlobalRanking"):FindFirstChild("Slot")

if not SongDatabase.IsLoaded then
	SongDatabase.Loaded.Event:Wait()
end

local function refreshTopPlayers()
	local response = GetGlobalLeaderboard:InvokeServer()

	if not response.success then
		warn(response.error)
		return
	end

	local container = script.Parent.Players
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	container.CanvasSize = UDim2.new(0, 0, 0, 0)

	local result = response.result
	local players = result.players

	for i, player in players do
		local slotInstance = SlotTemplate:Clone()
		local data = slotInstance.Data

		-- TODO: Fill in these fields with appropriate data
		data.Player.Text = "#" .. i .. ". " .. player.name -- Player name
		data.Primary.PrimaryText.Text =
			string.format("Accuracy: %0.2f%% | # Played: %d", player.accuracy, player.playCount) -- Primary text
		data.Primary.Rating.Text = string.format("%0.2f", player.rating) -- Rating/score value
		data.ExtraData.Text = "" -- Additional information

		-- Set player image if available
		slotInstance.Image.Image = Pfp.getPfp(player.userId)

		slotInstance.Parent = container

		container.CanvasSize += UDim2.new(0, 0, 0, slotInstance.Size.Y.Offset + container.UIListLayout.Padding.Offset)
	end
end

script.Parent.BackButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("MainMenu")
end)

Time.setInterval(refreshTopPlayers, 60)
refreshTopPlayers()
