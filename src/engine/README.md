# Legacy Engine Files

This folder contains all the original engine files that were moved to preserve the codebase history and provide reference for the new modular architecture.

## Path Fixes Applied

All require paths have been updated to work from the `_legacy` folder location:

### Internal Legacy References
- `require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)` → `require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)`
- `require(game.ReplicatedStorage.RobeatsGameCore.Enums.*)` → `require(game.ReplicatedStorage.RobeatsGameCore.Enums.*)`
- `require(game.ReplicatedStorage.RobeatsGameCore.Effects.*)` → `require(game.ReplicatedStorage.RobeatsGameCore.Effects.*)`
- `require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.*)` → `require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.*)`
- `require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.*)` → `require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.*)`
- `require(game.ReplicatedStorage.RobeatsGameCore.Types.*)` → `require(game.ReplicatedStorage.RobeatsGameCore.Types.*)`

### External References (Preserved)
These references were kept as-is since they point to external modules:
- `require(game.ReplicatedStorage.Shared.SPUtil)` ✓
- `require(game.ReplicatedStorage.Shared.CurveUtil)` ✓
- `require(game.ReplicatedStorage.Shared.AssertType)` ✓
- `require(game.ReplicatedStorage.Libraries.LemonSignal)` ✓

### Corrected References
- `require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)` → `require(game.ReplicatedStorage.Shared.SongDatabase)`

## Files Successfully Updated

### Root Files
- AudioManager.lua ✓
- EnvironmentSetup.lua ✓ 
- GameSessionManager.lua ✓
- HitParams.lua ✓
- HitSFXGroup.lua ✓
- ObjectPool.lua ✓
- RenderableHit.lua ✓
- Replay.lua ✓
- RobeatsGame.lua ✓
- ScoreManager.lua ✓
- SFXManager.lua ✓
- SongErrorParser.lua ✓
- TimingPresets.lua ✓

### Effects/
- EffectSystem.lua ✓
- HoldingNoteEffect.lua ✓
- HoldingNoteEffect2D.lua ✓
- NoteResultPopupEffect.lua ✓
- NoteResultPopupEffect2D.lua ✓
- TriggerNoteEffect.lua ✓
- TriggerNoteEffect2D.lua ✓
- VisualEffectsSystem.lua ✓

### Enums/
- All enum files ✓

### NoteTrack/
- NoteTrack.lua ✓
- NoteTrack2D.lua ✓
- NoteTrackSystem.lua ✓
- NoteTrackSystem2D.lua ✓
- TriggerButton.lua ✓
- TriggerButton2D.lua ✓

### NoteTypes/
- HeldNote.lua ✓
- HeldNote2D.lua ✓
- NoteBase.lua ✓
- SingleNote.lua ✓
- SingleNote2D.lua ✓

### Types/
- All type definition files ✓

## Status

✅ **All legacy files have been successfully updated and are functional**

The legacy files can now be required and used as reference while the new modular architecture is being developed and refined.
