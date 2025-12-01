--[[
	EffectsManager - Handles visual and audio effects for gameplay

	Separated from stat tracking to maintain single responsibility.
	Called by note files when hits occur to display judgement popups,
	play hit sounds, and show hold effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NoteResult = require(ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(ReplicatedStorage.RobeatsGameCore.SFXManager)
local NoteResultPopupEffect = require(ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect)
local NoteResultPopupEffect2D = require(ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect2D)
local HoldingNoteEffect = require(ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local HoldingNoteEffect2D = require(ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect2D)

local EffectsManager = {}

-- Per-frame state to prevent multiple SFX playing in the same frame
local _frameHasPlayedSfx = false

--[[
	Reset per-frame state. Should be called once per frame in the game update loop.
]]
function EffectsManager.update()
	_frameHasPlayedSfx = false
end

--[[
	Play visual and audio effects for a hit.

	@param game - The RobeatsGame instance
	@param noteResult - The judgement (NoteResult enum)
	@param slotIndex - The game slot index
	@param trackIndex - The note track index
	@param params - Hit parameters table with:
		- GhostTap: boolean - Was this a ghost tap (no note)?
		- PlaySFX: boolean - Should we play hit sounds?
		- PlayHoldEffect: boolean - Should we show hold effect?
		- HoldEffectPosition: Vector3 - Position for 3D hold effect
		- IsHeldNoteBegin: boolean - Is this the start of a held note?
]]
function EffectsManager.playHitEffect(
	game: any,
	noteResult: number,
	slotIndex: number,
	trackIndex: number,
	params: {
		GhostTap: boolean?,
		PlaySFX: boolean?,
		PlayHoldEffect: boolean?,
		HoldEffectPosition: Vector3?,
		IsHeldNoteBegin: boolean?,
	}?
)
	params = params or {}

	-- Early return for ghost taps - no visual effects needed
	if params.GhostTap then
		return
	end

	local tracksystem = game:get_tracksystem(slotIndex)
	if not tracksystem then
		return
	end

	local track = tracksystem:get_track(trackIndex)
	if not track then
		return
	end

	-- Show judgement popup (if judgement is visible)
	if game:get_judgement_visibility()[noteResult] then
		if game:get_2d_mode() then
			game._effects:add_effect(NoteResultPopupEffect2D:new(game, noteResult))
		else
			game._effects:add_effect(
				NoteResultPopupEffect:new(game, track:get_end_position() + Vector3.new(0, 0.25, 0), noteResult)
			)
		end
	end

	-- Play hit sound effects
	if params.PlaySFX == true and game._audio_manager:get_hitsounds() then
		-- Only one SFX per frame
		if not _frameHasPlayedSfx then
			if noteResult ~= NoteResult.Miss then
				if params.IsHeldNoteBegin == true then
					game._audio_manager:get_hit_sfx_group():play_first()
				else
					game._audio_manager:get_hit_sfx_group():play_alternating()
				end
			else
				game._sfx_manager:play_sfx(SFXManager.SFX_MISS)
			end
			_frameHasPlayedSfx = true
		end

		-- Show hold effect if requested
		if params.PlayHoldEffect then
			if noteResult ~= NoteResult.Miss then
				if game:get_2d_mode() then
					game._effects:add_effect(HoldingNoteEffect2D:new(game, trackIndex))
				else
					game._effects:add_effect(HoldingNoteEffect:new(game, params.HoldEffectPosition, noteResult))
				end
			end
		end
	end
end

return EffectsManager
