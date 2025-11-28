local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Util.UI)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local function MenuBar(props)
	local context = React.useContext(ScreenContext)
	local isStudio = RunService:IsStudio()

	local buttons = props.buttons or {}
	local includeStudio = if props.includeStudioButton == nil then true else props.includeStudioButton

	if isStudio and includeStudio then
		table.insert(buttons, {
			text = "Song Editor (Studio)",
			onClick = function()
				ReplicatedStorage.Bindables.ShowSongEditor:Fire()
			end,
		})
	end

	local children = {}

	children.Outline = UI.Frame({
		Size = UDim2.new(1, 0, 0.1, 0),
		Position = UDim2.new(0, 0, -0.1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		children = {
			UI.Element("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(217, 25, 255)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(156, 139, 211)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 200, 177)),
				}),
			}),
		},
	})

	children.Stabilizer = UI.Frame({
		Size = UDim2.new(1, 0, 0.25, 0),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BorderSizePixel = 0,
	})

	local buttonChildren = {}
	buttonChildren.Layout = UI.List({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	if #buttons == 0 then
		table.insert(buttons, {
			text = "Back",
			Visible = false,
			onClick = function()
				context.switchScreen("MainMenu")
			end,
		})
	end

	for index, button in ipairs(buttons) do
		buttonChildren["Button" .. index] = UI.Button({
			Size = UDim2.new(0.111, 0, 1, 0),
			Visible = if button.Visible == nil then true else button.Visible,
			Text = button.text,
			TextProps = {
				TextXAlignment = Enum.TextXAlignment.Center,
			},
			onClick = button.onClick or function()
				context.switchScreen(button.target or "MainMenu")
			end,
		})
	end

	children.Buttons = UI.Frame({
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		children = buttonChildren,
	})

	children.Corner = UI.Corner({ CornerRadius = UDim.new(0, 4) })

	return UI.Frame({
		Size = props.Size or UDim2.new(1, 0, 0.05, 0),
		Position = props.Position or UDim2.new(0, 0, 1, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BorderSizePixel = 0,
		children = children,
	})
end

return MenuBar
