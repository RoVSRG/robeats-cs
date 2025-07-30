local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Transient = require(game.ReplicatedStorage.State.Transient)
local Pfp = require(game.ReplicatedStorage.Shared.Pfp)

local Container = script.Parent.Players

local Remotes = game.ReplicatedStorage.Remotes

print("Watching song hash changes...")

local DEBOUNCE = 0.8

function updateLeaderboard(hash)
	local slot = ScreenChief:GetTemplates("SongSelect"):FindFirstChild("Slot")

	for _, child in Container:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local leaderboard = Remotes.Functions.GetLeaderboard:InvokeServer(hash)

	if leaderboard.success then
		for i, entry in ipairs(leaderboard.data) do
			local playerFrame = slot:Clone()
			playerFrame.LayoutOrder = i

			playerFrame.Image.Image = Pfp.getPfp(entry["user_id"])

			local data = playerFrame:FindFirstChild("Data")

			data.Name = "Player" .. i
			data.Player.Text = "#" .. tostring(i) .. ". " .. entry["player_name"]
			data.Primary.PrimaryText.Text = string.format("Rating: %0.2f | Accuracy: %0.2f", entry["rating"], entry["accuracy"])
			data.Primary.Rate.Text = string.format("%0.2fx", entry["rate"] / 100)

			data.Spread.Text = string.format("Spread: %d / %d / %d / %d / %d / %d", 
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
		warn("Failed to fetch leaderboard: " .. leaderboard.error)
	end
end

Transient.song.hash:on(function(hash)
	task.delay(DEBOUNCE, function()
		if hash ~= Transient.song.hash:get() then
			return
		end

		updateLeaderboard(hash)
	end)
end)
