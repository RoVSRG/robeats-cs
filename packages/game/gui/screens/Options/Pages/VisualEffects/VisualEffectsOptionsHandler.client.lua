local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("VisualOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- Auto-register all VisualEffects category options
optionsHandler:autoRegisterOptions("VisualEffects")
