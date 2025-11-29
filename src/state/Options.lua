local Val = require(game.ReplicatedStorage.Libraries.Val)

local Options = {
	-- Input Settings
	Keybind1 = Val.new("A"):asOption({
		type = "keybind",
		displayName = "Lane 1 Key",
		category = "Input",
		layoutOrder = 1,
	}),
	Keybind2 = Val.new("S"):asOption({
		type = "keybind",
		displayName = "Lane 2 Key",
		category = "Input",
		layoutOrder = 2,
	}),
	Keybind3 = Val.new("Y"):asOption({
		type = "keybind",
		displayName = "Lane 3 Key",
		category = "Input",
		layoutOrder = 3,
	}),
	Keybind4 = Val.new("U"):asOption({
		type = "keybind",
		displayName = "Lane 4 Key",
		category = "Input",
		layoutOrder = 4,
	}),

	-- Gameplay Settings
	ScrollSpeed = Val.new(23):asOption({
		type = "int",
		displayName = "Note Speed",
		category = "General",
		increment = 1,
		min = 1,
		max = 100,
		layoutOrder = 1,
	}),
	AudioOffset = Val.new(0):asOption({
		type = "int",
		displayName = "Audio Offset",
		category = "General",
		increment = 1,
		min = -1000,
		max = 1000,
		layoutOrder = 2,
	}),
	HitOffset = Val.new(0):asOption({
		type = "int",
		displayName = "Hit Offset",
		category = "General",
		increment = 1,
		min = -1000,
		max = 1000,
		layoutOrder = 3,
	}),
	OverallDifficulty = Val.new(8):asOption({
		type = "int",
		displayName = "Overall Difficulty (OD)",
		category = "General",
		increment = 1,
		min = 0,
		max = 10,
		layoutOrder = 4,
	}),
	Mods = Val.new({}), -- Array of active mods

	-- Visual Settings - 2D Mode
	Use2DMode = Val.new(false):asOption({
		type = "bool",
		displayName = "2D Enabled",
		category = "2D",
		layoutOrder = 1,
	}),
	Skin2D = Val.new(nil), -- 2D skin name (nil = auto-select)
	Upscroll = Val.new(false):asOption({
		type = "bool",
		displayName = "Use Upscroll",
		category = "2D",
		layoutOrder = 2,
	}),
	NoteColor = Val.new(Color3.fromRGB(246, 253, 139)), -- Note color
	NoteColorAffects2D = Val.new(true):asOption({
		type = "bool",
		displayName = "Inherit 3D Note Color",
		category = "2D",
		layoutOrder = 3,
	}),

	-- Visual Settings - Effects
	LnCut = Val.new(0):asOption({
		type = "int",
		displayName = "Long Note Cut (ms)",
		category = "VisualEffects",
		increment = 10,
		min = 0,
		max = 500,
		layoutOrder = 1,
	}),
	LaneCoverEnabled = Val.new(false):asOption({
		type = "bool",
		displayName = "Lane Cover Enabled",
		category = "VisualEffects",
		layoutOrder = 2,
	}),
	LaneCoverPct = Val.new(0):asOption({
		type = "int",
		displayName = "Lane Cover Height",
		category = "VisualEffects",
		increment = 1,
		min = 0,
		max = 100,
		layoutOrder = 3,
	}),
	HideReceptorGlow = Val.new(false):asOption({
		type = "bool",
		displayName = "Hide Receptor Glow",
		category = "VisualEffects",
		layoutOrder = 4,
	}),
	ReceptorTransparency = Val.new(0):asOption({
		type = "int",
		displayName = "Receptor Transparency",
		category = "VisualEffects",
		increment = 10,
		min = 0,
		max = 100,
		layoutOrder = 5,
	}),
	LnTransparency = Val.new(false):asOption({
		type = "bool",
		displayName = "Transparent Long Notes",
		category = "VisualEffects",
		layoutOrder = 6,
	}),
	HideLnTails = Val.new(true):asOption({
		type = "bool",
		displayName = "Hide Long Note Tails",
		category = "VisualEffects",
		layoutOrder = 7,
	}),
	ShowHitLighting = Val.new(false):asOption({
		type = "bool",
		displayName = "Show Hit Lighting",
		category = "VisualEffects",
		layoutOrder = 8,
	}),

	-- Judgement Visibility
	ShowMarvelous = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Marvelous Judgements",
		category = "VisualEffects",
		layoutOrder = 9,
	}),
	ShowPerfect = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Perfect Judgements",
		category = "VisualEffects",
		layoutOrder = 10,
	}),
	ShowGreat = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Great Judgements",
		category = "VisualEffects",
		layoutOrder = 11,
	}),
	ShowGood = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Good Judgements",
		category = "VisualEffects",
		layoutOrder = 12,
	}),
	ShowBad = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Bad Judgements",
		category = "VisualEffects",
		layoutOrder = 13,
	}),
	ShowMiss = Val.new(true):asOption({
		type = "bool",
		displayName = "Show Miss Judgements",
		category = "VisualEffects",
		layoutOrder = 14,
	}),

	-- Audio Settings
	Hitsounds = Val.new(true):asOption({
		type = "bool",
		displayName = "Hitsounds Enabled",
		category = "Input",
		layoutOrder = 5,
	}),
	HitsoundVolume = Val.new(50):asOption({
		type = "int",
		displayName = "Hitsound Volume",
		category = "Input",
		increment = 5,
		min = 0,
		max = 100,
		layoutOrder = 6,
	}),
	MusicVolume = Val.new(50):asOption({
		type = "int",
		displayName = "Music Volume",
		category = "Input",
		increment = 5,
		min = 0,
		max = 100,
		layoutOrder = 7,
	}),

	-- Advanced Settings
	StartTimeMs = Val.new(0), -- Start time in milliseconds
	GameSlot = Val.new(0), -- Game slot for multiplayer
	RecordReplay = Val.new(false), -- Record replay data
}

return Options
