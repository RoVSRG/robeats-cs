local CollectionService = game:GetService("CollectionService")
local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)

local Templates = ScreenChief:GetTemplates("Options")

local OptionsHandler = {}

function OptionsHandler.createIntOption(name, val, page, incrementVal)
	local option = Templates:FindFirstChild("IntOption"):Clone()
	option.Display.Text = name

	option.Increment.MouseButton1Click:Connect(function()
		val:set(val:get() - incrementVal or 1)
	end)

	option.Decrement.MouseButton1Click:Connect(function()
		val:set(val:get() - incrementVal or 1)
	end)

	val:on(function(val)
		option.ValueDisplay.Text = val
	end)

	option.Parent = page
	option.Visible = true
end

function OptionsHandler.createBoolOption(name, val, page)
    print("[OptionsHandler.lua] created bool optiokn...")
	local clone = Templates:FindFirstChild("BoolOption"):Clone()
	clone.Display.Text = name

	clone.Toggleable.MouseButton1Click:Connect(function()
		val:set(not val:get())
	end)

	val:on(function(newval)
		if newval then
            clone.Toggleable.Text = "TRUE"
			clone.Toggleable.BackgroundColor3 = Color3.fromRGB(90, 170, 113)
		else
            clone.Toggleable.Text = "FALSE"
			clone.Toggleable.BackgroundColor3 = Color3.fromRGB(147, 44, 46)
		end
	end)

    clone.Name = name
	clone.Parent = page
	clone.Visible = true
end

function OptionsHandler.createRadioOption(name, val, page, selection)
	local option = Templates:FindFirstChild("RadioOption"):Clone()
	option.Display.Text = name

	for i = 1, #selection do
		local selectionButton = option.SampleButton:Clone()
		selectionButton.Name = selection[i]
		selectionButton.Text = selection[i]
		CollectionService:AddTag(selectionButton, "Radio_" .. name)
		selectionButton.Parent = option
	end

	for _, button in pairs(CollectionService:GetTagged("Radio_" .. name)) do
		button.MouseButton1Click:Connect(function()
			val:set(button.Name)

			for _, item in pairs(option:GetChildren()) do
				if item:IsA("GuiButton") then
					item.BackgroundTransparency = 0
				end
			end

			button.BackgroundTransparency = 0.6
		end)
	end

	option.Parent = page
	option.Visible = true
end

function OptionsHandler.createMultiselectOption(name, val, page, selection)
	local option = Templates:FindFirstChild("RadioOption"):Clone()
	option.Display.Text = name

	for i = 1, #selection do
		local selectionButton = option.SampleButton:Clone()
		selectionButton.Name = selection[i]
		selectionButton.Text = selection[i]
		CollectionService:AddTag(selectionButton, "Multi_" .. name)
		selectionButton.Parent = option
	end

	for _, button in pairs(CollectionService:GetTagged("Multi_" .. name)) do
		button.MouseButton1Click:Connect(function()
			val:set(not val:get())

			if val:get() then
				option.Toggleable.BackgroundColor3 = Color3.fromRGB(90, 170, 113)
			else
				option.Toggleable.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end)
	end

    option.Parent = page
	option.Visible = true
end

return OptionsHandler
