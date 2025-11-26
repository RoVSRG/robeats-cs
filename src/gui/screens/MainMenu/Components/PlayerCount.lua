local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function PlayerCount(props)
	local count, setCount = useState(0)

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

	return e("TextLabel", {
		Text = count .. " Players Online",
		Size = UDim2.new(0, 200, 0, 30),
		Position = props.Position or UDim2.new(0, 10, 0.95, 0), -- Bottom Left default
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(150, 150, 150),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

return PlayerCount
