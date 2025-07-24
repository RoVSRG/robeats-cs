# Rhythm Game Engine Architecture Redesign

## Core Principles
1. **Single Responsibility**: Each module has one clear purpose
2. **Dependency Injection**: Components receive their dependencies explicitly
3. **Interface Segregation**: Small, focused interfaces instead of god objects
4. **Mode Abstraction**: 2D/3D differences handled through strategy pattern

## New Component Structure

### 1. Core Engine (`src/engine/core/`)
```
GameEngine.lua           -- Main coordinator, minimal logic
GameConfig.lua          -- Configuration management
GameState.lua           -- State machine (Setup -> Playing -> Ended)
EventBus.lua            -- Decoupled communication between components
```

### 2. Audio System (`src/engine/audio/`)
```
AudioManager.lua        -- Pure audio playback and timing
SongLoader.lua          -- Song data loading and parsing
TimingEngine.lua        -- Note timing calculations and windows
HitSoundManager.lua     -- Hit sound effects
```

### 3. Note System (`src/engine/notes/`)
```
NoteFactory.lua         -- Creates notes based on chart data
NoteScheduler.lua       -- Spawns notes at correct times
NoteLifecycle.lua       -- Note update/removal logic
HitDetection.lua        -- Hit testing logic
```

### 4. Playfield System (`src/engine/playfield/`)
```
PlayfieldRenderer.lua   -- Abstract base for visual rendering
Playfield3D.lua         -- 3D playfield implementation
Playfield2D.lua         -- 2D playfield implementation
TrackManager.lua        -- Track state and input handling  
```

### 5. Scoring System (`src/engine/scoring/`)
```
ScoreCalculator.lua     -- Pure score calculation logic
JudgementSystem.lua     -- Hit judgement and feedback
ComboTracker.lua        -- Combo/chain tracking
```

### 6. Input System (`src/engine/input/`)
```
InputManager.lua        -- Input capture and processing
KeyBinding.lua          -- Key mapping configuration
```

## Example Interface Definitions

### GameEngine (Main Coordinator)
```lua
export type GameEngine = {
    -- Core lifecycle
    initialize: (config: Config.GameConfig) -> (),
    loadSong: (songKey: string) -> (),
    startGame: () -> (),
    update: (deltaTime: number) -> (),
    cleanup: () -> (),
    
    -- State queries
    getState: () -> GameState.State,
    getScore: () -> number,
    getAccuracy: () -> number,
}
```

### PlayfieldRenderer (Strategy Interface)
```lua
export type PlayfieldRenderer = {
    -- Visual management
    setup: (tracks: number, config: Config.GameConfig) -> (),
    spawnNote: (note: NoteData) -> (),
    updateNote: (noteId: string, position: Vector3) -> (),
    removeNote: (noteId: string) -> (),
    
    -- Input feedback
    pressTrack: (trackIndex: number) -> (),
    releaseTrack: (trackIndex: number) -> (),
    
    -- Effects
    showHitEffect: (trackIndex: number, judgement: Judgement) -> (),
    cleanup: () -> (),
}
```

### TimingEngine (Pure Logic)
```lua
export type TimingEngine = {
    -- Timing calculations
    calculateNoteSpawnTime: (noteTime: number, speed: number) -> number,
    calculateHitWindow: (judgement: Judgement) -> (number, number),
    isNoteHittable: (noteTime: number, currentTime: number) -> boolean,
    
    -- Pure functions, no side effects
    getJudgement: (timeDelta: number) -> Judgement,
}
```

## Benefits of This Approach

1. **Testability**: Each component can be unit tested in isolation
2. **Maintainability**: Changes to 2D rendering don't affect audio logic
3. **Type Safety**: Clear interfaces make type checking work properly
4. **Flexibility**: Easy to add new playfield modes or scoring systems
5. **Debugging**: Issues are isolated to specific components
6. **Performance**: Only load what you need (3D vs 2D components)

## Migration Strategy

1. **Phase 1**: Extract pure logic components (TimingEngine, ScoreCalculator)
2. **Phase 2**: Create playfield abstraction and implementations
3. **Phase 3**: Refactor AudioManager to be purely audio-focused
4. **Phase 4**: Implement EventBus for component communication
5. **Phase 5**: Create new GameEngine coordinator
6. **Phase 6**: Remove old god objects

## Example: Clean AudioManager
```lua
local AudioManager = {}

function AudioManager:new(eventBus: EventBus.EventBus)
    local self = {}
    
    -- Only audio concerns
    local bgm: Sound
    local currentTime = 0
    local isPlaying = false
    
    function self:loadSong(songData: SongData)
        bgm = createSound(songData.audioId)
        eventBus:emit("audioLoaded", songData)
    end
    
    function self:play()
        bgm:Play()
        isPlaying = true
        eventBus:emit("audioStarted")
    end
    
    function self:update(deltaTime: number)
        if isPlaying then
            currentTime += deltaTime
            eventBus:emit("audioTimeUpdate", currentTime)
        end
    end
    
    function self:getCurrentTime(): number
        return currentTime
    end
    
    return self
end
```

This separates audio timing from note spawning, visual management, and scoring.
