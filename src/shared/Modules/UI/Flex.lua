local Flex = {}
Flex.__index = Flex

-- [ State Management ] --
function Flex.State(initialValue)
	local self = {
		_value = initialValue,
		_listeners = {}
	}
	
	function self:get()
		return self._value
	end
	
	function self:set(newValue)
		self._value = newValue
		for _, callback in ipairs(self._listeners) do
			task.spawn(callback, newValue)
		end
	end
	
	function self:bind(callback)
		table.insert(self._listeners, callback)
		callback(self._value)
		return self -- allow chaining or just returning state
	end
	
	return self
end

function Flex.Computed(processor, ...)
	local states = {...}
	local computed = Flex.State(processor())
	
	local function update()
		computed:set(processor())
	end
	
	for _, state in ipairs(states) do
		state:bind(update)
	end
	
	return computed
end

-- [ Core ] --

-- Helper to apply properties (supports State)
local function applyProps(instance, props)
	for k, v in pairs(props) do
		if k ~= "Children" and k ~= "Parent" then
			if type(v) == "table" and v.get and v.bind then
				-- It's a State object, bind it to the property
				v:bind(function(val)
					instance[k] = val
				end)
			else
				-- Static value
				instance[k] = v
			end
		end
	end
end

-- Helper to handle children
local function mountChildren(parent, children)
	if not children then return end
	for _, child in pairs(children) do
		child.Parent = parent
	end
end

function Flex.Frame(props)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1) -- Default to full size
	
	applyProps(frame, props)
	
	if props.Children then
		mountChildren(frame, props.Children)
	end
	
	if props.Parent then
		frame.Parent = props.Parent
	end
	
	return frame
end

function Flex.ListLayout(props)
	local layout = Instance.new("UIListLayout")
	applyProps(layout, props)
	return layout
end

-- Creates a Container with a UIListLayout
function Flex.Container(props)
	local container = Instance.new("Frame")
	container.Name = props.Name or "FlexContainer"
	container.BackgroundTransparency = props.BackgroundTransparency or 1
	container.Size = props.Size or UDim2.fromScale(1, 1)
	container.Position = props.Position or UDim2.new()
	container.AnchorPoint = props.AnchorPoint or Vector2.new()
	container.BackgroundColor3 = props.BackgroundColor3 or Color3.new(1, 1, 1)
	
	-- Layout Props
	local layoutProps = {
		FillDirection = props.Direction or Enum.FillDirection.Vertical,
		SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder,
		Padding = props.Padding or UDim.new(0, 0),
		ItemLineAlignment = props.ItemLineAlignment or Enum.ItemLineAlignment.Stretch,
		HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Top,
		Wraps = props.Wraps or false,
		HorizontalFlex = props.HorizontalFlex or Enum.UIFlexAlignment.None,
		VerticalFlex = props.VerticalFlex or Enum.UIFlexAlignment.None,
	}
	
	local layout = Flex.ListLayout(layoutProps)
	layout.Parent = container
	
	-- Apply other frame props
	for k, v in pairs(props) do
		if not layoutProps[k] and k ~= "Children" and k ~= "Direction" then
			if type(v) == "table" and v.get and v.bind then
				-- State binding for container props
				v:bind(function(val)
					container[k] = val
				end)
			else
				container[k] = v
			end
		end
	end

	if props.Children then
		mountChildren(container, props.Children)
	end
	
	if props.Parent then
		container.Parent = props.Parent
	end

	return container
end

function Flex.Row(props)
	props.Direction = Enum.FillDirection.Horizontal
	return Flex.Container(props)
end

function Flex.Column(props)
	props.Direction = Enum.FillDirection.Vertical
	return Flex.Container(props)
end

-- Wrapper for an item to control its Flex behavior
function Flex.Item(props)
	local content = props.Content
	if not content then
		error("Flex.Item requires a 'Content' property (Instance).")
	end
	
	local flexItem = Instance.new("UIFlexItem")
	flexItem.FlexMode = props.FlexMode or Enum.UIFlexMode.Custom
	
	if props.GrowRatio then
		flexItem.GrowRatio = props.GrowRatio
	end
	
	if props.ShrinkRatio then
		flexItem.ShrinkRatio = props.ShrinkRatio
	end
	
	if props.ItemLineAlignment then
		flexItem.ItemLineAlignment = props.ItemLineAlignment
	end
	
	flexItem.Parent = content
	return content
end

return Flex