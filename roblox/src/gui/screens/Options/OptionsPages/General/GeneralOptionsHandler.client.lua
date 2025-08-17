local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("GeneralOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- Auto-register all General category options
optionsHandler:autoRegisterOptions("General")
