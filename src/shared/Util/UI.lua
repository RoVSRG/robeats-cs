local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(ReplicatedStorage.Contexts.ThemeContext)

local e = React.createElement

local function shallowCopy(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function pullChildren(props)
	local children = props.children or props[React.Children]
	props.children = nil
	props[React.Children] = nil
	return children or {}
end

local function mergeChildren(first, others)
	local combined = {}

	if first then
		table.insert(combined, first)
	end

	for key, child in pairs(others) do
		combined[key] = child
	end

	return combined
end

local function applyDefaults(theme, kind, props)
	local applied = {}
	for key, value in pairs(props) do
		applied[key] = value
	end

	if kind == "TextLabel" then
		applied.TextColor3 = applied.TextColor3 or theme.colors.textPrimary
		applied.Font = applied.Font or theme.fonts.body
		applied.TextSize = applied.TextSize or theme.textSize
		applied.BackgroundTransparency = applied.BackgroundTransparency or 1
	end

	if kind == "ImageLabel" or kind == "ImageButton" then
		applied.BackgroundTransparency = applied.BackgroundTransparency or 1
	end

	return applied
end

local UI = {}

function UI.Frame(rawProps)
	rawProps = rawProps or {}
	local theme = React.useContext(Theme.Context)
	local props = applyDefaults(theme, "Frame", shallowCopy(rawProps))
	local children = pullChildren(props)

	return e("Frame", props, children)
end

function UI.Image(rawProps)
	rawProps = rawProps or {}
	local theme = React.useContext(Theme.Context)
	local props = applyDefaults(theme, "ImageLabel", shallowCopy(rawProps))
	local children = pullChildren(props)
	return e("ImageLabel", props, children)
end

function UI.Text(rawProps)
	rawProps = rawProps or {}
	local theme = React.useContext(Theme.Context)
	local props = applyDefaults(theme, "TextLabel", shallowCopy(rawProps))
	local children = pullChildren(props)
	return e("TextLabel", props, children)
end

function UI.Button(rawProps)
	rawProps = rawProps or {}
	local theme = React.useContext(Theme.Context)
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	local hover, setHover = React.useState(false)

	local onClick = props.onClick
	props.onClick = nil

	local text = props.Text or props.text
	props.Text = nil
	props.text = nil

	local textProps = props.TextProps or {}
	props.TextProps = nil

	local function moveTextProp(key)
		if props[key] ~= nil then
			textProps[key] = props[key]
			props[key] = nil
		end
	end

	moveTextProp("TextXAlignment")
	moveTextProp("TextYAlignment")
	moveTextProp("TextColor3")
	moveTextProp("TextScaled")
	moveTextProp("TextSize")
	moveTextProp("TextStrokeTransparency")
	moveTextProp("TextWrapped")
	moveTextProp("Font")
	moveTextProp("RichText")
	moveTextProp("LineHeight")

	props.AutoButtonColor = props.AutoButtonColor or false
	props.BackgroundColor3 = hover and theme.colors.buttonHover or (props.BackgroundColor3 or theme.colors.button)
	props.BorderSizePixel = props.BorderSizePixel or 0
	props.ImageTransparency = props.ImageTransparency or 1
	props[React.Event.MouseButton1Click] = onClick
	props[React.Event.MouseEnter] = function()
		setHover(true)
	end
	props[React.Event.MouseLeave] = function()
		setHover(false)
	end

	local textChild
	if text then
		textChild = e("TextLabel", {
			Text = text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = textProps.Size or UDim2.new(0.925, 0, 0.4, 0),
			BackgroundTransparency = 1,
			Font = textProps.Font or theme.fonts.bold,
			TextColor3 = textProps.TextColor3 or (hover and Color3.new(0, 0, 0) or theme.colors.textPrimary),
			TextScaled = if textProps.TextScaled == nil then true else textProps.TextScaled,
			TextSize = textProps.TextSize,
			TextStrokeTransparency = textProps.TextStrokeTransparency,
			TextXAlignment = textProps.TextXAlignment or Enum.TextXAlignment.Left,
			TextYAlignment = textProps.TextYAlignment,
			TextWrapped = if textProps.TextWrapped == nil then true else textProps.TextWrapped,
			RichText = textProps.RichText,
			LineHeight = textProps.LineHeight,
		})
	end

	if props.CornerRadius ~= false then
		children._corner = e("UICorner", { CornerRadius = props.CornerRadius or theme.corner })
	end

	return e("ImageButton", props, mergeChildren(textChild, children))
end

function UI.List(rawProps)
	rawProps = rawProps or {}
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	return e("UIListLayout", props, children)
end

function UI.Padding(rawProps)
	rawProps = rawProps or {}
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	return e("UIPadding", props, children)
end

function UI.Corner(rawProps)
	rawProps = rawProps or {}
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	return e("UICorner", props, children)
end

function UI.Element(instanceType, rawProps)
	rawProps = rawProps or {}
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	return e(instanceType, props, children)
end

return UI
