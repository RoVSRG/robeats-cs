local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

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