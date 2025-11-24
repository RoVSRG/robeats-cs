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
			currentData = currentData or { Scores = {}, Stats = { TotalScore = 0, PlayCount = 0, AverageAccuracy = 0 } }
			
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
			-- Recalculate average accuracy: (OldAvg * OldCount + NewAcc) / NewCount
			local oldAvg = currentData.Stats.AverageAccuracy or 0
			local oldCount = currentData.Stats.PlayCount or 0
			local newCount = oldCount + 1
			
			currentData.Stats.TotalScore = (currentData.Stats.TotalScore or 0) + payload.score
			currentData.Stats.PlayCount = newCount
			currentData.Stats.AverageAccuracy = ((oldAvg * oldCount) + payload.accuracy) / newCount
			
			finalData = currentData
			return currentData
		end)
	end)
	
	if not success then
		warn("Failed to save user score:", err)
		return nil
	end
	
	-- 2. Update Song Leaderboard (OrderedDataStore)
	local leaderboardStore = DataStoreManager.getSongLeaderboardStore(songHash)
	local packedValue = DataStoreManager.packScore(payload.score, payload.accuracy)
	
	leaderboardStore:UpdateAsync(userId, function(oldValue)
		oldValue = oldValue or 0
		if packedValue > oldValue then
			return packedValue
		end
		return nil -- No update
	end)

	-- 3. Update Global Leaderboard
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
		table.insert(leaderboard, {
			user_id = tonumber(entry.key), -- Client expects user_id, not id
			player_name = "Loading...",    -- Client expects player_name, not name
			score = score,
			accuracy = acc,
			rank = rank,
			rate = 100, -- Default rate if not stored in ODS (we only stored Score/Acc)
			-- Note: To get full details like marvelouse/perfect counts for the UI, we'd need to fetch the UserProfile.
			-- For now, we leave them 0 or try to fetch if critical. 
			-- The UI likely needs them for "Color.getSpreadRichText".
			marvelous = 0, perfect = 0, great = 0, good = 0, bad = 0, miss = 0
		})
	end

	-- Fetch names
	local ids = {}
	for _, entry in ipairs(leaderboard) do
		table.insert(ids, entry.user_id)
	end
	
	if #ids > 0 then
		local success, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(ids)
		end)
		if success then
			for _, info in ipairs(infos) do
				for _, entry in ipairs(leaderboard) do
					if entry.user_id == info.Id then
						entry.player_name = info.DisplayName
					end
				end
			end
		end
	end
	
	-- Fetch "Best" for the requesting user
	local best = nil
	if userId then
		local userStore = DataStoreManager.getUserStore()
		local success, data = pcall(function()
			return userStore:GetAsync(userId)
		end)
		if success and data and data.Scores and data.Scores[hash] then
			best = data.Scores[hash]
		end
	end

	return {
		leaderboard = leaderboard,
		best = best
	}
end

-- GET User Best Scores
function SDK.Scores.getUserBest(userId)
	local userStore = DataStoreManager.getUserStore()
	local success, data = pcall(function()
		return userStore:GetAsync(userId)
	end)
	
	if success and data and data.Scores then
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
			rating = entry.value,
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
	
	local stats = (data and data.Stats) or { TotalScore = 0, PlayCount = 0, AverageAccuracy = 0 }
	
	return {
		id = userId,
		name = getUserName(userId),
		rank = 0, -- Placeholder
		rating = stats.TotalScore or 0,
		accuracy = stats.AverageAccuracy or 0,
		playCount = stats.PlayCount or 0,
		-- avatar = "" -- Client likely fetches this themselves via Pfp module
	}
end

function SDK.Players.postJoin(data)
	-- No-op for now, or could initialize data
end

return SDK
