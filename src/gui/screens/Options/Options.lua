local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local OptionList = require(script.Parent.Components.OptionList)
local SkinsPanel = require(script.Parent.Components.SkinsPanel)
local SettingsSerializer = require(ReplicatedStorage.Serialization.SettingsSer)

local SaveSettings = ReplicatedStorage.Remotes.Events.SaveSettings

local e = React.createElement

local NAV_ITEMS = {
	{ key = "General", label = "General", icon = "⚙️" },
	{ key = "Input", label = "Input", icon = "⌨️" },
	{ key = "VisualEffects", label = "Visual Effects", icon = "💥" },
	{ key = "2D", label = "2D", icon = "⭕" },
	{ key = "Skins", label = "Skins", icon = "🖌️" },
}

local function NavButton(props)
	local isActive = props.active
	local isHovering, setIsHovering = React.useState(false)

	local backgroundColor
	if isActive then
		backgroundColor = Color3.fromRGB(60, 60, 60)
	elseif isHovering then
		backgroundColor = Color3.fromRGB(50, 50, 50)
	else
		backgroundColor = Color3.fromRGB(40, 40, 40)
	end

	return e(UI.TextButton, {
		Text = "",
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = backgroundColor,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		[React.Event.MouseButton1Click] = props.onClick,
		[React.Event.MouseEnter] = function()
			setIsHovering(true)
		end,
		[React.Event.MouseLeave] = function()
			setIsHovering(false)
		end,
	}, {
		Flex = e("UIFlexItem", {
			FlexMode = Enum.UIFlexMode.Fill,
		}),
		Padding = e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),

		Icon = props.icon and e(UI.TextLabel, {
			Text = props.icon,
			Size = UDim2.fromOffset(63, 57),
			Position = UDim2.new(0.47, 0, 0.12, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(222, 222, 222),
			TextSize = 71,
			TextTransparency = 0.63,
			Font = UI.Theme.fonts.bold,
		}),

		Label = e(UI.TextLabel, {
			Text = props.label,
			Size = UDim2.fromOffset(96, 34),
			Position = UDim2.new(0.033, 0, 0.45, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(222, 222, 222),
			TextSize = 32,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.bold,
		}),
	})
end

local function PageShell(props)
	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		Visible = props.active,
	}, {
		Padding = e(UI.UIPadding, { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }),
		Title = e(UI.TextLabel, {
			Text = props.title,
			Size = UDim2.new(0.999, 0, 0.055, 0),
			Position = UDim2.new(0, 0, 0.006, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(116, 116, 116),
			TextScaled = true,
			TextSize = 60,
			Font = UI.Theme.fonts.bold,
			TextWrapped = true,
		}),
		Body = props.children,
	})
end

local function Options()
	local screenContext = React.useContext(ScreenContext)
	local activePage, setActivePage = React.useState("General")
	local backHover, setBackHover = React.useState(false)

	local function handleBack()
		SaveSettings:FireServer(SettingsSerializer.get_serialized_opts())
		screenContext.switchScreen("MainMenu")
		setActivePage("General")
	end

	local navButtons = {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.005, 1),
			Wraps = false,
		}),
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
	}

	for index, item in ipairs(NAV_ITEMS) do
		navButtons["Button" .. item.key] = e(NavButton, {
			label = item.label,
			icon = item.icon,
			layoutOrder = index,
			active = activePage == item.key,
			onClick = function()
				setActivePage(item.key)
			end,
		})
	end

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Container = e(UI.Frame, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1049, 442),
			BackgroundTransparency = 1,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

			Selections = e(UI.Frame, {
				Position = UDim2.new(0.191, 0, 0, 0),
				Size = UDim2.new(0.155, 0, 0.908, 0),
				BackgroundColor3 = Color3.fromRGB(29, 28, 29),
				BorderSizePixel = 0,
			}, navButtons),

			Pages = e(UI.Frame, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.584, 0, 0.5, 0),
				Size = UDim2.fromOffset(470, 441),
				BackgroundColor3 = Color3.fromRGB(35, 35, 35),
				BorderSizePixel = 0,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),

				General = e(PageShell, {
					title = "General",
					active = activePage == "General",
				}, e(OptionList, { category = "General" })),

				Input = e(PageShell, {
					title = "Input",
					active = activePage == "Input",
				}, e(OptionList, { category = "Input" })),

				Visual = e(PageShell, {
					title = "Visual Effects",
					active = activePage == "VisualEffects",
				}, e(OptionList, { category = "VisualEffects" })),

				TwoD = e(PageShell, {
					title = "2D",
					active = activePage == "2D",
				}, e(OptionList, { category = "2D" })),

				Skins = e(PageShell, {
					title = "Skins",
					active = activePage == "Skins",
				}, e(SkinsPanel)),
			}),

			Back = e(UI.TextButton, {
				Text = "Back",
				Size = UDim2.new(0.154, 0, 0.075, 0),
				Position = UDim2.new(0.192, 0, 0.922, 0),
				BackgroundColor3 = backHover and Color3.fromRGB(209, 57, 57) or Color3.fromRGB(199, 47, 47),
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 22,
				Font = UI.Theme.fonts.body,
				AutoButtonColor = false,
				BorderSizePixel = 2,
				[React.Event.MouseButton1Click] = handleBack,
				[React.Event.MouseEnter] = function()
					setBackHover(true)
				end,
				[React.Event.MouseLeave] = function()
					setBackHover(false)
				end,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

return Options
