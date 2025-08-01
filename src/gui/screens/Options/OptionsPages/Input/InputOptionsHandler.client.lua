-- local Options = require(game.ReplicatedStorage.State.Options)
local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("InputOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local _optionsHandler = OptionsHandler.new(container)

-- TODO: Implement options using the new OptionsHandler class
-- See OPTIONS_DOCUMENTATION.md for the list of options that should be implemented
--
-- Example implementations:
-- optionsHandler:createBoolOption("Hitsounds Enabled", Options.HitsoundsEnabled)
-- optionsHandler:createIntOption("Hitsound Volume", Options.HitsoundVolume, 5)
-- optionsHandler:createIntOption("Music Volume", Options.MusicVolume, 5)
-- Custom keybind interface would need to be implemented separately
