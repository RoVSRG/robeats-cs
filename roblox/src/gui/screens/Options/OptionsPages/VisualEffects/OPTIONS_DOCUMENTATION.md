# Visual Effects Options Documentation

This document contains the options that were previously present in the Visual Effects options page.

## Options List

### Boolean Options

1. **Hide Long Note Tails**
   - Type: Boolean toggle
   - Description: Hides the trailing visual effects of long notes

2. **Hide Receptor Glow**
   - Type: Boolean toggle
   - Description: Disables the glowing effect on note receptors

3. **Show Hit Lighting**
   - Type: Boolean toggle
   - Description: Shows visual lighting effects when notes are hit

4. **Transparent Long Notes**
   - Type: Boolean toggle
   - Description: Makes long notes semi-transparent

### Integer Options

5. **Receptor Transparency**
   - Type: Integer with increment/decrement controls
   - Description: Controls the transparency level of note receptors

### Multiselect Options

6. **Judgement Visibility**
   - Type: Multiselect checkboxes
   - Options: "Perfect", "Marvelous", "Great", "Good", "Bad", "Miss"
   - Description: Controls which judgement types are visually displayed

## Implementation Notes

These options were implemented as pre-built GUI elements in the container. The Judgement Visibility option uses a multiselect pattern with individual toggles for each judgement type.

Example implementation:
```luau
local optionsHandler = OptionsHandler.new(container)
optionsHandler:createBoolOption("Hide Long Note Tails", Options.HideLongNoteTails)
optionsHandler:createBoolOption("Hide Receptor Glow", Options.HideReceptorGlow)
optionsHandler:createBoolOption("Show Hit Lighting", Options.ShowHitLighting)
optionsHandler:createBoolOption("Transparent Long Notes", Options.TransparentLongNotes)
optionsHandler:createIntOption("Receptor Transparency", Options.ReceptorTransparency, 10)
optionsHandler:createMultiselectOption("Judgement Visibility", Options.JudgementVisibility, {
    "Perfect", "Marvelous", "Great", "Good", "Bad", "Miss"
})
```
