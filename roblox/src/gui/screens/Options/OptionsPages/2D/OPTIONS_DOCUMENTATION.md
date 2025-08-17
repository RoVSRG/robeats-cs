# 2D Options Documentation

This document contains the options that were previously present in the 2D options page.

## Options List

### Boolean Options

1. **2D Enabled** (`Options.Use2DMode`)
   - Type: Boolean toggle
   - Description: Enables 2D mode for the game

2. **Inherit 3D Note Color** (`Options.NoteColorAffects2D`)
   - Type: Boolean toggle  
   - Description: When enabled, 2D notes inherit colors from 3D note settings

3. **Use Upscroll** (`Options.Upscroll`)
   - Type: Boolean toggle
   - Description: Changes note scroll direction to upward instead of downward

## Implementation Notes

These options were previously implemented using the old OptionsHandler singleton pattern. They should be reimplemented using the new class-based OptionsHandler approach:

```luau
local optionsHandler = OptionsHandler.new(container)
optionsHandler:createBoolOption("2D Enabled", Options.Use2DMode)
optionsHandler:createBoolOption("Inherit 3D Note Color", Options.NoteColorAffects2D)
optionsHandler:createBoolOption("Use Upscroll", Options.Upscroll)
```
