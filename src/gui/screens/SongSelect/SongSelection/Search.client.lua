local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local SearchUpdated = script.Parent.SearchUpdated

local function search(term: string)
	return SongDatabase:Search(term)
end

local DEBOUNCE_TIME = 0.3

script.Parent.SearchField:GetPropertyChangedSignal("Text"):Connect(function()
	local term = script.Parent.SearchField.Text
	
	wait(DEBOUNCE_TIME)

	if script.Parent.SearchField.Text ~= term then
		return
	end
	
	local results = search(term)
	local empty = term == ""

	local visibleCount = 0
	
	for _, songButton in script.Parent.SongButtonContainer:GetChildren() do
		if songButton.ClassName == "UIListLayout" then
			continue
		end
		
		local songId: NumberValue = songButton.SongID
		
		if table.find(results, songId.Value) or empty then
			songButton.Visible = true
			visibleCount += 1
		else
			songButton.Visible = false
		end
	end

	SearchUpdated:Fire(visibleCount)
end)

script.Parent.ClearSearchButton.Activated:Connect(function()
	script.Parent.SearchField.Text = ""
end)