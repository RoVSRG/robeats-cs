local Options = require(game.ReplicatedStorage.State.Options)
local OptionsHandler = require(script.Parent.Parent.Parent.OptionsHandler)

local container = script.Parent:FindFirstChild("2DOptionsContainer")

OptionsHandler.createBoolOption("2D Enabled", Options.Use2DMode, container)
OptionsHandler.createBoolOption("Inherit 3D Note Color", Options.NoteColorAffects2D, container)
OptionsHandler.createBoolOption("Use Upscroll", Options.Upscroll, container)