local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("InputOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- Auto-register all Input category options
optionsHandler:autoRegisterOptions("Input")
