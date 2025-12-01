local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local Transient = require(ReplicatedStorage.State.Transient)
local SPUtil = require(ReplicatedStorage.Shared.SPUtil)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

-- Calculate how many graphemes can fit in the available width
local function calculateVisibleGraphemes(text, textSize, font, maxWidth)
	for i = 1, string.len(text) do
		local substring = string.sub(text, 1, i)
		local textDimensions = TextService:GetTextSize(substring, textSize, font, Vector2.new(math.huge, math.huge))
		if textDimensions.X > maxWidth then
			return i - 1
		end
	end
	return string.len(text) + 1
end

--[[
	SongButton - Individual song button matching archive design

	Props:
		song: table - Song data {ID, SongName, ArtistName, CharterName, Difficulty, Color}
		position: UDim2 - Position in virtual list
		size: UDim2 - Size of button
		color: Color3 - Background color (from color mode)
]]
local function SongButton(props)
	local song = props.song
	local buttonRef = useRef(nil)

	-- Build text: [Difficulty] Artist - Title (Charter)
	local text = string.format(
		"[%d] %s - %s (%s)",
		math.floor((song.Difficulty or 0) + 0.5),
		song.ArtistName or "Unknown",
		song.SongName or "Unknown",
		song.CharterName or "Unknown"
	)

	-- Click handler: Update selected song in Transient state
	local function handleClick(rbx)
		Transient.song.selected:set(song.ID)
		SPUtil:attach_sound(rbx, "Select")
	end

	-- Calculate and set MaxVisibleGraphemes after mount
	useEffect(function()
		if buttonRef.current then
			task.defer(function()
				local button = buttonRef.current
				if button then
					local maxWidth = button.AbsoluteSize.X
					local maxGraphemes = calculateVisibleGraphemes(
						text,
						15, -- TextSize
						UI.Theme.fonts.body,
						maxWidth
					)
					button.MaxVisibleGraphemes = maxGraphemes
				end
			end)
		end
	end, {})

	return e(UI.TextButton, {
		ref = buttonRef,
		Text = text,
		Size = props.size or UDim2.new(1, -10, 0, 38),
		BackgroundColor3 = props.color or song.Color or Color3.fromRGB(255, 255, 255),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = UI.Theme.fonts.body,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		MaxVisibleGraphemes = 50, -- Default, will be calculated
		ClipsDescendants = true,
		[React.Event.MouseButton1Click] = handleClick,
	}, {
		Padding = e(UI.UIPadding, {
			PaddingLeft = UDim.new(0, 4),
		}),
	})
end

return React.memo(SongButton, function(oldProps, newProps)
	-- Only re-render if song ID or color changes
	return oldProps.song.ID == newProps.song.ID
		and oldProps.color == newProps.color
end)
