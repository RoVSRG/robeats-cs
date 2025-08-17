--!strict

-- Configuration types for the Robeats game engine

export type GameConfig = {
	-- 2D Lane Configuration
	Use2DLane: boolean?,
	Skin2D: Instance?,
	
	-- Playfield Settings
	playfieldWidth: number?,
	playfieldHitPos: number?,
	upscroll: boolean?,
	
	-- Visual Settings
	ReceptorTransparency: number?,
	HideReceptorGlow: boolean?,
	
	-- Audio Settings
	GlobalAudioOffset: number?,
	SongRate: number,
	Hitsounds: boolean?,
	NoteSpeed: number?,
	
	-- Timing Settings
	UseCustomJudgements: boolean?,
	OverallDifficulty: number?,
	
	-- Custom Timing Presets (used when UseCustomJudgements is true)
	CustomMarvelousPreset: number?,
	CustomPerfectPreset: number?,
	CustomGreatPreset: number?,
	CustomGoodPreset: number?,
	CustomBadPreset: number?,
}

export type ReplayConfig = {
	viewing: boolean?,
}

return {}
