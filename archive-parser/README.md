# Archive Parser

TypeScript tool to parse `archive_screens` into readable formats for React implementation.

## Setup

```bash
cd archive-parser
npm install
```

## Usage

```bash
npm run parse <screen-name>
```

**Example:**
```bash
npm run parse SongSelect
npm run parse Options
npm run parse MainMenu
```

## Output

Creates `archive-parsed/<screen-name>/` with:

1. **`hierarchy.txt`** - ASCII tree showing component structure with sizes
2. **`layout-specs.json`** - JSON array of all UI elements with layout data
3. **`layout-specs.lua`** - Lua table format for direct import
4. **`README.md`** - Summary with statistics and key components

## Output Format

### hierarchy.txt
```
SongSelect (831px × 433px)
├─ SongSelection (35.4% × 100%)
│  ├─ SearchBar (100% × 35px)
│  └─ SongButtonContainer (100% × 90%)
├─ Leaderboard (28.7% × 66.2%)
└─ MultiplayerInfo (33.6% × 100%)
```

### layout-specs.json
```json
[
  {
    "name": "SongSelection",
    "className": "Frame",
    "width": "35.4%",
    "height": "100%",
    "x": "0%",
    "y": "0%",
    "color": "Color3.fromRGB(29, 28, 29)"
  }
]
```

### layout-specs.lua
```lua
return {
  ["SongSelection"] = {
    className = "Frame",
    width = "35.4%",
    height = "100%",
    x = "0%",
    y = "0%",
    color = Color3.fromRGB(29, 28, 29),
  },
}
```

## What It Extracts

- **Layout**: Size, Position (formatted as percentages/pixels)
- **Colors**: BackgroundColor3, TextColor3
- **Text**: Font size, text content
- **Visibility**: Whether elements are visible
- **Hierarchy**: Parent-child relationships

## What It Filters Out

- Script files (.lua, .client.lua)
- Default/irrelevant properties
- Folders without UI significance
- Internal Roblox metadata
