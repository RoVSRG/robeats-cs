local Container = script.Parent.Container

-- Helper for random silly colors
local function randomColor()
	local h = math.random()
	local s = math.random(30, 50) / 100
	local v = math.random(60, 85) / 100
	return Color3.fromHSV(h, s, v)
end

local function Spacer(parent, height)
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.fromOffset(0, height or 5)
	spacer.BackgroundTransparency = 1
	spacer.Parent = parent
end

-- Create a silly text line
local function Line(parent, textString, textSize, bold)
	local label = Instance.new("TextLabel")
	label.Text = textString or "???"
	label.TextSize = textSize or 12
	label.TextColor3 = Color3.fromHex("#ededed")
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -10, 0, textSize + 6)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	
	label.Parent = parent
	return label
end

local version = 0

local function addUpdate(shortDescription)
	version += 1
	
	script.Parent.Title.Text = "Patch #" .. version
	
	local api = {}

	-- Container for the entire update card
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -10, 0, 40) -- will expand dynamically
	card.BackgroundColor3 = randomColor()
	card.BorderSizePixel = 0
	card.BackgroundTransparency = 0.05
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.LayoutOrder = -version
	card.Parent = Container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Padding inside card
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = card

	-- Layout for stacking version + lines
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = card

	-- Version line
	Line(card, "Patch #" .. tostring(version) .. "  –  " .. (shortDescription or "No description lol"), 22, true)

	Spacer(Container, 5)

	-- API: addLine for this specific card
	function api.addLine(text)
		Line(card, "• " .. text, 12, false)
	end

	function api.setColor(c)
		card.BackgroundColor3 = c
	end

	return api
end

-- Title section
Line(Container, "LATEST CHAOS UPDATES", 28, true)
Spacer(Container, 10)

-- Example updates
local u1 = addUpdate("Absolute CINEMA")
u1.addLine("We slapped this together over the course of a few weeks.")
u1.addLine("Yes, you're welcome.")
u1.addLine("Introduced bugs beyond your belief.")
