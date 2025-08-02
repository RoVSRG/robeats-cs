local Options = require(game.ReplicatedStorage.State.Options)
local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("GeneralOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local optionsHandler = OptionsHandler.new(container)

-- TODO: Implement options using the new OptionsHandler class
-- See OPTIONS_DOCUMENTATION.md for the list of options that should be implemented
--
-- Example implementations:
optionsHandler:createIntOption("Audio Offset", Options.AudioOffset, 1)
-- optionsHandler:createIntOption("Field of View", Options.FieldOfView, 5)
-- optionsHandler:createIntOption("Hit Offset", Options.HitOffset, 1)
-- optionsHandler:createIntOption("Lane Cover", Options.LaneCover, 10)
-- optionsHandler:createBoolOption("Lane Cover Enabled", Options.LaneCoverEnabled)
optionsHandler:createIntOption("Note Speed", Options.ScrollSpeed, 1)
optionsHandler:createRadioOption("Timing Preset", Options.TimingPreset, {"Standard", "Strict"})
