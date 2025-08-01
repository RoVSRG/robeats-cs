# Input Options Documentation

This document contains the options that were previously present in the Input options page.

## Options List

### Boolean Options

1. **Hitsounds Enabled**
   - Type: Boolean toggle
   - Description: Enables/disables hit sound effects when notes are struck

### Integer Options

2. **Hitsound Volume**
   - Type: Integer with increment/decrement controls
   - Description: Controls the volume level of hit sound effects

3. **Music Volume**
   - Type: Integer with increment/decrement controls
   - Description: Controls the volume level of background music

### Complex Options

4. **Keybinds**
   - Type: Complex keybinding interface
   - Description: Allows customization of input keys for each lane

## Implementation Notes

These options were implemented as pre-built GUI elements in the container. The Keybinds option likely requires a custom implementation due to its complexity.

Example implementation:
```luau
local optionsHandler = OptionsHandler.new(container)
optionsHandler:createBoolOption("Hitsounds Enabled", Options.HitsoundsEnabled)
optionsHandler:createIntOption("Hitsound Volume", Options.HitsoundVolume, 5)
optionsHandler:createIntOption("Music Volume", Options.MusicVolume, 5)
-- Keybinds would need custom implementation
```
