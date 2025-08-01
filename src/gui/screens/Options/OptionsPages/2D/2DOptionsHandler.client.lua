local Options = require(game.ReplicatedStorage.State.Options)
local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("2DOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- TODO: Implement options using the new OptionsHandler class
-- See OPTIONS_DOCUMENTATION.md for the list of options that should be implemented
-- 
-- Example:
optionsHandler:createBoolOption("2D Enabled", Options.Use2DMode)
optionsHandler:createBoolOption("Inherit 3D Note Color", Options.NoteColorAffects2D)
optionsHandler:createBoolOption("Use Upscroll", Options.Upscroll)