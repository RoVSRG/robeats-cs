local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

local function MenuBar(props)
	local buttons = props.buttons or {}

	if RunService:IsStudio() and props.includeStudioButton ~= false then
		table.insert(buttons, {
			text = "Song Editor (Studio)",
			onClick = function()
				ReplicatedStorage.Bindables.ShowSongEditor:Fire()
			end,
		})
	end

	local buttonElements = {}

	for index, button in ipairs(buttons) do
		table.insert(buttonElements, e(UI.TextButton, {
			LayoutOrder = index + 1,
			Text = string.upper(button.text),
			Size = UDim2.new(0, math.huge, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundColor3 = UI.Theme.colors.button,
			TextColor3 = UI.Theme.colors.textPrimary,
			[React.Event.MouseButton1Click] = button.onClick,
			[React.Event.MouseEnter] = function(self)
				self.BackgroundColor3 = UI.Theme.colors.buttonHover
				self.TextColor3 = Color3.new(0, 0, 0)
			end,
			[React.Event.MouseLeave] = function(self)
				self.BackgroundColor3 = UI.Theme.colors.button
				self.TextColor3 = UI.Theme.colors.textPrimary
			end,
		}))
	end

	-- Hidden back button placeholder to preserve archive ordering
	table.insert(buttonElements, 1, e(UI.ImageButton, {
		Visible = false,
		Size = UDim2.new(0.111, 0, 1, 0),
	}))

	return e(UI.Frame, {
		Size = UDim2.new(1, 0, 0.05, 0),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BorderSizePixel = 0,
	}, {
		e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		e(UI.Frame, {
			Size = UDim2.new(1, 0, 0.1, 0),
			Position = UDim2.new(0, 0, -0.1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
		}, {
			e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(217, 25, 255)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(156, 139, 211)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 200, 177)),
				}),
			}),
		}),
		e(UI.Frame, {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			table.unpack(buttonElements),
		}),
	})
end

return MenuBar
