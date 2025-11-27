-- Notification system
-- Listens to Bindables.CreateNotification and spawns UI notifications
-- Usage examples:
--   game.ReplicatedStorage.Bindables.CreateNotification:Fire("Saved successfully")
--   game.ReplicatedStorage.Bindables.CreateNotification:Fire("Missing chart file", "warning")
--   game.ReplicatedStorage.Bindables.CreateNotification:Fire({ message = "Critical failure", type = "error" })

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local bindables = game.ReplicatedStorage:WaitForChild("Bindables")
local createNotificationEvent = bindables:WaitForChild("CreateNotification") :: BindableEvent

local FX = require(game.ReplicatedStorage.Modules.FX)

-- Create (or reuse) root ScreenGui
local screenGui: ScreenGui = (playerGui:FindFirstChild("Notifications") :: ScreenGui) or Instance.new("ScreenGui")
screenGui.Name = "Notifications"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local container: Frame = (screenGui:FindFirstChild("Container") :: Frame) or Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, -20, 1, -20)
container.Position = UDim2.new(0, 10, 0, 10)
container.AnchorPoint = Vector2.new(0, 0)
container.BackgroundTransparency = 1
container.Parent = screenGui

local listLayout: UIListLayout = (container:FindFirstChild("UIListLayout") :: UIListLayout)
	or Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = container

-- Styling per type (subtle accent colors only)
local TYPE_STYLE: { [string]: { Accent: Color3, Text: string } } = {
	info = { Accent = Color3.fromRGB(90, 150, 255), Text = "Info" },
	warning = { Accent = Color3.fromRGB(255, 190, 60), Text = "Warning" },
	error = { Accent = Color3.fromRGB(255, 90, 90), Text = "Error" },
}

local BASE_BACKGROUND = Color3.fromRGB(32, 34, 38)
local BASE_TRANSPARENCY_VISIBLE = 0.12

local ACTIVE = {}
local nextId = 0

local function playSound(nType: string)
	if nType == "error" then
		FX.PlaySound("Error")
	elseif nType == "warning" then
		FX.PlaySound("Error")
	else
		FX.PlaySound("Notification")
	end
end

local function makeNotification(message: string, nType: string?)
	local nTypeResolved: string = (nType and string.lower(nType)) or "info"
	if TYPE_STYLE[nTypeResolved] == nil then
		nTypeResolved = "info"
	end

	playSound(nTypeResolved)

	nextId += 1
	local id = nextId

	local style = TYPE_STYLE[nTypeResolved]

	local holder = Instance.new("Frame")
	holder.Name = "Notification_" .. id
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(0, 360, 0, 0)
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, 0, 0, 0)
	holder.BackgroundColor3 = BASE_BACKGROUND
	holder.BackgroundTransparency = BASE_TRANSPARENCY_VISIBLE
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = holder

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.65
	stroke.Color = style.Accent:Lerp(Color3.new(1, 1, 1), 0.35)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = holder

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.BackgroundColor3 = style.Accent
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.Position = UDim2.new(0, -4, 0, 0)
	accent.Parent = holder

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = holder

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = style.Text
	title.ZIndex = 2
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.AutomaticSize = Enum.AutomaticSize.Y
	-- Nudge right 5px; shrink width by 5 to preserve space for dismiss button
	title.Position = UDim2.new(0, 5, 0, 0)
	title.Size = UDim2.new(1, -33, 0, 14)
	title.Parent = holder

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.new(1, 1, 1)
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.AutomaticSize = Enum.AutomaticSize.Y
	-- Match right nudge of title
	body.Size = UDim2.new(1, -33, 0, 0)
	body.Position = UDim2.new(0, 5, 0, 18)
	body.Text = message
	body.Parent = holder

	local dismiss = Instance.new("TextButton")
	dismiss.Name = "Dismiss"
	dismiss.Text = "x"
	dismiss.Font = Enum.Font.GothamBold
	dismiss.TextSize = 18
	dismiss.BackgroundTransparency = 1
	dismiss.TextColor3 = Color3.new(1, 1, 1)
	dismiss.AnchorPoint = Vector2.new(1, 0)
	dismiss.Size = UDim2.new(0, 20, 0, 20)
	dismiss.Position = UDim2.new(1, -2, 0, 2)
	dismiss.Parent = holder

	local layoutOrder = -id -- newest on top
	holder.LayoutOrder = layoutOrder

	local appear = TweenService:Create(
		holder,
		TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ BackgroundTransparency = BASE_TRANSPARENCY_VISIBLE }
	)
	holder.BackgroundTransparency = 1
	appear:Play()

	ACTIVE[id] = holder

	local function remove()
		if not ACTIVE[id] then
			return
		end
		ACTIVE[id] = nil
		local tween = TweenService:Create(
			holder,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1, Size = UDim2.new(0, holder.AbsoluteSize.X, 0, 0) }
		)
		tween.Completed:Connect(function()
			holder:Destroy()
		end)
		tween:Play()
	end

	dismiss.MouseButton1Click:Connect(remove)

	-- Auto dismiss after 8s (errors last longer)
	task.delay(nTypeResolved == "error" and 12 or 8, remove)
end

createNotificationEvent.Event:Connect(function(param1, param2)
	local msg: string
	local nType: string? = nil
	if typeof(param1) == "table" then
		msg = param1.message or param1.text or "(no message)"
		nType = param1.type or param1.kind
	else
		msg = tostring(param1)
		nType = param2 and tostring(param2) or nil
	end
	makeNotification(msg, nType)
end)

createNotificationEvent:Fire("Welcome to Robeats CS!", "info")
