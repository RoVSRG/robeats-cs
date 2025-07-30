local Val = require(game.ReplicatedStorage.Libraries.Val)

local Options = Val.scope {
    -- Input Settings
    Keybind1 = Val.new("A"),
    Keybind2 = Val.new("S"),
    Keybind3 = Val.new("Y"),
    Keybind4 = Val.new("U"),

    -- Gameplay Settings
    ScrollSpeed = Val.new(23), -- Note speed (1.0 is normal speed)
    AudioOffset = Val.new(0), -- Audio offset in milliseconds
    HitOffset = Val.new(0), -- Hit offset in milliseconds
    TimingPreset = Val.new("Standard"), -- Timing window preset
    Mods = Val.new({}), -- Array of active mods
    
    -- Visual Settings - 2D Mode
    Use2DMode = Val.new(false), -- Use 2D lane instead of 3D
    Skin2D = Val.new(nil), -- 2D skin name (nil = auto-select)
    Upscroll = Val.new(false), -- Upscroll mode for 2D
    NoteColor = Val.new(Color3.fromRGB(246, 253, 139)), -- Note color
    NoteColorAffects2D = Val.new(true), -- Whether note color affects 2D notes
    
    -- Visual Settings - Effects
    HideReceptorGlow = Val.new(false), -- Hide receptor glow effect
    ReceptorTransparency = Val.new(0), -- Receptor transparency (0-1)
    LnTransparency = Val.new(false), -- Long note transparency
    HideLnTails = Val.new(true), -- Hide long note tails
    ShowHitLighting = Val.new(false), -- Show hit lighting effects

    -- Judgement Visibility
    ShowMarvelous = Val.new(true),
    ShowPerfect = Val.new(true),
    ShowGreat = Val.new(true),
    ShowGood = Val.new(true),
    ShowBad = Val.new(true),
    ShowMiss = Val.new(true),
    
    -- Audio Settings
    Hitsounds = Val.new(true), -- Enable hitsounds
    HitsoundVolume = Val.new(0.5), -- Hitsound volume (0-1)
    MusicVolume = Val.new(0.5), -- Music volume (0-1)
    
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