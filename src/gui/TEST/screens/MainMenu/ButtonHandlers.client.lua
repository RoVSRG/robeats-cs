local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local CollectionService = game:GetService("CollectionService")

local function handleButtonInteractives()
	for _, element in script.Parent:GetChildren() do
		if element:IsA("ImageButton") then
			CollectionService:AddTag(element, "MenuButton")
		end
	end
	
	for _, button in CollectionService:GetTagged("MenuButton") do
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			button.TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		end)
		
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
			button.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
	end
end

handleButtonInteractives()

-- Song Select
script.Parent.PlayButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("SongSelect")
end)

-- Changelog
script.Parent.ChangelogButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("Changelog")
end)

-- Options
script.Parent.OptionsButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("Options")
end)