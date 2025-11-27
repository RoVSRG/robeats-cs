local ServerStorage = game:GetService("ServerStorage")
local SongsFolder = ServerStorage:WaitForChild("Songs")

local songs = SongsFolder:GetChildren()
table.sort(songs, function(a, b)
	local aId = a.Name
	local bId = b.Name
	return aId < bId
end)

local PAGE_SIZE = 100

local colorKeys = {}

local Functions = game.ReplicatedStorage.Remotes.Functions

Functions.GetSongsPage.OnServerInvoke = function(player, pageIndex: number)
	local start = pageIndex * PAGE_SIZE + 1
	local stop = math.min(start + PAGE_SIZE - 1, #songs)

	local page = {}
	for i = start, stop do
		local folder = songs[i]
		if folder then
			if not colorKeys[tostring(i)] then
				colorKeys[tostring(i)] = Color3.new(math.random(), math.random(), math.random())
			end

			local includeKeys = {
				"SongName",
				"ArtistName",
				"CharterName",
				"Description",
				"Difficulty",
				"Length",
				"ObjectCount",
				"AudioID",
				"CoverImageAssetId",
				"Volume",
				"HitSFXGroup",
				"TimeOffset",
				"MD5Hash",
				"NPSGraph",
				"MaxNPS",
				"AverageNPS",
				"TotalSingleNotes",
				"TotalHoldNotes",
			}

			local song = {
				Name = folder.Name,
				Color = colorKeys[tostring(i)],
				ID = i,
				FolderName = folder.Name,
			}

			for _, key in ipairs(includeKeys) do
				song[key] = folder:GetAttribute(key)
			end

			table.insert(page, song)
		end
	end

	return page
end

Functions.GetHitObjects.OnServerInvoke = function(player, folderName)
	local songFolder = SongsFolder:FindFirstChild(folderName)
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
