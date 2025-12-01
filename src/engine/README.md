# RoBeats Engine

A rhythm game engine for Roblox, based on the original RoBeats engine and modified to support osu!mania-like gameplay mechanics. This engine handles note spawning, hit detection, audio synchronization, visual effects, and score tracking.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Core Components](#core-components)
  - [RobeatsGame](#robeatsgame)
  - [AudioManager](#audiomanager)
  - [NoteTrackSystem](#notetracksystem)
  - [EffectsManager](#effectsmanager)
  - [SFXManager](#sfxmanager)
  - [ObjectPool](#objectpool)
- [Note System](#note-system)
  - [Note Types](#note-types)
  - [Note Lifecycle](#note-lifecycle)
  - [Hit Detection](#hit-detection)
- [Effects System](#effects-system)
- [Enums](#enums)
- [Configuration](#configuration)
- [Game Lifecycle](#game-lifecycle)
- [State Integration](#state-integration)
- [Replay System](#replay-system)
- [Timing System](#timing-system)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         RobeatsGame                              │
│  (Main controller - lifecycle, input, update loop)              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │  AudioManager   │  │  NoteTrackSystem │  │  EffectSystem  │ │
│  │  - Song loading │  │  - Note tracks   │  │  - Visual FX   │ │
│  │  - Timing sync  │  │  - Hit detection │  │  - Particles   │ │
│  │  - Note spawn   │  │  - Input routing │  │  - Popups      │ │
│  └────────┬────────┘  └────────┬─────────┘  └────────────────┘ │
│           │                    │                                 │
│           ▼                    ▼                                 │
│  ┌─────────────────────────────────────────┐                    │
│  │              Note Instances              │                    │
│  │  SingleNote, HeldNote (3D and 2D)       │                    │
│  └─────────────────────────────────────────┘                    │
│                        │                                         │
│                        ▼                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  External State                           │   │
│  │  GameStats (src/state/) ← Single source of truth         │   │
│  │  EffectsManager ← Visual/audio feedback                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Single Source of Truth**: All gameplay statistics live in `src/state/GameStats.lua`. The engine only writes to this module; it never reads from it for game logic.

2. **Separation of Concerns**:
   - `GameStats` handles stat tracking (score, combo, accuracy)
   - `EffectsManager` handles visual/audio feedback (popups, SFX, hold effects)
   - Notes call both when hits occur

3. **Object Pooling**: Notes are pooled and reused to minimize garbage collection.

4. **Dual Mode Support**: Full support for both 3D and 2D rendering modes.

---

## Core Components

### RobeatsGame

**File:** `RobeatsGame.lua`

The main game controller that orchestrates all other components. It manages the game lifecycle, processes input, and runs the update loop.

#### State Machine

```lua
RobeatsGame.State = {
    Idle = "idle",       -- Not playing, no song loaded
    Loading = "loading", -- Song and assets loading
    Ready = "ready",     -- Ready to start
    Playing = "playing", -- Game in progress
    Paused = "paused",   -- Game paused
    Finished = "finished" -- Game complete
}
```

#### Legacy Mode Enum (for compatibility)

```lua
RobeatsGame.Mode = {
    Setup = 1,     -- Loading/setup phase
    Game = 2,      -- Active gameplay
    GameEnded = 3  -- Game finished
}
```

#### Key Methods

| Method | Description |
|--------|-------------|
| `new(center_position)` | Creates a new game instance |
| `load(song_key, slot, replay?)` | Loads a song and prepares the game |
| `startGame(start_time_ms?)` | Begins gameplay |
| `pause()` | Pauses the game |
| `resume()` | Resumes from pause |
| `update(dt_scale)` | Main update loop (call every frame) |
| `teardown()` | Cleans up all resources |

#### Key Properties

| Property | Description |
|----------|-------------|
| `_tracksystems` | Dictionary of active NoteTrackSystem instances |
| `_audio_manager` | AudioManager instance |
| `_effects` | EffectSystem for visual effects |
| `_sfx_manager` | SFXManager for sound effects |
| `_object_pool` | ObjectPool for note recycling |

#### Configuration Getters/Setters

```lua
-- 2D Mode
game:get_2d_mode() / game:set_2d_mode(val)
game:get_skin() / game:set_skin(val)
game:is_upscroll() / game:set_upscroll_mode(val)

-- Visual Settings
game:get_note_color() / game:set_note_color(val)
game:get_ln_transparent() / game:set_ln_transparent(val)
game:get_hit_lighting() / game:set_hit_lighting(val)
game:get_ln_tails() / game:set_ln_tails(val)
game:get_ln_cut() / game:set_ln_cut(val)

-- Judgement Visibility
game:get_judgement_visibility() / game:set_judgement_visibility(val)

-- Mods
game:get_mods() / game:set_mods(val)
game:is_mod_active(mod)
```

---

### AudioManager

**File:** `AudioManager.lua`

Handles audio playback, timing synchronization, and note spawning based on song data.

#### Mode Enum

```lua
AudioManager.Mode = {
    NotLoaded = 0,   -- No audio loaded
    Loading = 1,     -- Audio loading
    PreStart = 3,    -- Pre-game countdown
    Playing = 4,     -- Audio playing
    PostPlaying = 5, -- Delay before game end
    Finished = 6     -- Audio finished
}
```

#### Key Methods

| Method | Description |
|--------|-------------|
| `load_song(song_key, config)` | Loads song audio and hit objects |
| `start_play(start_time_ms?)` | Starts playback |
| `pause()` | Pauses the BGM |
| `resume()` | Resumes the BGM |
| `update(dt_scale)` | Updates audio timing and spawns notes |
| `get_current_time_ms(no_offset?)` | Gets current playback time |
| `get_song_length_ms()` | Gets total song length |
| `get_note_prebuffer_time_ms()` | Gets note travel time |
| `get_note_result_timing()` | Gets timing windows |

#### Timing System

The AudioManager tracks time internally (`_bgm_time_position`) rather than relying solely on `Sound.TimePosition` for smoother 60fps updates.

```lua
-- Note spawn timing
local note_prebuffer_time = 13720 / scroll_speed -- milliseconds

-- Timing windows are OD-based (see TimingPresets.lua)
```

---

### NoteTrackSystem

**Files:** `NoteTrack/NoteTrackSystem.lua`, `NoteTrack/NoteTrackSystem2D.lua`

Manages the four note tracks and handles input routing to notes.

#### Key Methods

| Method | Description |
|--------|-------------|
| `get_track(index)` | Gets a track (1-4) |
| `get_notes()` | Gets the active notes list |
| `press_track_index(index, judgement?)` | Handles key press |
| `release_track_index(index, judgement?)` | Handles key release |
| `update(dt_scale)` | Updates all notes and tracks |

#### Input Flow

```
Key Press → NoteTrackSystem:press_track_index(index)
    │
    ├── Track:press() (visual feedback)
    │
    └── For each note in track:
        ├── note:test_hit()
        │   └── Returns: did_hit, note_result, renderable_hit
        │
        └── If hit: note:on_hit(result, i, renderable_hit)
            ├── GameStats.recordHit(result, params, renderable_hit)
            └── EffectsManager.playHitEffect(game, result, slot, track, params)
```

#### Ghost Taps

When no note is hit, a "ghost tap" miss is recorded:

```lua
if not hit_found then
    local params = HitParams:new()
        :set_ghost_tap(true)
        :set_whiff_miss(true)
    GameStats.recordHit(NoteResult.Miss, params)
    EffectsManager.playHitEffect(game, NoteResult.Miss, slot, track, params)
end
```

---

### EffectsManager

**File:** `EffectsManager.lua`

Handles all visual and audio feedback for note hits. Separated from stat tracking to maintain single responsibility.

#### Key Method

```lua
EffectsManager.playHitEffect(
    game,        -- RobeatsGame instance
    noteResult,  -- NoteResult enum value
    slotIndex,   -- Game slot (1-4)
    trackIndex,  -- Track (1-4)
    params       -- HitParams table
)
```

#### Parameters

```lua
params = {
    GhostTap = boolean,       -- Skip effects for ghost taps
    PlaySFX = boolean,        -- Play hit sounds
    PlayHoldEffect = boolean, -- Show hold lighting effect
    HoldEffectPosition = Vector3,
    IsHeldNoteBegin = boolean -- First vs alternating hitsound
}
```

#### Per-Frame State

Only one SFX plays per frame to prevent audio stacking:

```lua
function EffectsManager.update()
    _frameHasPlayedSfx = false
end
```

---

### SFXManager

**File:** `SFXManager.lua`

Manages pooled sound effects for efficient audio playback.

#### Sound Effect Constants

```lua
-- Hit sounds
SFXManager.SFX_HITFXG_DRUM_1/2
SFXManager.SFX_HITFXG_TAMB_1/2
SFXManager.SFX_HITFXG_HIHAT_1/2/3
SFXManager.SFX_HITFXG_CLAP_1/2
SFXManager.SFX_HITFXG_JAZZHH_1/2/3

-- Game sounds
SFXManager.SFX_MISS
SFXManager.SFX_COUNTDOWN_READY/GO
SFXManager.SFX_FANFARE
```

#### Key Methods

| Method | Description |
|--------|-------------|
| `preload(sfx_key, count, volume)` | Pre-pools sounds |
| `play_sfx(sfx_key, volume?)` | Plays a sound |
| `update()` | Recycles finished sounds |

---

### ObjectPool

**File:** `ObjectPool.lua`

Generic object pooling for note recycling.

```lua
pool:repool(key, obj)  -- Return to pool
pool:depool(key)       -- Get from pool (or nil if empty)
```

---

## Note System

### Note Types

| Type | File | Description |
|------|------|-------------|
| SingleNote | `NoteTypes/SingleNote.lua` | Single tap note (3D) |
| SingleNote2D | `NoteTypes/SingleNote2D.lua` | Single tap note (2D) |
| HeldNote | `NoteTypes/HeldNote.lua` | Long note / slider (3D) |
| HeldNote2D | `NoteTypes/HeldNote2D.lua` | Long note / slider (2D) |

### NoteBase Interface

All notes implement the `NoteBase` interface:

```lua
function self:update(dt_scale)       -- Update position/state
function self:should_remove()        -- Check if note should be removed
function self:do_remove()            -- Cleanup on removal
function self:test_hit()             -- Test if key press hits this note
function self:on_hit(result, i, hit) -- Handle successful hit
function self:test_release()         -- Test if key release matters
function self:on_release(result, i)  -- Handle key release
function self:get_track_index()      -- Get which track (1-4)
```

### Note Lifecycle

```
┌──────────┐    Spawned by AudioManager
│   Pre    │ ◄──────────────────────────
└────┬─────┘
     │ time passes...
     ▼
┌──────────┐    Player hits note
│  (Hit)   │ ───────────────────► on_hit() → recordHit() + playHitEffect()
└────┬─────┘
     │ For HeldNote:
     ▼
┌──────────┐    Player holds key
│ Holding  │
└────┬─────┘
     │ Hold end reached
     ▼
┌──────────┐    Player releases
│ (Release)│ ───────────────────► on_release() → recordHit()
└────┬─────┘
     │
     ▼
┌──────────┐
│ DoRemove │ ───────────────────► do_remove() → return to pool
└──────────┘
```

### Hit Detection

Notes use parametric `_t` to track progress along the track:
- `_t = 0`: Note at spawn position
- `_t = 1`: Note at hit position

```lua
-- Time remaining until note should be hit
function self:get_time_to_end()
    return (_hit_time_ms - _creation_time_ms) * (1 - _t)
end
```

The `NoteResult:timedelta_to_result()` function converts timing to judgement:

```lua
local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, game)
```

---

## Effects System

### EffectSystem

**File:** `Effects/EffectSystem.lua`

Container that manages all active visual effects.

```lua
-- EffectBase interface
function self:add_to_parent(parent)  -- Add to scene
function self:update(dt_scale)       -- Update animation
function self:should_remove()        -- Check if complete
function self:do_remove()            -- Cleanup
```

### Effect Types

| Effect | Files | Description |
|--------|-------|-------------|
| NoteResultPopup | `Effects/NoteResultPopupEffect.lua` | Judgement text (MARVELOUS, PERFECT, etc.) |
| NoteResultPopup2D | `Effects/NoteResultPopupEffect2D.lua` | 2D version |
| HoldingNoteEffect | `Effects/HoldingNoteEffect.lua` | Light while holding LN |
| HoldingNoteEffect2D | `Effects/HoldingNoteEffect2D.lua` | 2D version |
| TriggerNoteEffect | `Effects/TriggerNoteEffect.lua` | Hit spark/flash |
| TriggerNoteEffect2D | `Effects/TriggerNoteEffect2D.lua` | 2D version |
| VisualEffectsSystem | `Effects/VisualEffectsSystem.lua` | General visual effects |

---

## Enums

### NoteResult

**File:** `Enums/NoteResult.lua`

```lua
NoteResult = {
    Miss = 0,
    Bad = 1,
    Good = 2,
    Great = 3,
    Perfect = 4,
    Marvelous = 5
}
```

Each judgement has an associated color:

```lua
NoteResult.Colors = {
    [Miss] = Color3.fromRGB(190, 30, 30),      -- Red
    [Bad] = Color3.fromRGB(174, 22, 194),      -- Purple
    [Good] = Color3.fromRGB(12, 15, 151),      -- Blue
    [Great] = Color3.fromRGB(57, 192, 16),     -- Green
    [Perfect] = Color3.fromRGB(235, 220, 13),  -- Yellow
    [Marvelous] = Color3.fromRGB(255, 255, 255) -- White
}
```

### Grade

**File:** `Enums/Grade.lua`

```lua
Grade = {
    SS = 1,  -- 100%
    S = 2,   -- 95%+
    A = 3,   -- 90%+
    B = 4,   -- 80%+
    C = 5,   -- 70%+
    D = 6,   -- 60%+
    F = 7    -- <60%
}
```

### GameTrack

**File:** `Enums/GameTrack.lua`

```lua
GameTrack = {
    Track1 = 1,
    Track2 = 2,
    Track3 = 3,
    Track4 = 4
}
```

### GameSlot

**File:** `Enums/GameSlot.lua`

Supports up to 4 players with different camera/world positions:

```lua
GameSlot = {
    SLOT_1 = 1,
    SLOT_2 = 2,
    SLOT_3 = 3,
    SLOT_4 = 4
}
```

### Mods

**File:** `Enums/Mods.lua`

```lua
Mods = {
    Mirror = 1,  -- Flip tracks horizontally
    Sway = 2     -- Camera sway on key press
}
```

---

## Configuration

### HitParams

**File:** `HitParams.lua`

Builder pattern for hit parameters:

```lua
local params = HitParams:new()
    :set_play_sfx(true)
    :set_play_hold_effect(true, position)
    :set_held_note_begin(true)
    :set_time_miss(false)
    :set_whiff_miss(false)
    :set_ghost_tap(false)
```

| Property | Description |
|----------|-------------|
| `PlaySFX` | Play hit sound effect |
| `PlayHoldEffect` | Show hold lighting |
| `HoldEffectPosition` | Position for 3D hold effect |
| `IsHeldNoteBegin` | Is this the start of a held note? |
| `TimeMiss` | Miss caused by note expiring |
| `WhiffMiss` | Miss from pressing with no note |
| `GhostTap` | No visual effect, just stat tracking |

### TimingPresets

**File:** `TimingPresets.lua`

Calculates timing windows based on Overall Difficulty (OD):

```lua
TimingPresets.calculateTimingWindows(od)
-- Returns:
{
    NoteMarvelousMaxMS = 16,      -- Constant
    NotePerfectMaxMS = 64 - 3*od,
    NoteGreatMaxMS = 97 - 3*od,
    NoteGoodMaxMS = 127 - 3*od,
    NoteBadMaxMS = 151 - 3*od,
    -- Min values are negative of max
}
```

---

## Game Lifecycle

### Initialization

```lua
-- 1. Create game instance
local game = RobeatsGame.new(center_position)

-- 2. Load song
game:load(song_key, player_slot, replay?)
-- State: Idle → Loading → Ready

-- 3. Start game (after loading complete)
game:startGame(start_time_ms?)
-- State: Ready → Playing
```

### Update Loop

```lua
-- Every frame in your game loop:
game:update(dt_scale)
```

The update loop handles:
1. Audio timing updates
2. Note spawning (via AudioManager)
3. Input processing
4. Note updates and removal
5. Effect updates
6. SFX cleanup
7. Game end detection

### Pause/Resume

```lua
game:pause()   -- Playing → Paused
game:resume()  -- Paused → Playing
```

### Teardown

```lua
game:teardown()
-- Cleans up:
-- - All tracksystems and notes
-- - Audio manager
-- - Effects
-- - SFX
-- - Input handlers
-- - Environment (2D/3D)
```

---

## State Integration

### GameStats (src/state/GameStats.lua)

The engine writes to `GameStats` for all score tracking. This module uses Val for reactive state that UI can subscribe to.

#### Writing from Engine

```lua
-- In note files:
local GameStats = require(ReplicatedStorage.State.GameStats)

-- Record a hit
GameStats.recordHit(noteResult, params, renderableHit)

-- Reset for new game (called by RobeatsGame:startGame)
GameStats.reset()
```

#### Val-Wrapped State

```lua
-- Core stats
GameStats.score      -- Val<number>
GameStats.combo      -- Val<number>
GameStats.maxCombo   -- Val<number>

-- Judgement counts
GameStats.marvelous  -- Val<number>
GameStats.perfect    -- Val<number>
GameStats.great      -- Val<number>
GameStats.good       -- Val<number>
GameStats.bad        -- Val<number>
GameStats.miss       -- Val<number>

-- Computed values (auto-update)
GameStats.accuracy   -- Val<number> (0-100)
GameStats.grade      -- Val<string> (SS, S, A, etc.)
GameStats.rating     -- Val<number>
```

---

## Replay System

**File:** `Replay.lua`

Records and plays back game inputs.

### Recording

```lua
local replay = Replay:new({ viewing = false })

-- Add hits during gameplay
replay:add_replay_hit(time_ms, track, action, judgement, scoreData)
```

### Playback

```lua
local replay = Replay:new({ viewing = true })
replay:set_hits(recorded_hits)

-- During update, get actions for current time
local actions = replay:get_actions_this_frame(current_time_ms)
for _, action in actions do
    if action.action == Replay.HitType.Press then
        tracksystem:press_track_index(action.track, action.judgement)
    end
end
```

---

## Timing System

### RenderableHit

**File:** `RenderableHit.lua`

Captures hit timing data for display and statistics:

```lua
local hit = RenderableHit:new(hit_time_ms, time_left, judgement)
-- Returns:
{
    hit_object_time = hit_time_ms + time_left,  -- When note was actually hit
    time_left = time_left,                       -- Timing deviation (+ early, - late)
    judgement = judgement                        -- NoteResult enum value
}
```

### Note Spawn Timing

Notes are spawned when:
```lua
current_time_ms + prebuffer_time >= hit_object.Time
```

The prebuffer time is calculated from scroll speed:
```lua
prebuffer_time_ms = 13720 / scroll_speed
```

---

## Environment Setup

**File:** `EnvironmentSetup.lua`

Manages the game world setup for both 2D and 3D modes.

### Key Methods

| Method | Description |
|--------|-------------|
| `initial_setup()` | One-time initialization |
| `set_mode(mode)` | Switch between Menu/Game mode |
| `setup_2d_environment(skin, config)` | Initialize 2D playfield |
| `teardown_2d_environment()` | Clean up 2D elements |
| `create_dynamic_floor(...)` | Create 3D floor geometry |
| `get_game_environment_center_position()` | World center point |
| `get_element_protos_folder()` | Template objects |
| `get_local_elements_folder()` | Active game objects |
| `get_player_gui_root()` | ScreenGui for 2D elements |

---

## File Structure

```
src/engine/
├── RobeatsGame.lua          # Main game controller
├── AudioManager.lua         # Audio and note spawning
├── EffectsManager.lua       # Hit effect coordinator
├── SFXManager.lua           # Sound effect pooling
├── ObjectPool.lua           # Object recycling
├── RenderableHit.lua        # Hit timing data
├── Replay.lua               # Input recording/playback
├── HitParams.lua            # Hit parameter builder
├── HitSFXGroup.lua          # Hitsound groups
├── EnvironmentSetup.lua     # World setup
├── TimingPresets.lua        # OD-based timing windows
├── SongErrorParser.lua      # Song data error handling
│
├── NoteTrack/
│   ├── NoteTrackSystem.lua     # 3D track system
│   ├── NoteTrackSystem2D.lua   # 2D track system
│   ├── NoteTrack.lua           # Single 3D track
│   ├── NoteTrack2D.lua         # Single 2D track
│   ├── TriggerButton.lua       # 3D receptor
│   └── TriggerButton2D.lua     # 2D receptor
│
├── NoteTypes/
│   ├── NoteBase.lua         # Base interface
│   ├── SingleNote.lua       # 3D tap note
│   ├── SingleNote2D.lua     # 2D tap note
│   ├── HeldNote.lua         # 3D long note
│   └── HeldNote2D.lua       # 2D long note
│
├── Effects/
│   ├── EffectSystem.lua            # Effect container
│   ├── VisualEffectsSystem.lua     # Visual effects
│   ├── NoteResultPopupEffect.lua   # 3D judgement popup
│   ├── NoteResultPopupEffect2D.lua # 2D judgement popup
│   ├── HoldingNoteEffect.lua       # 3D hold lighting
│   ├── HoldingNoteEffect2D.lua     # 2D hold lighting
│   ├── TriggerNoteEffect.lua       # 3D hit spark
│   └── TriggerNoteEffect2D.lua     # 2D hit spark
│
├── Enums/
│   ├── NoteResult.lua       # Judgement enum
│   ├── Grade.lua            # Grade enum
│   ├── GameTrack.lua        # Track enum
│   ├── GameSlot.lua         # Player slot enum
│   ├── Mods.lua             # Mod enum
│   └── ReplayType.lua       # Replay type enum
│
└── Types/
    └── Config.lua           # Type definitions
```

---

## Example Usage

### Basic Game Setup

```lua
local RobeatsGame = require(ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local EnvironmentSetup = require(ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

-- Initial setup (once)
EnvironmentSetup:initial_setup()

-- Create game
local center = EnvironmentSetup:get_game_environment_center_position()
local game = RobeatsGame.new(center)

-- Load song
game:load(song_key, GameSlot.SLOT_1)

-- Wait for ready, then start
game:getStateChanged():Connect(function(newState)
    if newState == RobeatsGame.State.Ready then
        game:startGame()
    elseif newState == RobeatsGame.State.Finished then
        local results = GameStats.getResults()
        print("Final score:", results.score)
        game:teardown()
    end
end)

-- Update loop
RunService.RenderStepped:Connect(function(dt)
    game:update(dt)
end)
```

### Subscribing to Stats (UI)

```lua
local GameStats = require(ReplicatedStorage.State.GameStats)
local useVal = require(ReplicatedStorage.hooks.useVal)

-- In a React component:
local function ScoreDisplay()
    local score = useVal(GameStats.score)
    local combo = useVal(GameStats.combo)
    local accuracy = useVal(GameStats.accuracy)

    return React.createElement("TextLabel", {
        Text = string.format("Score: %d | Combo: %d | Acc: %.2f%%",
            score, combo, accuracy)
    })
end
```
