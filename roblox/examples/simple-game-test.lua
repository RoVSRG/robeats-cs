--!strict
-- Example script showing the simplified RobeatsGameWrapper usage
-- Now the engine reads directly from Options state instead of requiring complex config objects

local RobeatsGameWrapper = require(game.ReplicatedStorage.Modules.RobeatsGameWrapper)
local Options = require(game.ReplicatedStorage.State.Options)

-- Set up game options directly in the global state
Options.ScrollSpeed:set(20)  -- Note speed
Options.Use2DMode:set(true)  -- Enable 2D mode
Options.Upscroll:set(false)  -- Downscroll
Options.NoteColor:set(Color3.fromRGB(0, 255, 255))  -- Cyan notes
Options.MusicVolume:set(0.8)  -- 80% music volume
Options.HitsoundVolume:set(0.6)  -- 60% hitsound volume
Options.ShowHitLighting:set(true)  -- Enable hit effects

-- Set up keybinds
Options.Keybind1:set("A")
Options.Keybind2:set("S") 
Options.Keybind3:set("Y")
Options.Keybind4:set("U")

-- Create game wrapper - much simpler now!
local game = RobeatsGameWrapper.new()

-- Connect to events
game.stateChanged:Connect(function(newState, oldState)
    print(`Game state changed: {oldState} -> {newState}`)
end)

game.scoreChanged:Connect(function(score)
    print(`Score: {score}`)
end)

game.songFinished:Connect(function(stats)
    print("Song finished! Accuracy: " .. string.format("%.2f", stats.accuracy) .. "%")
    print("Grade: " .. stats.grade)
end)

-- Load and start a song - minimal config needed!
local success = game:loadSong({
    songKey = "someSongKey", -- The only required parameter
    startTimeMs = 0,         -- Optional: start from beginning
    gameSlot = 0,           -- Optional: player slot
    recordReplay = false,   -- Optional: record replay data
})

if success then
    print("Song loaded successfully!")
    
    -- Start the game
    if game:start() then
        print("Game started!")
        
        -- The engine now automatically reads from Options for all settings:
        -- - Keybinds come from Options.Keybind1-4
        -- - Note speed from Options.ScrollSpeed  
        -- - Visual settings from Options.Use2DMode, NoteColor, etc.
        -- - Audio settings from Options.MusicVolume, HitsoundVolume, etc.
        -- - Gameplay settings from Options.Mods, TimingPreset, etc.
        
        -- You can still change settings during gameplay and they'll take effect:
        wait(5)
        Options.ScrollSpeed:set(30) -- Increase note speed mid-game
        
        -- Or adjust volume on the fly:
        game:setVolume(0.5, 0.3) -- 50% music, 30% hitsounds (also updates Options)
        
    else
        print("Failed to start game")
    end
else
    print("Failed to load song")
end

-- Clean up when done
game:destroy()
