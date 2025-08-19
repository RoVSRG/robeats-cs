local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Transient = require(game.ReplicatedStorage.State.Transient)
local Pfp = require(game.ReplicatedStorage.Shared.Pfp)
local Color = require(game.ReplicatedStorage.Shared.Color)

local Container = script.Parent.Players
local Loading = script.Parent.Loading

local Remotes = game.ReplicatedStorage.Remotes

print("Watching song hash changes...")

local DEBOUNCE = 0.8

function updateLeaderboard(hash)
	Loading.Visible = false

	local slot = ScreenChief:GetTemplates("SongSelect"):FindFirstChild("Slot")

	local response = Remotes.Functions.GetLeaderboard:InvokeServer(hash)

	if response.success then
		local result = response.result
		local leaderboard = result.leaderboard
		local best = result.best

		local bestText: TextLabel = script.Parent.best

		if best then
			bestText.Text = string.format("Best: %0.2f SR | %0.2f%% | %0.2fx", best.rating, best.accuracy, best.rate / 100)
		else
			bestText.Text = "No Best Score"
		end

		for i, entry in ipairs(leaderboard) do
			local playerFrame = slot:Clone()
			playerFrame.LayoutOrder = i

			playerFrame.Image.Image = Pfp.getPfp(entry["user_id"])

			local data = playerFrame:FindFirstChild("Data")

			data.Name = "Player" .. i
			data.Player.Text = "#" .. tostring(i) .. ". " .. entry["player_name"]
			data.Primary.PrimaryText.Text = string.format("Rating: %0.2f | Accuracy: %0.2f%%", entry["rating"], entry["accuracy"])
			data.Primary.Rate.Text = string.format("%0.2fx", entry["rate"] / 100)
			data.Primary.Rate.BackgroundColor3 = Color.calculateRateColor(entry["rate"])

			data.Spread.Text = Color.getSpreadRichText(
				entry["marvelous"],
				entry["perfect"],
				entry["great"],
				entry["good"],
				entry["bad"],
				entry["miss"]
			)

			if entry["user_id"] == game.Players.LocalPlayer.UserId then
				data.Player.TextColor3 = Color3.fromRGB(62, 184, 255)
			end

			playerFrame.Parent = Container
		end
	else
		warn("Failed to fetch leaderboard: " .. response.error)
	end
end

Transient.song.hash:on(function(hash)
	Loading.Visible = true
	script.Parent.best.Text = "Loading..."

	for _, child in Container:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	task.delay(DEBOUNCE, function()
		if hash ~= Transient.song.hash:get() then
			return
		end

		updateLeaderboard(hash)
	end)
end)
