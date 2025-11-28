local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Util.UI)

local useState = React.useState
local useEffect = React.useEffect

local function PlayerCount(props)
	local count, setCount = useState(0)

	local position = props.Position or UDim2.new(0, 10, 0.95, 0)
	local size = props.Size or UDim2.new(0, 200, 0, 30)
	local anchorPoint = props.AnchorPoint
	local textScaled = props.TextScaled
	local textSize = props.TextSize or 14
	local textColor = props.TextColor3 or Color3.fromRGB(150, 150, 150)
	local font = props.Font or Enum.Font.Gotham
	local textAlignment = props.TextXAlignment or Enum.TextXAlignment.Center

	useEffect(function()
		local function update()
			setCount(#Players:GetPlayers())
		end
		
		update()
		
		local conn1 = Players.PlayerAdded:Connect(update)
		local conn2 = Players.PlayerRemoving:Connect(update)
		
		return function()
			conn1:Disconnect()
			conn2:Disconnect()
		end
	end, {})

	local template = props.TextTemplate or "%d players online"

	return UI.Text({
		Text = string.format(template, count),
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		TextColor3 = textColor,
		Font = font,
		TextSize = textSize,
		TextScaled = textScaled,
		TextXAlignment = textAlignment,
		TextStrokeTransparency = props.TextStrokeTransparency,
	})
end

return PlayerCount
