local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Color = require(game.ReplicatedStorage.Shared.Color)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)

local function getDifficulty(songId)
    local songData = SongDatabase:GetSongByKey(songId)
    return songData and songData.Difficulty or 0
end

local sortMap = {
    ["Difficulty (Asc)"] = function(a, b)
        return getDifficulty(a.SongID.Value) < getDifficulty(b.SongID.Value)
    end,
    ["Difficulty (Desc)"] = function(a, b)
        return getDifficulty(a.SongID.Value) > getDifficulty(b.SongID.Value)
    end,
}

local function sortSongs(songButtons, mode)
    local sortFunction = sortMap[mode]
    if not sortFunction then
        error("Invalid sort mode: " .. tostring(mode))
    end
    table.sort(songButtons, sortFunction)

    for i, button in ipairs(songButtons) do
        button.LayoutOrder = i
    end
end

local keys = {}

for name, _ in pairs(sortMap) do
    table.insert(keys, name)
end

local selectedSort = 1

script.Parent.SortByButton.MouseButton1Click:Connect(function()
    selectedSort = selectedSort % #keys + 1
    local sortMode = keys[selectedSort]
    script.Parent.SortByButton.Text = "Sort: " .. sortMode

    local songButtons = {}
    for _, button in ipairs(script.Parent.SongButtonContainer:GetChildren()) do
        if button:IsA("TextButton") then
            table.insert(songButtons, button)
        end
    end

    sortSongs(songButtons, sortMode)
end)

local selectedColor = 1

local colorKeys = {"Default", "Difficulty"}

script.Parent.ColorButton.MouseButton1Click:Connect(function()
    selectedColor = selectedColor % #colorKeys + 1
    local colorMode = colorKeys[selectedColor]

    script.Parent.ColorButton.Text = "Color: " .. colorMode

    local songButtons = script.Parent.SongButtonContainer:GetChildren()
    
    for _, button in ipairs(songButtons) do
        if not button:IsA("TextButton") then
            continue
        end

        local song = button.SongID.Value

        if colorMode == "Default" then
            local getColor = SongDatabase:GetPropertyByKey(song, "Color")
            button.BackgroundColor3 = getColor
        elseif colorMode == "Difficulty" then
            local difficulty = getDifficulty(song)
            button.BackgroundColor3 = Color.calculateDifficultyColor(difficulty / Rating.getRainbowRating())
        end
    end
end)