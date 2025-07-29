local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local GLOBAL_HEADERS = {}
local LOCALHOST = "http://localhost:3000"

local function withUrl(path)
	if RunService:IsStudio() then
		return LOCALHOST .. path
	end

	return "https://your-api-domain.com" .. path
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

	local url = config.url or ""

	if url:sub(1, 1) == "/" then
		url = withUrl(url)
	end

	if config.params then
		url ..= encodeParams(config.params)
		config.params = nil
	end

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

return {
	request = request,
	get = get,
	post = post,
	put = put,
	del = del,
	GLOBAL_HEADERS = GLOBAL_HEADERS,
}
