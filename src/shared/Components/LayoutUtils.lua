local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local LayoutUtils = {}

--[[
	Helper: Convert hybrid input to UDim

	Supports:
	- number -> UDim.new(0, number) - Offset-based
	- {scale, offset} -> UDim.new(scale, offset) - Hybrid
	- {scale} -> UDim.new(scale, 0) - Scale-based
]]
local function toUDim(value)
	if type(value) == "number" then
		return UDim.new(0, value)
	elseif type(value) == "table" then
		return UDim.new(value[1] or 0, value[2] or 0)
	end
	return UDim.new(0, 0)
end

--[[
	List - Create UIListLayout with straightforward syntax

	Usage:
		List({ fill = Enum.FillDirection.Horizontal, padding = 4 })
		List({ fill = Enum.FillDirection.Vertical, padding = {0.01, 5} })
		List({ fill = Enum.FillDirection.Horizontal, padding = 10, halign = Enum.HorizontalAlignment.Left })

	Props:
		fill: FillDirection (default: Vertical)
		padding or gap: number (Offset) or table {scale, offset} (Hybrid)
		halign: HorizontalAlignment (default: Center)
		valign: VerticalAlignment (default: Top)
		sortOrder: SortOrder (default: LayoutOrder)
		wraps: boolean (default: false)
]]
function LayoutUtils.List(props)
	props = props or {}

	return e("UIListLayout", {
		FillDirection = props.fill or Enum.FillDirection.Vertical,
		HorizontalAlignment = props.halign or Enum.HorizontalAlignment.Center,
		VerticalAlignment = props.valign or Enum.VerticalAlignment.Top,
		Padding = toUDim(props.padding or props.gap or 0),
		SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder,
		Wraps = props.wraps or false,
	})
end

--[[
	HList - Shorthand for horizontal UIListLayout

	Usage:
		HList({ padding = 5 })
		HList({ padding = 10, valign = Enum.VerticalAlignment.Center })
]]
function LayoutUtils.HList(props)
	local merged = props or {}
	merged.fill = Enum.FillDirection.Horizontal
	return LayoutUtils.List(merged)
end

--[[
	VList - Shorthand for vertical UIListLayout

	Usage:
		VList({ padding = 5 })
		VList({ padding = {0.01, 0}, halign = Enum.HorizontalAlignment.Left })
]]
function LayoutUtils.VList(props)
	local merged = props or {}
	merged.fill = Enum.FillDirection.Vertical
	return LayoutUtils.List(merged)
end

return LayoutUtils
