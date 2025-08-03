local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local GLOBAL_HEADERS = {}
local LOCALHOST = "http://localhost:3000"

local function withUrl(path)
	local useDevServer = game:GetService("ServerScriptService"):GetAttribute("USE_DEV_SERVER")

	if RunService:IsStudio() and not useDevServer then
		warn("----------------------------------------------------------------------------------")
		warn("Using production server for HTTP requests! This is not recommended in Studio mode.")
		warn("----------------------------------------------------------------------------------")
	end

	if RunService:IsStudio() and useDevServer then
		return LOCALHOST .. path
	end

	return "https://robeatscs.com" .. path
end

local SECRETS = DataStoreService:GetDataStore("SECRETS")
local API_KEY = SECRETS:GetAsync("API_KEY")

local function withApiKey(params)
	params = params or {}
	params.api_key = API_KEY

	return params
end

local function encodeParams(params)
	local encoded = "?"
	local first = true

	for key, value in pairs(params) do
		encoded ..= (first and "" or "&") .. HttpService:UrlEncode(key) .. "=" .. HttpService:UrlEncode(value)
		first = false
	end

	return encoded
end

local function request(config, contentType)
	contentType = contentType or "application/json"
	config.params = config.params or {}

	local url = config.url or ""

	if url:sub(1, 1) == "/" then
		url = withUrl(url)
	end

	local params = withApiKey(config.params)

	url ..= encodeParams(params)
	config.params = nil

	local requestOptions = {
		Url = url,
		Method = config.method or "GET",
		Headers = {},
	}

	-- Merge headers
	for k, v in pairs(GLOBAL_HEADERS) do
		requestOptions.Headers[k] = v
	end

	if config.headers then
		for k, v in pairs(config.headers) do
			requestOptions.Headers[k] = v
		end
	end

	requestOptions.Headers["Content-Type"] = contentType

	if config.json then
		requestOptions.Body = HttpService:JSONEncode(config.json)
	elseif config.body then
		requestOptions.Body = config.body
	end

	if config.compress then
		requestOptions.Compress = config.compress
	end

	local response = HttpService:RequestAsync(requestOptions)

	if RunService:IsStudio() and response.StatusCode ~= 200 then
		warn(string.format("HTTP request failed: %s", response.Body))
	end

	return {
		json = function()
			return HttpService:JSONDecode(response.Body)
		end,
		body = response.Body,
		headers = response.Headers,
		status = {
			code = response.StatusCode,
			message = response.StatusMessage,
		},
		success = response.Success,
	}
end

local function get(url, config)
	config = config or {}
	config.url = url
	config.method = "GET"
	return request(config)
end

local function post(url, config)
	config = config or {}
	config.url = url
	config.method = "POST"
	return request(config)
end

local function put(url, config)
	config = config or {}
	config.url = url
	config.method = "PUT"
	return request(config)
end

local function del(url, config)
	config = config or {}
	config.url = url
	config.method = "DELETE"
	return request(config)
end

local lastApiKeyUpdate = tick()

RunService.Heartbeat:Connect(function(dt)
	if tick() - lastApiKeyUpdate > 30 then
		local newApiKey = SECRETS:GetAsync("API_KEY")

		if newApiKey then
			API_KEY = newApiKey
		end

		lastApiKeyUpdate = tick()
	end
end)

return {
	request = request,
	get = get,
	post = post,
	put = put,
	del = del,
	GLOBAL_HEADERS = GLOBAL_HEADERS,
}
