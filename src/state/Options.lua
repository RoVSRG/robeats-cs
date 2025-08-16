local Val = require(game.ReplicatedStorage.Libraries.Val)

local Options = Val.scope {
    -- Input Settings
    Keybind1 = Val.new("A"),
    Keybind2 = Val.new("S"),
    Keybind3 = Val.new("Y"),
    Keybind4 = Val.new("U"),

    -- Gameplay Settings
    ScrollSpeed = Val.new(23):asOption({
        type = "int",
        displayName = "Note Speed",
        category = "General",
        increment = 1,
        min = 1,
        max = 100
    }),
    AudioOffset = Val.new(0):asOption({
        type = "int",
        displayName = "Audio Offset",
        category = "General",
        increment = 1,
        min = -1000,
        max = 1000
    }),
    HitOffset = Val.new(0):asOption({
        type = "int",
        displayName = "Hit Offset",
        category = "General",
        increment = 1,
        min = -1000,
        max = 1000
    }),
    TimingPreset = Val.new("Standard"):asOption({
        type = "radio",
        displayName = "Timing Preset",
        category = "General",
        selection = {"Standard", "Strict"}
    }),
    LaneCoverEnabled = Val.new(false):asOption({
        type = "bool",
        displayName = "Lane Cover Enabled",
        category = "General"
    }),
    LaneCoverPct = Val.new(0):asOption({
        type = "int",
        displayName = "Lane Cover Height",
        category = "General",
        increment = 1,
        min = 0,
        max = 100
    }),
    Mods = Val.new({}), -- Array of active mods
    
    -- Visual Settings - 2D Mode
    Use2DMode = Val.new(false):asOption({
        type = "bool",
        displayName = "2D Enabled",
        category = "2D"
    }),
    Skin2D = Val.new(nil), -- 2D skin name (nil = auto-select)
    Upscroll = Val.new(false):asOption({
        type = "bool",
        displayName = "Use Upscroll",
        category = "2D"
    }),
    NoteColor = Val.new(Color3.fromRGB(246, 253, 139)), -- Note color
    NoteColorAffects2D = Val.new(true):asOption({
        type = "bool",
        displayName = "Inherit 3D Note Color",
        category = "2D"
    }),
    
    -- Visual Settings - Effects
    HideReceptorGlow = Val.new(false):asOption({
        type = "bool",
        displayName = "Hide Receptor Glow",
        category = "VisualEffects"
    }),
    ReceptorTransparency = Val.new(0):asOption({
        type = "int",
        displayName = "Receptor Transparency",
        category = "VisualEffects",
        increment = 10,
        min = 0,
        max = 100
    }),
    LnTransparency = Val.new(false):asOption({
        type = "bool",
        displayName = "Transparent Long Notes",
        category = "VisualEffects"
    }),
    HideLnTails = Val.new(true):asOption({
        type = "bool",
        displayName = "Hide Long Note Tails",
        category = "VisualEffects"
    }),
    ShowHitLighting = Val.new(false):asOption({
        type = "bool",
        displayName = "Show Hit Lighting",
        category = "VisualEffects"
    }),

    -- Judgement Visibility
    ShowMarvelous = Val.new(true),
    ShowPerfect = Val.new(true),
    ShowGreat = Val.new(true),
    ShowGood = Val.new(true),
    ShowBad = Val.new(true),
    ShowMiss = Val.new(true),
    
    -- Audio Settings
    Hitsounds = Val.new(true):asOption({
        type = "bool",
        displayName = "Hitsounds Enabled",
        category = "Input"
    }),
    HitsoundVolume = Val.new(0.5):asOption({
        type = "int",
        displayName = "Hitsound Volume",
        category = "Input",
        increment = 5,
        min = 0,
        max = 100
    }),
    MusicVolume = Val.new(0.5):asOption({
        type = "int",
        displayName = "Music Volume",
        category = "Input",
        increment = 5,
        min = 0,
        max = 100
    }),
    
    -- Advanced Settings
    StartTimeMs = Val.new(0), -- Start time in milliseconds
    GameSlot = Val.new(0), -- Game slot for multiplayer
    RecordReplay = Val.new(false), -- Record replay data
}

type TimingPreset = "Standard" | "Strict" 

Options.setTimingPreset = function(preset: TimingPreset)
    if preset == "Standard" or preset == "Strict" then
        Options.TimingPreset:set(preset)
    else
        error("Invalid timing preset: " .. tostring(preset))
    end
end

return Options