--[[
	HitGraph Component

	Visual representation of hit timing throughout a song.
	X-axis: Time progression (0 to song end)
	Y-axis: Timing deviation (-180ms to +180ms)

	Props:
		- hits: array of { hit_object_time, time_left, judgement }
		- songLength: total song duration in ms
		- rate: playback rate multiplier (1.0 = normal speed)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local NoteResult = require(ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SPUtil = require(ReplicatedStorage.Shared.SPUtil)

local e = React.createElement
local useMemo = React.useMemo

-- Timing window bounds (ms)
local MAX_OFFSET = 180
local MIN_OFFSET = -180

local function HitGraph(props)
	local hits = props.hits or {}
	local songLength = props.songLength or 1
	local rate = props.rate or 1

	-- Adjust song length for rate
	local adjustedLength = songLength / rate

	-- Build hit point elements
	local hitElements = useMemo(function()
		local elements = {}

		for i, hit in ipairs(hits) do
			local x = hit.hit_object_time / adjustedLength
			local judgement = hit.judgement

			if judgement == NoteResult.Miss then
				-- Miss: red vertical line spanning full height
				elements["Miss_" .. i] = e(UI.Frame, {
					Size = UDim2.new(0, 1, 1, 0),
					Position = UDim2.fromScale(x, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = NoteResult:result_to_color(NoteResult.Miss),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
				})
			else
				-- Hit: small colored dot
				local y = SPUtil:inverse_lerp(MAX_OFFSET, MIN_OFFSET, hit.time_left)
				elements["Hit_" .. i] = e(UI.Frame, {
					Size = UDim2.fromOffset(3, 3),
					Position = UDim2.fromScale(x, y),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = NoteResult:result_to_color(judgement),
					BorderSizePixel = 0,
				}, {
					Corner = e(UI.UICorner, { CornerRadius = UDim.new(1, 0) }),
				})
			end
		end

		return elements
	end, { hits, adjustedLength })

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Padding = e(UI.UIPadding, {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),

		-- Guide lines container
		Guides = e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, {
			-- Early line (+180ms / top)
			EarlyLine = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0, 0),
				BackgroundColor3 = Color3.fromRGB(80, 80, 80),
				BorderSizePixel = 0,
			}),

			-- Center line (0ms / perfect timing)
			CenterLine = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(100, 100, 100),
				BorderSizePixel = 0,
			}),

			-- Late line (-180ms / bottom)
			LateLine = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(80, 80, 80),
				BorderSizePixel = 0,
			}),

			-- Labels
			EarlyLabel = e(UI.TextLabel, {
				Text = "Early",
				Size = UDim2.fromOffset(40, 14),
				Position = UDim2.new(0, -5, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				TextSize = 10,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			LateLabel = e(UI.TextLabel, {
				Text = "Late",
				Size = UDim2.fromOffset(40, 14),
				Position = UDim2.new(0, -5, 1, 0),
				AnchorPoint = Vector2.new(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				TextSize = 10,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),

		-- Hit points container
		HitPoints = e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, hitElements),
	})
end

return HitGraph
