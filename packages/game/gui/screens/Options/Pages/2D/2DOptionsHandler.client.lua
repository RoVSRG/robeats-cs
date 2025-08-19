local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("2DOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- Auto-register all 2D category options
optionsHandler:autoRegisterOptions("2D")