local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Color = require(game.ReplicatedStorage.Shared.Color)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)

local function getDifficulty(songId)
    local difficulty = SongDatabase:GetPropertyByKey(songId, "Difficulty", tonumber)
    return difficulty or 0
end

local function getSongId(button)
    return button.SongID.Value
end

local function getDataKey(button, key)
    return SongDatabase:GetPropertyByKey(getSongId(button), key)
end

local sortOptions = {
    {
        name = "Default",
        func = nil
    },
    {
        name = "Difficulty (Desc)",
        func = function(a, b)
            return getDifficulty(getSongId(a)) > getDifficulty(getSongId(b))
        end
    },
    {
        name = "Difficulty (Asc)",
        func = function(a, b)
            return getDifficulty(getSongId(a)) < getDifficulty(getSongId(b))
        end
    },
    {
        name = "Title (Asc)",
        func = function(a, b)
            return getDataKey(a, "SongName") < getDataKey(b, "SongName")
        end
    },
    {
        name = "Title (Desc)",
        func = function(a, b)
            return getDataKey(a, "SongName") > getDataKey(b, "SongName")
        end
    },
    {
        name = "Artist (Asc)",
        func = function(a, b)
            return getDataKey(a, "ArtistName") < getDataKey(b, "ArtistName")
        end
    },
    {
        name = "Artist (Desc)",
        func = function(a, b)
            return getDataKey(a, "ArtistName") > getDataKey(b, "ArtistName")
        end
    },
}

local function sortSongs(songButtons, mode)
    local sortOption = nil
    for _, option in ipairs(sortOptions) do
        if option.name == mode then
            sortOption = option
            break
        end
    end
    
    if not sortOption then
        error("Invalid sort mode: " .. tostring(mode))
    end
    
    table.sort(songButtons, sortOption.func)

    for i, button in ipairs(songButtons) do
        button.LayoutOrder = i
    end
end

local selectedSort = 0

local function cycle()
    selectedSort = selectedSort % #sortOptions + 1
    local sortMode = sortOptions[selectedSort].name
    script.Parent.SortByButton.Text = "Sort: " .. sortMode

    if sortMode == "Default" then
        for _, button in ipairs(script.Parent.SongButtonContainer:GetChildren()) do
            if button:IsA("TextButton") then
                button.LayoutOrder = button.OriginalLayoutOrder.Value
            end
        end
        
        return
    end

    local songButtons = {}
    for _, button in ipairs(script.Parent.SongButtonContainer:GetChildren()) do
        if button:IsA("TextButton") then
            table.insert(songButtons, button)
        end
    end

    sortSongs(songButtons, sortMode)
end

script.Parent.SortByButton.MouseButton1Click:Connect(cycle)

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
            button.BackgroundColor3 = Color.calculateDifficultyColor(difficulty)
        end
    end
end)

if not SongDatabase.IsLoaded then
    SongDatabase.Loaded.Event:Wait()
end

for _, button in ipairs(script.Parent.SongButtonContainer:GetChildren()) do
    if button:IsA("TextButton") then
        button.OriginalLayoutOrder.Value = button.LayoutOrder
    end
end

cycle()