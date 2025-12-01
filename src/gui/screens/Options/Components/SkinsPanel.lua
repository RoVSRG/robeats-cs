local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local Skins = require(ReplicatedStorage.Skins)
local Options = require(ReplicatedStorage.State.Options)
local useVal = require(ReplicatedStorage.hooks.useVal)

local e = React.createElement
local useEffect = React.useEffect
local useMemo = React.useMemo
local useRef = React.useRef

local function SkinsPanel(props)
	local selectedSkin, setSelectedSkin = useVal(Options.Skin2D)
	local mountRef = useRef(nil)

	local skinNames = useMemo(function()
		local sorted = {}
		for _, name in ipairs(Skins:key_list()) do
			table.insert(sorted, name)
		end
		table.sort(sorted)

		local names = { "Auto" }
		for _, name in ipairs(sorted) do
			table.insert(names, name)
		end

		return names
	end, {})

	useEffect(function()
		local mount = mountRef.current
		if not mount then
			return
		end

		for _, child in ipairs(mount:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		if not selectedSkin then
			return
		end

		local skin = Skins:get_skin(selectedSkin)
		if not skin then
			return
		end

		local gameplayFrameBase = skin:FindFirstChild("GameplayFrame")
		if not gameplayFrameBase then
			return
		end

		local gameplayFrame = gameplayFrameBase:Clone()
		gameplayFrame.AnchorPoint = Vector2.new(0.5, 1)
		gameplayFrame.Position = UDim2.fromScale(0.5, 1)
		gameplayFrame.Size = UDim2.fromScale(1, 1)
		gameplayFrame.Parent = mount

		local tracks = gameplayFrame:FindFirstChild("Tracks")
		local noteProto = skin:FindFirstChild("NoteProto")

		if tracks and noteProto then
			for index = 1, 4 do
				local track = tracks:FindFirstChild("Track" .. index)
				if track then
					local note = noteProto:Clone()
					note.Parent = track
					note.Position = UDim2.fromScale(0.5, math.random(30, 70) / 100)
				end
			end
		end

		return function()
			if gameplayFrame then
				gameplayFrame:Destroy()
			end
		end
	end, { selectedSkin })

	local listChildren = {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	}

	for index, name in ipairs(skinNames) do
		local isAuto = name == "Auto"
		local isActive
		if isAuto then
			isActive = selectedSkin == nil
		else
			isActive = selectedSkin == name
		end
		local strokeColor = isActive and Color3.fromRGB(255, 167, 36) or Color3.new(0, 0, 0)

		listChildren["Skin" .. index] = e(UI.TextButton, {
			Text = name,
			Size = UDim2.fromOffset(201, 26),
			BackgroundColor3 = Color3.fromRGB(17, 17, 17),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			Font = UI.Theme.fonts.bold,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = index,
			[React.Event.MouseButton1Click] = function()
				if isAuto then
					setSelectedSkin(nil)
				else
					setSelectedSkin(name)
				end
			end,
		}, {
			UI.Padding({ Left = 10 }),
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
			Stroke = e("UIStroke", {
				Color = strokeColor,
				Thickness = 1,
			}),
		})
	end

	return e(UI.Frame, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.new(0.5, 0, 0.533, 0),
		Size = props.size or UDim2.new(1, 0, 0.933, 0),
		BackgroundTransparency = 1,
	}, {
		List = e("Frame", {
			Position = UDim2.new(0.034, 0, 0.138, 0),
			Size = UDim2.fromOffset(222, 345),
			BackgroundTransparency = 1,
		}, {
			Scroller = e("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
			}, listChildren),
		}),
		Metadata = e(UI.Frame, {
			Position = UDim2.new(0.522, 0, 0.138, 0),
			Size = UDim2.fromOffset(205, 345),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
			SkinMount = e("Frame", {
				Position = UDim2.new(0.063, 0, 0.049, 0),
				Size = UDim2.fromOffset(178, 267),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ref = mountRef,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
			}),
			Info = e(UI.Frame, {
				Position = UDim2.new(0.063, 0, 0.861, 0),
				Size = UDim2.fromOffset(178, 34),
				BackgroundColor3 = Color3.fromRGB(18, 18, 18),
				BorderSizePixel = 0,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
				Padding = e(UI.UIPadding, { PaddingLeft = UDim.new(0, 7) }),
				Layout = e(UI.UIListLayout, {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Label = e(UI.TextLabel, {
					Text = "Skin Selected:",
					Size = UDim2.fromOffset(145, 11),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(216, 216, 216),
					TextSize = 11,
					Font = UI.Theme.fonts.body,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),
				Name = e(UI.TextLabel, {
					Text = selectedSkin or "Auto",
					Size = UDim2.fromOffset(145, 10),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(216, 216, 216),
					TextSize = 11,
					Font = UI.Theme.fonts.bold,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}),
			}),
		}),
	})
end

return SkinsPanel
