local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(ReplicatedStorage.Contexts.ThemeContext)

type Children = { [any]: any }
type BaseProps = { [string]: any, children: Children? }
type TextProps = {
	Font: Enum.Font?,
	TextColor3: Color3?,
	TextScaled: boolean?,
	TextSize: number?,
	TextStrokeTransparency: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextWrapped: boolean?,
	RichText: boolean?,
	LineHeight: number?,
	Size: UDim2?,
}
type ButtonProps = BaseProps & {
	Text: string?,
	TextProps: TextProps?,
	Image: string?,
	AutoButtonColor: boolean?,
	BackgroundColor3: Color3?,
	BorderSizePixel: number?,
	ImageTransparency: number?,
	CornerRadius: UDim?,
	onClick: (() -> ())?,
}

local e = React.createElement

local function shallowCopy(source: { [any]: any }?): { [any]: any }
	local copy = {}
	if source then
		for key, value in pairs(source) do
			copy[key] = value
		end
	end
	return copy
end

local function pullChildren(props: BaseProps): Children
	local children = props.children
	props.children = nil
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

local function applyDefaults(theme: any, kind: string, props: { [any]: any })
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

function UI.Text(rawProps: BaseProps?)
	rawProps = rawProps or {}
	local theme = React.useContext(Theme.Context)
	local props = applyDefaults(theme, "TextLabel", shallowCopy(rawProps))
	local children = pullChildren(props)
	return e("TextLabel", props, children)
end

function UI.Button(rawProps: ButtonProps?)
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

	local hasImage = props.Image ~= nil or props.image ~= nil
	local hasText = text ~= nil

	local variant
	if hasImage and hasText then
		variant = "image-text"
	elseif hasImage then
		variant = "image"
	else
		variant = "text"
	end

	if variant == "text" then
		local buttonProps = shallowCopy(props)
		buttonProps.AutoButtonColor = buttonProps.AutoButtonColor or false
		buttonProps.BackgroundColor3 = hover and theme.colors.buttonHover
			or (buttonProps.BackgroundColor3 or theme.colors.button)
		buttonProps.BorderSizePixel = buttonProps.BorderSizePixel or 0
		buttonProps.Text = text or ""
		buttonProps.Font = textProps.Font or theme.fonts.bold
		buttonProps.TextColor3 = textProps.TextColor3 or (hover and Color3.new(0, 0, 0) or theme.colors.textPrimary)
		buttonProps.TextScaled = if textProps.TextScaled == nil then false else textProps.TextScaled
		buttonProps.TextSize = textProps.TextSize or theme.textSize
		buttonProps.TextStrokeTransparency = textProps.TextStrokeTransparency
		buttonProps.TextXAlignment = textProps.TextXAlignment or Enum.TextXAlignment.Left
		buttonProps.TextYAlignment = textProps.TextYAlignment
		buttonProps.TextWrapped = if textProps.TextWrapped == nil then true else textProps.TextWrapped
		buttonProps.RichText = textProps.RichText
		buttonProps.LineHeight = textProps.LineHeight

		buttonProps[React.Event.MouseButton1Click] = onClick
		buttonProps[React.Event.MouseEnter] = function()
			setHover(true)
		end
		buttonProps[React.Event.MouseLeave] = function()
			setHover(false)
		end

		if buttonProps.CornerRadius ~= false then
			children._corner = e("UICorner", { CornerRadius = buttonProps.CornerRadius or theme.corner })
		end

		return e("TextButton", buttonProps, children)
	end

	local imageProps = shallowCopy(props)
	imageProps.AutoButtonColor = imageProps.AutoButtonColor or false
	imageProps.BackgroundColor3 = hover and theme.colors.buttonHover
		or (imageProps.BackgroundColor3 or theme.colors.button)
	imageProps.BorderSizePixel = imageProps.BorderSizePixel or 0
	imageProps.ImageTransparency = imageProps.ImageTransparency or 1
	imageProps[React.Event.MouseButton1Click] = onClick
	imageProps[React.Event.MouseEnter] = function()
		setHover(true)
	end
	imageProps[React.Event.MouseLeave] = function()
		setHover(false)
	end

	local textChild
	if hasText then
		textChild = e("TextLabel", {
			Text = text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = textProps.Size or UDim2.new(0.925, 0, 0.4, 0),
			BackgroundTransparency = 1,
			Font = textProps.Font or theme.fonts.bold,
			TextColor3 = textProps.TextColor3 or (hover and Color3.new(0, 0, 0) or theme.colors.textPrimary),
			TextScaled = if textProps.TextScaled == nil then true else textProps.TextScaled,
			TextSize = textProps.TextSize or theme.textSize,
			TextStrokeTransparency = textProps.TextStrokeTransparency,
			TextXAlignment = textProps.TextXAlignment or Enum.TextXAlignment.Left,
			TextYAlignment = textProps.TextYAlignment,
			TextWrapped = if textProps.TextWrapped == nil then true else textProps.TextWrapped,
			RichText = textProps.RichText,
			LineHeight = textProps.LineHeight,
		})
	end

	if imageProps.CornerRadius ~= false then
		children._corner = e("UICorner", { CornerRadius = imageProps.CornerRadius or theme.corner })
		imageProps.CornerRadius = nil
	end

	return e("ImageButton", imageProps, mergeChildren(textChild, children))
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

function UI.Element(instanceType: string, rawProps)
	rawProps = rawProps or {}
	local props = shallowCopy(rawProps)
	local children = pullChildren(props)
	return e(instanceType, props, children)
end

return UI
