local DataStoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")

-- Constants
local USER_PROFILE_DS_NAME = "UserProfile_v1"
local SONG_LEADERBOARD_ODS_NAME = "SongLeaderboard_v1"
local GLOBAL_LEADERBOARD_ODS_NAME = "GlobalLeaderboard_v1"

local DataStoreManager = {}

-- Get the main User Profile Store
function DataStoreManager.getUserStore()
	return DataStoreService:GetDataStore(USER_PROFILE_DS_NAME)
end

-- Get the OrderedDataStore for a specific song hash
function DataStoreManager.getSongLeaderboardStore(hash)
	-- Scope is the hash to keep things organized, or we can just use the name.
	-- Using Scope is safer for limits if many songs exist.
	return DataStoreService:GetOrderedDataStore(SONG_LEADERBOARD_ODS_NAME, hash)
end

-- Get the Global Rating Leaderboard
function DataStoreManager.getGlobalLeaderboardStore()
	return DataStoreService:GetOrderedDataStore(GLOBAL_LEADERBOARD_ODS_NAME)
end

-- Helper: Bit-pack Score and Accuracy for ODS
-- Max Score is usually ~1-2 million.
-- Max Accuracy is 100.00 (x100 = 10000).
-- We can store Score * 10000 + (Acc * 100).
-- Example: Score 1,000,000, Acc 100.00 -> 1,000,000 * 10000 + 10000 = 10,000,010,000 (Fits in 64-bit int)
function DataStoreManager.packScore(score, accuracy)
	local safeScore = math.floor(score)
	local safeAcc = math.floor(accuracy * 100) -- 99.55 -> 9955
	return (safeScore * 10000) + safeAcc
end

function DataStoreManager.unpackScore(packed)
	local accPart = packed % 10000
	local scorePart = math.floor(packed / 10000)
	return scorePart, accPart / 100
end

return DataStoreManager
