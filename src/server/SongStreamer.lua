local ServerStorage = game:GetService("ServerStorage")
local Songs = ServerStorage:WaitForChild("Songs")

local PAGE_SIZE = 100

local colorKeys = {}

local Functions = game.ReplicatedStorage.Remotes.Functions

Functions.GetSongsPage.OnServerInvoke = function(player, pageIndex)
	local songs = Songs:GetChildren()
	table.sort(songs, function(a, b)
		return tonumber(a.Name:match("%[(%d+)%]")) < tonumber(b.Name:match("%[(%d+)%]"))
	end)

	local start = pageIndex * PAGE_SIZE + 1
	local stop = math.min(start + PAGE_SIZE - 1, #songs)

	local page = {}
	for i = start, stop do
		local folder = songs[i]
		if folder then
			if not colorKeys[tostring(i)] then
				colorKeys[tostring(i)] = Color3.new(math.random(), math.random(), math.random())
			end
			
			table.insert(page, {
				Name = folder.Name,
				SongName = folder:GetAttribute("SongName"),
				ArtistName = folder:GetAttribute("ArtistName"),
				Difficulty = folder:GetAttribute("Difficulty"),
				Length = folder:GetAttribute("Length"),
				Color = colorKeys[tostring(i)],
				ID = i,
				FolderName = folder.Name
			})
		end
	end

	return page
end

Functions.GetHitObjects.OnServerInvoke = function(player, folderName)
	local songFolder = Songs:FindFirstChild(folderName)
	if not folderName then
		return nil
	end

	local chartValue = songFolder:FindFirstChild("ChartString")
	if not chartValue then
		warn("[Server] GetHitObjects: Missing ChartString in", folderName)
		return nil
	end

	-- Send raw compressed Base64 string (client will decode)
	return chartValue.Value
end

