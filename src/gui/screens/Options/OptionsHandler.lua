local CollectionService = game:GetService("CollectionService")
local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)

local Templates = ScreenChief:GetTemplates("Options")

local OptionsHandler = {}
OptionsHandler.__index = OptionsHandler

-- Create a new OptionsHandler instance with its own container frame
function OptionsHandler.new(parent)
	local self = setmetatable({}, OptionsHandler)
	
	-- Create the container frame
	self.container = Instance.new("Frame")
	self.container.Size = UDim2.new(1, 0, 1, 0)
	self.container.BackgroundTransparency = 1
	self.container.Name = "OptionContainer"
	self.container.Parent = parent
	
	-- Add UIListLayout for automatic spacing
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = self.container
	
	return self
end

-- Get the container frame for this OptionsHandler instance
function OptionsHandler:getContainer()
	return self.container
end

-- Destroy this OptionsHandler instance and clean up its container
function OptionsHandler:destroy()
	if self.container then
		self.container:Destroy()
		self.container = nil
	end
end

local function withTemplate(container, templateName, callback)
	assert(container, "container must be provided")
	assert(typeof(container) == "Instance", "container must be an Instance")
	assert(templateName, "templateName must be provided")
	assert(typeof(templateName) == "string", "templateName must be a string")
	assert(callback, "callback must be provided")
	assert(typeof(callback) == "function", "callback must be a function")

	local option = Templates:FindFirstChild(templateName):Clone()

	callback(option)
	
	option.Parent = container
	option.Visible = true
end

function OptionsHandler:createIntOption(name, val, incrementVal, minVal, maxVal)
	incrementVal = incrementVal or 1
	minVal = minVal or -math.huge
	maxVal = maxVal or math.huge

	withTemplate(self.container, "IntOption", function(option)
		option.Display.Text = name

		option.Increment.MouseButton1Click:Connect(function()
			local newValue = val:get() + incrementVal
			if newValue <= maxVal then
				val:set(newValue)
			end
		end)

		option.Decrement.MouseButton1Click:Connect(function()
			local newValue = val:get() - incrementVal
			if newValue >= minVal then
				val:set(newValue)
			end
		end)

		val:on(function(val)
			option.ValueDisplay.Text = val
		end)

		val:set(val:get(), true)
	end)
end

function OptionsHandler:createBoolOption(name, val)
	withTemplate(self.container, "BoolOption", function(option)
		option.Display.Text = name
		option.Name = name

		option.Toggleable.MouseButton1Click:Connect(function()
			val:set(not val:get())
		end)

		val:on(function(newval)
			if newval then
				option.Toggleable.Text = "TRUE"
				option.Toggleable.BackgroundColor3 = Color3.fromRGB(90, 170, 113)
			else
				option.Toggleable.Text = "FALSE"
				option.Toggleable.BackgroundColor3 = Color3.fromRGB(147, 44, 46)
			end
		end)

		val:set(val:get(), true)
	end)
end

function OptionsHandler:createRadioOption(name, val, selection)
	withTemplate(self.container, "RadioOption", function(option)
		option.Display.Text = name

		if option:FindFirstChild("SampleButton") then
			option.SampleButton.Visible = false
		end

		local valueToButton = {}

		for i = 1, #selection do
			local selectionButton = option.SampleButton:Clone()
			selectionButton.Visible = true
			selectionButton.Name = selection[i]
			selectionButton.Text = selection[i]
			CollectionService:AddTag(selectionButton, "Radio_" .. name)
			selectionButton.Parent = option
			valueToButton[selection[i]] = selectionButton

			selectionButton.MouseButton1Click:Connect(function()
				val:set(selectionButton.Name)
			end)
		end

		-- Reflect current value in UI and keep it in sync
		local function updateSelectionUI(currentValue)
			for _, child in ipairs(option:GetChildren()) do
				if child:IsA("GuiButton") and child ~= option.SampleButton then
					if child.Name == tostring(currentValue) then
						child.BackgroundColor3 = Color3.fromRGB(255, 167, 36)
					else
						child.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
					end
				end
			end
		end

		val:on(function(currentValue)
			updateSelectionUI(currentValue)
		end)

		-- Initialize UI to current value (without re-firing listeners)
		val:set(val:get(), true)
	end)
end

function OptionsHandler:createMultiselectOption(name, val, selection)
	withTemplate(self.container, "RadioOption", function(option)
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
	end)
end

function OptionsHandler:createOptionFromConfig(name, val, config)
	if config.type == "int" then
		self:createIntOption(name, val, config.increment or 1, config.min, config.max)
	elseif config.type == "bool" then
		self:createBoolOption(name, val)
	elseif config.type == "radio" then
		self:createRadioOption(name, val, config.selection)
	elseif config.type == "multiselect" then
		self:createMultiselectOption(name, val, config.selection)
	else
		warn("Unknown option type:", config.type)
	end
end

function OptionsHandler:autoRegisterOptions(categoryFilter)
	local Options = require(game.ReplicatedStorage.State.Options)
	local Val = require(game.ReplicatedStorage.Libraries.Val)
	
	for key, val in Options do
		if typeof(val) == "table" and getmetatable(val) == Val and val._optionConfig and val._optionConfig.category == categoryFilter then
			self:createOptionFromConfig(val._optionConfig.displayName, val, val._optionConfig)
		end
	end
end

return OptionsHandler
