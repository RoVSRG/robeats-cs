local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local FX = require(ReplicatedStorage.Modules.FX)

local e = React.createElement

local gatoImages = {
	"70460952048890",
	"13979677676",
	"11176073563",
	"7545257075",
	"10090011252",
	"15172898181",
	"5906571674",
}

local function randomProps()
	return {
		Image = "rbxassetid://" .. gatoImages[math.random(1, #gatoImages)],
		Size = UDim2.new(0, math.random(100, 200), 0, math.random(100, 200)),
		Position = UDim2.new(0.7, 0, 0.5, 0) + UDim2.fromOffset(math.random(-100, 200), math.random(-10, 50)),
		Rotation = math.random(0, 360),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 10,
	}
end

local function Gato()
	local mountRef = React.useRef(nil)
	local currentRef = React.useRef(nil)
	local tickState, setTick = React.useState(0)

	React.useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				setTick(function(prev)
					return prev + 1
				end)
				task.wait(5)
			end
		end)
		return function()
			running = false
			if currentRef.current then
				currentRef.current:Destroy()
				currentRef.current = nil
			end
		end
	end, {})

	React.useEffect(function()
		if currentRef.current then
			currentRef.current:Destroy()
			currentRef.current = nil
		end

		local parent = mountRef.current
		if not parent then
			return
		end

		local button = Instance.new("ImageButton")
		local props = randomProps()
		for key, value in pairs(props) do
			button[key] = value
		end
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1

		button.MouseButton1Click:Once(function()
			FX.PlaySound("PartyHorn")
			button:Destroy()
			currentRef.current = nil
			print("You clicked the gato!")
		end)

		button.Parent = parent
		currentRef.current = button
	end, { tickState })

	return e(UI.Frame, {
		Name = "GatoMount",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = mountRef,
	})
end

return Gato
