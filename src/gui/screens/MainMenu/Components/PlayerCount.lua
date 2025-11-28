local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

local function PlayerCount(props)
	local count, setCount = React.useState(0)

	React.useEffect(function()
		local function update()
			setCount(#Players:GetPlayers())
		end

		update()

		local added = Players.PlayerAdded:Connect(update)
		local removing = Players.PlayerRemoving:Connect(update)

		return function()
			added:Disconnect()
			removing:Disconnect()
		end
	end, {})

	local template = props.TextTemplate or "%d players online"

	return e(UI.TextLabel, {
		Text = string.format(template, count),
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		TextColor3 = props.TextColor3,
		Font = props.Font,
		TextSize = props.TextSize,
		TextScaled = props.TextScaled,
		TextXAlignment = props.TextXAlignment,
		TextStrokeTransparency = props.TextStrokeTransparency,
	})
end

return PlayerCount
