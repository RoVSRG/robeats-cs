--[[
	Changelog Screen

	Displays a scrollable list of update cards showing patch notes.
	Converted from archive_screens/Changelog to React Lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local BackButton = require(ReplicatedStorage.gui.components.buttons.BackButton)
local ChangelogCard = require(script.Parent.Components.ChangelogCard)
local updates = require(script.Parent.data.updates)

local e = React.createElement
local useContext = React.useContext

local function Changelog()
	local screenContext = useContext(ScreenContext)

	-- Build children for container
	local children = {
		UIListLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		-- Title
		Title = e("TextLabel", {
			Text = "LATEST CHAOS UPDATES",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromHex("#ededed"),
			Font = Enum.Font.GothamBold,
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}),

		-- Spacer after title
		TitleSpacer = e("Frame", {
			Size = UDim2.fromOffset(0, 10),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}),
	}

	-- Add changelog cards (reverse order for newest first)
	for index, update in ipairs(updates) do
		children["Update_" .. index] = e(ChangelogCard, {
			version = update.version,
			title = update.title,
			lines = update.lines,
			color = update.color,
			layoutOrder = -update.version + 100, -- Negative to reverse order
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
		BorderSizePixel = 0,
	}, {
		-- Scrollable container
		Container = e("ScrollingFrame", {
			Size = UDim2.new(1, -40, 1, -80),
			Position = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		}, children),

		-- Back button
		BackButton = e(BackButton, {
			onClick = function()
				screenContext.switchScreen("MainMenu")
			end,
		}),
	})
end

return Changelog
