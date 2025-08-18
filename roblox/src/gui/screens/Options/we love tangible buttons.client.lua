local CollectionService = game:GetService("CollectionService")

local SettingsSerializer = require(game.ReplicatedStorage.Serialization.SettingsSer)
local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local switchPage = require(script.Parent.SwitchPage)

local SaveSettings = game.ReplicatedStorage.Remotes.Events.SaveSettings

local BackButton = script.Parent.BackButton
local pageButtons = script.Parent.Selections

local function setupPageButtons()
	for _, item in pairs(pageButtons:GetChildren()) do
		if item:IsA("TextButton") then
			CollectionService:AddTag(item, "OptionButton")
		end
	end

	for _, button in pairs(CollectionService:GetTagged("OptionButton")) do
		button.MouseButton1Click:Connect(function()
			switchPage(button.Name)
		end)
	end
end

BackButton.MouseButton1Click:Connect(function()
	SaveSettings:FireServer(SettingsSerializer.get_serialized_opts())
	ScreenChief:Switch("MainMenu")
end)

setupPageButtons()
