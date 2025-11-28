--!strict
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigModule = script:FindFirstChild("SDKConfig")
		or ServerScriptService:FindFirstChild("SDKConfig")
		or ReplicatedStorage:FindFirstChild("SDKConfig")
local ExternalConfig = nil
if ConfigModule then
	local ok, cfg = pcall(function()
		return require(ConfigModule :: any)
	end)
	if ok and type(cfg) == "table" then
		ExternalConfig = cfg
	end
end

export type Grade = "F" | "D" | "C" | "B" | "A" | "S" | "SS"

export type ScoreData = {
	rating: number,
	score: number,
	accuracy: number,
	grade: Grade,
	max_combo: number,
	marvelous: number,
	perfect: number,
	great: number,
	good: number,
	bad: number,
	miss: number,
	rate: number,
	mean: number,
}

export type ScoreSubmission = {
	user: {
		userId: number,
		name: string,
	},
	map: {
		hash: string,
	},
	payload: ScoreData,
}

export type PlayerProfile = {
	userId: number,
	name: string,
	rating: number,
	accuracy: number,
	playCount: number,
	rank: number,
}

export type LeaderboardEntry = ScoreData & {
	user_id: string?,
	player_name: string?,
	hash: string,
	created_at: string,
}

export type LeaderboardResponse = {
	best: LeaderboardEntry?,
	leaderboard: { LeaderboardEntry },
}

export type UserBestScore = ScoreData & {
	hash: string,
	created_at: string,
}

type APIConfig = {
	BaseUrl: string,
	ApiKey: string,
}

local Config: APIConfig = {
	BaseUrl = ExternalConfig and ExternalConfig.BaseUrl or "http://127.0.0.1:3000",
	ApiKey = ExternalConfig and ExternalConfig.ApiKey or "dev_change_me",
}

local warnedHttpDisabled = false

local function request(method: "GET" | "POST", path: string, body: any?, query: { [string]: string }?)
	if not RunService:IsServer() then
		warn("[SDK] Cannot make HTTP requests from the client.")
		return nil
	end

	if not HttpService.HttpEnabled then
		if not warnedHttpDisabled then
			warn("[SDK] HttpService.HttpEnabled is false; enable HTTP requests in Game Settings > Security.")
			warnedHttpDisabled = true
		end
		return nil
	end

	local url = Config.BaseUrl .. path
	
	if query then
		local queryString = ""
		for k, v in pairs(query) do
			queryString = queryString .. (queryString == "" and "?" or "&") .. k .. "=" .. HttpService:UrlEncode(tostring(v))
		end
		url = url .. queryString
	end

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = method,
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = "Bearer " .. Config.ApiKey,
			},
			Body = body and HttpService:JSONEncode(body) or nil,
		})
	end)

	if not success then
		warn("[SDK] Request Failed: " .. tostring(response))
		return nil
	end

	if not response.Success then
		warn("[SDK] API Error " .. response.StatusCode .. ": " .. response.Body)
		return nil
	end

	local decodeSuccess, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if not decodeSuccess then
		warn("[SDK] JSON Decode Error: " .. tostring(data))
		return nil
	end

	return data
end

local SDK = {}

function SDK.configure(url: string, key: string)
	Config.BaseUrl = url:gsub("/+$", "") -- Remove trailing slash
	Config.ApiKey = key
end

function SDK.ping(): boolean
	local res = request("GET", "/")
	return res ~= nil and res.status == "ok1"
end

local Players = {}

function Players.join(userId: number, name: string): boolean
	local res = request("POST", "/players/join", {
		userId = userId,
		name = name,
	})
	return res ~= nil
end

function Players.getTop(): { PlayerProfile }?
	return request("GET", "/players/top")
end

function Players.getProfile(userId: number): PlayerProfile?
	return request("GET", "/players", nil, { userId = tostring(userId) })
end

local Scores = {}

function Scores.getLeaderboard(hash: string, userId: number): LeaderboardResponse?
	return request("GET", "/scores/leaderboard", nil, {
		hash = hash,
		userId = tostring(userId),
	})
end

function Scores.getUserBest(userId: number): { UserBestScore }?
	return request("GET", "/scores/user/best", nil, { userId = tostring(userId) })
end

function Scores.submit(submission: ScoreSubmission): PlayerProfile?
	return request("POST", "/scores", submission)
end

function Scores.getHistory(playerId: number, songKey: string): { scores: { ScoreData & { player_id: string?, hash: string, created_at: string } } }?
	return request("GET", "/scores/" .. tostring(playerId) .. "/" .. songKey)
end

SDK.Players = Players
SDK.Scores = Scores

return SDK
