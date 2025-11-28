local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Util.UI)
local FX = require(ReplicatedStorage.Modules.FX)

local gatoImages = {
	"70460952048890",
	"13979677676",
	"11176073563",
	"7545257075",
	"10090011252",
	"15172898181",
	"5906571674",
}

local function randomGatoProps()
	return {
		Image = "rbxassetid://" .. gatoImages[math.random(1, #gatoImages)],
		Size = UDim2.new(0, math.random(100, 200), 0, math.random(100, 200)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.7, 0, 0.5, 0) + UDim2.fromOffset(math.random(-100, 200), math.random(-10, 50)),
		Rotation = math.random(0, 360),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 10,
	}
end

local function Gato()
	local mountRef = React.useRef(nil)
	local elementRef = React.useRef(nil)
	local spawnTicker, setSpawnTicker = React.useState(0)

	React.useEffect(function()
		local running = true

		local function loop()
			while running do
				setSpawnTicker(function(prev)
					return prev + 1
				end)
				task.wait(5)
			end
		end

		task.spawn(loop)

		return function()
			running = false
			if elementRef.current then
				elementRef.current:Destroy()
				elementRef.current = nil
			end
		end
	end, {})

	React.useEffect(function()
		if elementRef.current then
			elementRef.current:Destroy()
			elementRef.current = nil
		end
		local button = Instance.new("ImageButton")
		local props = randomGatoProps()
		for key, value in pairs(props) do
			button[key] = value
		end

		button.MouseButton1Click:Once(function()
			FX.PlaySound("PartyHorn")
			button:Destroy()
			elementRef.current = nil
			print("You clicked the gato!")
		end)

		button.Parent = mountRef.current
		elementRef.current = button
	end, { spawnTicker })

	return UI.Frame({
		Name = "GatoMount",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ref = mountRef,
	})
end

return Gato
