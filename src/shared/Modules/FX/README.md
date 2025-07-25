# FX Sound Manager

A high-performance sound effect manager with object pooling for Roblox games. Designed to handle rapid-fire sound effects without performance degradation.

## Features

- **Object Pooling**: Reuses Sound instances to avoid creation/destruction overhead
- **Automatic Sound Mapping**: Pulls sound effects from `script.Sounds` module
- **Volume & Pitch Randomization**: Built-in variation support for more natural sounds
- **Configurable Pool Sizes**: Customize pool sizes per sound effect
- **Memory Management**: Automatic cleanup and timeout handling
- **Performance Monitoring**: Built-in statistics for debugging

## Quick Start

```lua
local SoundManager = require(path.to.FX)

-- Play a basic sound effect
SoundManager.PlaySound("Select")

-- Play with options
SoundManager.PlaySound("Back", {
    Volume = 0.7,
    Pitch = 1.2,
    VolumeVariation = 0.1,
    PitchVariation = 0.2
})
```

## API Reference

### Core Functions

#### `SoundManager.PlaySound(soundName, options)`
Plays a sound effect from the sound pool.

**Parameters:**
- `soundName` (string): Name of the sound from Sounds.lua
- `options` (table, optional): Configuration options
  - `Volume` (number): Volume level (0-1)
  - `Pitch` (number): Pitch level (0.1-3)
  - `VolumeVariation` (number): Random volume variation (±value)
  - `PitchVariation` (number): Random pitch variation (±value)

**Returns:** Sound instance or nil if failed

#### `SoundManager.StopSound(sound)`
Stops a specific sound instance and returns it to the pool.

#### `SoundManager.StopAllSounds(soundName)`
Stops all instances of a sound type, or all sounds if soundName is nil.

### Pool Management

#### `SoundManager.SetPoolSize(soundName, size)`
Sets the pool size for a specific sound effect.

#### `SoundManager.GetPoolStats(soundName)`
Returns pool statistics for debugging. If soundName is nil, returns stats for all pools.

### Quick Access Functions

#### `SoundManager.PlaySelect(options)`
Convenience function for playing the "Select" sound.

#### `SoundManager.PlayBack(options)`
Convenience function for playing the "Back" sound.

## Configuration

### Constants (can be modified at the top of init.lua)
- `DEFAULT_POOL_SIZE = 5`: Default number of Sound instances per pool
- `MAX_POOL_SIZE = 20`: Maximum pool size to prevent memory issues
- `CLEANUP_INTERVAL = 30`: Seconds between automatic cleanup cycles
- `SOUND_TIMEOUT = 10`: Seconds before a sound can be reused

## Sound Configuration

Add your sound effects to `Sounds.lua`:

```lua
return {
    Select = "rbxassetid://876939830",
    Back = "rbxassetid://138204323",
    Footstep = "rbxassetid://123456789",
    Explosion = "rbxassetid://987654321",
    -- Add more sounds here
}
```

## Performance Benefits

### Without Pooling (Traditional Approach)
```lua
-- This creates performance issues with rapid-fire sounds
for i = 1, 100 do
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://123456"
    sound.Parent = workspace
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy() -- Garbage collection overhead
    end)
end
```

### With Pooling (Our Approach)
```lua
-- This is smooth and efficient
for i = 1, 100 do
    SoundManager.PlaySound("Select") -- Reuses existing Sound instances
end
```

## Best Practices

1. **Set Appropriate Pool Sizes**: For frequently used sounds, increase pool size
   ```lua
   SoundManager.SetPoolSize("Footstep", 15)
   ```

2. **Use Variation for Natural Sound**: Add randomization to prevent repetitive audio
   ```lua
   SoundManager.PlaySound("Footstep", {
       VolumeVariation = 0.1,
       PitchVariation = 0.15
   })
   ```

3. **Monitor Pool Usage**: Use GetPoolStats() during development to optimize pool sizes
   ```lua
   local stats = SoundManager.GetPoolStats()
   for sound, data in pairs(stats) do
       if data.inUse > data.available then
           print("Consider increasing pool size for: " .. sound)
       end
   end
   ```

4. **Clean Up Long-Running Sounds**: For sounds that should be stopped manually
   ```lua
   local ambientSound = SoundManager.PlaySound("Ambient")
   -- Later...
   SoundManager.StopSound(ambientSound)
   ```

## Example Use Cases

- **UI Sound Effects**: Button clicks, hover sounds, menu navigation
- **Gameplay Audio**: Rapid weapon fire, footsteps, collision sounds
- **Ambient Effects**: Background loops, environmental audio
- **Particle Systems**: Audio for visual effects that spawn frequently

## Troubleshooting

### Common Issues

1. **Sound Not Playing**: Check if the sound name exists in Sounds.lua
2. **Performance Issues**: Monitor pool stats and adjust pool sizes
3. **Memory Usage**: Ensure cleanup is running (check CLEANUP_INTERVAL)

### Debug Information

Use `GetPoolStats()` to monitor system health:
```lua
local stats = SoundManager.GetPoolStats()
print("Pool Statistics:")
for soundName, data in pairs(stats) do
    print(string.format("%s: %d available, %d in use, pool size: %d", 
        soundName, data.available, data.inUse, data.poolSize))
end
```

## License

This sound manager is designed for the Robeats project and can be adapted for other Roblox games.
