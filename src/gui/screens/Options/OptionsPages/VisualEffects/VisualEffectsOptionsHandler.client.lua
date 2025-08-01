-- local Options = require(game.ReplicatedStorage.State.Options)
local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("VisualOptionsContainer")

-- Create a new OptionsHandler instance that will manage its own container
local _optionsHandler = OptionsHandler.new(container)

-- TODO: Implement options using the new OptionsHandler class
-- See OPTIONS_DOCUMENTATION.md for the list of options that should be implemented
--
-- Example implementations:
-- optionsHandler:createBoolOption("Hide Long Note Tails", Options.HideLongNoteTails)
-- optionsHandler:createBoolOption("Hide Receptor Glow", Options.HideReceptorGlow)
-- optionsHandler:createBoolOption("Show Hit Lighting", Options.ShowHitLighting)
-- optionsHandler:createBoolOption("Transparent Long Notes", Options.TransparentLongNotes)
-- optionsHandler:createIntOption("Receptor Transparency", Options.ReceptorTransparency, 10)
-- optionsHandler:createMultiselectOption("Judgement Visibility", Options.JudgementVisibility, {
--     "Perfect", "Marvelous", "Great", "Good", "Bad", "Miss"
-- })
