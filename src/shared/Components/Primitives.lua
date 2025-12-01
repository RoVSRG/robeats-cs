local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Theme = require(ReplicatedStorage.Components.Theme)

local e = React.createElement

local function merge(base, extra)
	local out = {}
	for k, v in pairs(base) do
		out[k] = v
	end
	if extra then
		for k, v in pairs(extra) do
			out[k] = v
		end
	end
	return out
end

local function splitChildren(props)
	if not props then
		return {}, nil
	end

	local children = props.children
	local cleaned = {}
	for k, v in pairs(props) do
		if k ~= "children" then
			cleaned[k] = v
		end
	end
	return cleaned, children
end

local Primitives = {}

Primitives.Frame = function(props)
	local cleaned, children = splitChildren(props)

	local defaults = {
		BackgroundColor3 = Theme.colors.background,
		BorderSizePixel = 0,
	}

	return e("Frame", merge(defaults, cleaned), children)
end

Primitives.TextLabel = function(props)
	local cleaned, children = splitChildren(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		TextColor3 = Theme.colors.textPrimary,
		TextSize = Theme.textSize,
		TextScaled = false,
	}
	return e("TextLabel", merge(defaults, cleaned), children)
end

Primitives.TextButton = function(props)
	local cleaned, children = splitChildren(props)
	local defaults = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.colors.button,
		Font = Theme.fonts.bold,
		TextColor3 = Theme.colors.textPrimary,
		TextScaled = false,
	}
	return e("TextButton", merge(defaults, cleaned), children)
end

Primitives.ImageLabel = function(props)
	local cleaned, children = splitChildren(props)
	local defaults = {
		BackgroundTransparency = 1,
	}
	return e("ImageLabel", merge(defaults, cleaned), children)
end

Primitives.ImageButton = function(props)
	local cleaned, children = splitChildren(props)
	local defaults = {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}
	return e("ImageButton", merge(defaults, cleaned), children)
end

Primitives.UICorner = function(props)
	return e("UICorner", props or { CornerRadius = Theme.corner })
end

Primitives.UIPadding = function(props)
	return e("UIPadding", props)
end

Primitives.UIListLayout = function(props)
	return e("UIListLayout", props)
end

Primitives.TextBox = function(props)
	local cleaned, children = splitChildren(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.fonts.body,
		TextColor3 = Theme.colors.textPrimary,
		TextSize = Theme.textSize,
		TextScaled = false,
		BorderSizePixel = 0,
		ClearTextOnFocus = true,
	}
	return e("TextBox", merge(defaults, cleaned), children)
end

-- shorthand atoms
Primitives.Corner = function(radius)
	return Primitives.UICorner({
		CornerRadius = if radius then UDim.new(0, radius) else Theme.corner,
	})
end

type PaddingProps = {
	Left: number?,
	Right: number?,
	Top: number?,
	Bottom: number?,
}

Primitives.Padding = function(props: PaddingProps)
	return Primitives.UIPadding({
		PaddingLeft = UDim.new(0, props.Left or 0),
		PaddingRight = UDim.new(0, props.Right or 0),
		PaddingTop = UDim.new(0, props.Top or 0),
		PaddingBottom = UDim.new(0, props.Bottom or 0),
	})
end

type LayoutProps = {
	Direction: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	Order: Enum.SortOrder?,
	Padding: number?,
}

Primitives.Layout = function(props: LayoutProps)
	return Primitives.UIListLayout({
		FillDirection = props.Direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Top,
		SortOrder = props.Order or Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, props.Padding or 0),
	})
end

type FlexItemProps = {
	Mode: Enum.UIFlexMode?,
	GrowRatio: number?,
	ShrinkRatio: number?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
}

Primitives.FlexItem = function(props: FlexItemProps)
	return e("UIFlexItem", {
		FlexMode = props.Mode or Enum.UIFlexMode.Fill,
		GrowRatio = props.GrowRatio or 1,
		ShrinkRatio = props.ShrinkRatio or 1,
		ItemLineAlignment = props.ItemLineAlignment or Enum.ItemLineAlignment.Center,
	})
end

Primitives.Theme = Theme

return Primitives
