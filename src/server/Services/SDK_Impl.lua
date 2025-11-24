local DataStoreManager = require(script.Parent.DataStoreManager)
local UserService = game:GetService("UserService")

local SDK = {}
SDK.Scores = {}
SDK.Players = {}

-- Helper to get user name safely
local function getUserName(userId)
	local success, name = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync({ tonumber(userId) })[1].DisplayName
	end)
	return success and name or "Unknown"
end

-- POST Score
function SDK.Scores.post(data)
	local user = data.user
	local map = data.map
	local payload = data.payload
	local userId = tostring(user.userId)
	local songHash = map.hash

	-- 1. Update User Profile (The Source of Truth)
	local userStore = DataStoreManager.getUserStore()
	
	-- We use UpdateAsync to safely merge scores
	local finalData = nil
	
	local success, err = pcall(function()
		userStore:UpdateAsync(userId, function(currentData)
			currentData = currentData or { Scores = {}, Stats = { TotalScore = 0, PlayCount = 0 } }
			
			-- Check if this is a new high score
			local oldScoreData = currentData.Scores[songHash]
			local isPb = false
			
			if not oldScoreData or payload.score > oldScoreData.score then
				isPb = true
				-- Save the full payload
				currentData.Scores[songHash] = payload
				currentData.Scores[songHash].timestamp = os.time()
			end
			
			-- Update global stats
			currentData.Stats.TotalScore = (currentData.Stats.TotalScore or 0) + payload.score
			currentData.Stats.PlayCount = (currentData.Stats.PlayCount or 0) + 1
			
			finalData = currentData
			return currentData
		end)
	end)
	
	if not success then
		warn("Failed to save user score:", err)
		return nil
	end
	
	-- 2. Update Song Leaderboard (OrderedDataStore)
	-- Only update if it's a PB or if we don't check (ODS handles max automatically? No, we must check)
	-- Actually, UpdateAsync on ODS allows us to transform.
	local leaderboardStore = DataStoreManager.getSongLeaderboardStore(songHash)
	local packedValue = DataStoreManager.packScore(payload.score, payload.accuracy)
	
	leaderboardStore:UpdateAsync(userId, function(oldValue)
		oldValue = oldValue or 0
		if packedValue > oldValue then
			return packedValue
		end
		return nil -- No update
	end)

	-- 3. Update Global Leaderboard (Total Score? Rating?)
	-- For now, let's just use Total Score as a proxy for "Rating" since we don't have a complex rating calc backend anymore.
	local globalStore = DataStoreManager.getGlobalLeaderboardStore()
	local totalScore = 0
	if finalData and finalData.Stats then
		totalScore = finalData.Stats.TotalScore or 0
		globalStore:SetAsync(userId, totalScore)
	end

	-- Return the format expected by the client and Leaderstats
	return {
		rank = 0, -- Rank is hard to calculate instantly without expensive ODS queries. Display 0 or "?"
		rating = totalScore, -- Used for "Rating" leaderstat
		score = payload,
		is_pb = true
	}
end

-- GET Leaderboard for a Song
function SDK.Scores.getLeaderboard(hash, userId)
	local store = DataStoreManager.getSongLeaderboardStore(hash)
	local isAscending = false
	local pageSize = 50
	local pages = store:GetSortedAsync(isAscending, pageSize)
	local topPage = pages:GetCurrentPage()
	
	local leaderboard = {}
	
	for rank, entry in ipairs(topPage) do
		local score, acc = DataStoreManager.unpackScore(entry.value)
		-- We need names. Getting them one by one is slow.
		-- In a real prod env, we'd cache names. 
		-- For now, just fetch.
		table.insert(leaderboard, {
			id = entry.key,
			name = "Loading...", -- Frontend should handle name fetching or we batch it here
			score = score,
			accuracy = acc,
			rank = rank
		})
	end

	-- Helper to fetch names for the batch
	task.spawn(function() 
		-- This is where we'd actually fetch names if this ran on client, 
		-- but since this returns to a RemoteFunction, we must resolve names now or send IDs.
		-- Let's try to resolve a few.
		local ids = {}
		for _, entry in ipairs(leaderboard) do
			table.insert(ids, tonumber(entry.id))
		end
		
		if #ids > 0 then
			local success, infos = pcall(function()
				return UserService:GetUserInfosByUserIdsAsync(ids)
			end)
			if success then
				for _, info in ipairs(infos) do
					for _, entry in ipairs(leaderboard) do
						if tonumber(entry.id) == info.Id then
							entry.name = info.DisplayName
						end
					end
				end
			end
		end
	end)
	-- Wait briefly for spawn? No, Lua is single threaded but UserService yields.
	-- We need to block here to return names.
	
	local ids = {}
	for _, entry in ipairs(leaderboard) do
		table.insert(ids, tonumber(entry.id))
	end
	
	if #ids > 0 then
		local success, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(ids)
		end)
		if success then
			for _, info in ipairs(infos) do
				for _, entry in ipairs(leaderboard) do
					if tonumber(entry.id) == info.Id then
						entry.name = info.DisplayName
					end
				end
			end
		end
	end

	return leaderboard
end

-- GET User Best Scores
function SDK.Scores.getUserBest(userId)
	local userStore = DataStoreManager.getUserStore()
	local success, data = pcall(function()
		return userStore:GetAsync(userId)
	end)
	
	if success and data and data.Scores then
		-- Convert dictionary to array if needed, or return as is.
		-- The frontend likely expects an array or specific format.
		-- Let's return the raw scores map.
		return data.Scores
	end
	return {}
end

-- GET Global Leaderboard
function SDK.Players.getTop()
	local store = DataStoreManager.getGlobalLeaderboardStore()
	local pages = store:GetSortedAsync(false, 50)
	local topPage = pages:GetCurrentPage()
	
	local result = {}
	local ids = {}
	
	for rank, entry in ipairs(topPage) do
		table.insert(result, {
			id = entry.key,
			name = "Loading...",
			rating = entry.value, -- Using Total Score as rating
			rank = rank
		})
		table.insert(ids, tonumber(entry.key))
	end
	
	if #ids > 0 then
		local success, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(ids)
		end)
		if success then
			for _, info in ipairs(infos) do
				for _, entry in ipairs(result) do
					if tonumber(entry.id) == info.Id then
						entry.name = info.DisplayName
					end
				end
			end
		end
	end
	
	return result
end

-- GET Player Profile
function SDK.Players.get(userId)
	local userStore = DataStoreManager.getUserStore()
	local success, data = pcall(function()
		return userStore:GetAsync(userId)
	end)
	
	if success and data then
		return {
			id = userId,
			name = getUserName(userId),
			stats = data.Stats or {},
			-- Add other profile fields if needed
		}
	end
	return nil
end

function SDK.Players.postJoin(data)
	-- No-op for now, or could initialize data
end

return SDK
