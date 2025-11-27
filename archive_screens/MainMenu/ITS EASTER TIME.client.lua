-- These are just some fun easter eggs :3

local Element = require(game.ReplicatedStorage.Element)
local Time = require(game.ReplicatedStorage.Libraries.Time)
local FX = require(game.ReplicatedStorage.Modules.FX)

local Container = script.Parent

local elGato: ImageButton? = nil

local gatoImages = {
	"70460952048890",
	"13979677676",
	"11176073563",
	"7545257075",
	"10090011252",
	"15172898181",
	"5906571674",
}

local function operationSilly()
	if elGato then
		return
	end

	local image = Element.new("ImageButton", {
		Image = "rbxassetid://" .. gatoImages[math.random(1, #gatoImages)],
		Size = UDim2.new(0, math.random(100, 200), 0, math.random(100, 200)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.7, 0, 0.5, 0) + UDim2.fromOffset(math.random(-100, 200), math.random(-10, 50)),
		Rotation = math.random(0, 360),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 10,
	})

	image.MouseButton1Click:Once(function()
		FX.PlaySound("PartyHorn")

		image:Destroy()
		elGato = nil
		print("You clicked the gato!")
	end)

	image.Parent = Container

	elGato = image
end

Time.setInterval(operationSilly, 5)
