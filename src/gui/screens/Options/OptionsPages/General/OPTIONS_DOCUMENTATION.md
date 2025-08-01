# General Options Documentation

This document contains the options that were previously present in the General options page.

## Options List

### Integer Options

1. **Audio Offset** 
   - Type: Integer with increment/decrement controls
   - Description: Adjusts audio timing offset for synchronization

2. **Field of View**
   - Type: Integer with increment/decrement controls
   - Description: Controls the camera field of view angle

3. **Hit Offset**
   - Type: Integer with increment/decrement controls
   - Description: Adjusts hit timing offset for input latency compensation

4. **Lane Cover**
   - Type: Integer with increment/decrement controls
   - Description: Controls the height/position of lane cover overlay

5. **Note Speed**
   - Type: Integer with increment/decrement controls
   - Description: Controls the speed at which notes approach receptors

### Boolean Options

6. **Lane Cover Enabled**
   - Type: Boolean toggle
   - Description: Enables/disables the lane cover overlay

### Radio Options

7. **Timing Preset**
   - Type: Radio selection
   - Options: "Standard", "Strict"
   - Description: Selects between different timing window presets

## Implementation Notes

These options were implemented as pre-built GUI elements in the container. They should be reimplemented using the new OptionsHandler class system with appropriate state bindings.

Example implementation:
```luau
local optionsHandler = OptionsHandler.new(container)
optionsHandler:createIntOption("Audio Offset", Options.AudioOffset, 1)
optionsHandler:createIntOption("Field of View", Options.FieldOfView, 5)
optionsHandler:createIntOption("Hit Offset", Options.HitOffset, 1)
optionsHandler:createIntOption("Lane Cover", Options.LaneCover, 10)
optionsHandler:createBoolOption("Lane Cover Enabled", Options.LaneCoverEnabled)
optionsHandler:createIntOption("Note Speed", Options.NoteSpeed, 50)
optionsHandler:createRadioOption("Timing Preset", Options.TimingPreset, {"Standard", "Strict"})
```
