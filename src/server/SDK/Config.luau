--!strict
-- Centralized SDK configuration so API endpoints/keys can be adjusted without
-- editing SDK.luau directly. Values can also be overridden via Attributes on
-- this ModuleScript (BaseUrl/ApiKey) or on ServerScriptService/ReplicatedStorage
-- to support secret injection in Studio.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function readAttribute(container: Instance, name: string, fallback: any?): any?
	local ok, value = pcall(function()
		return container:GetAttribute(name)
	end)
	if ok and value and value ~= "" then
		return value
	end
	return fallback
end

-- Defaults assume the local backend (npm run dev:backend) on the same machine.
local defaultUrl = "http://127.0.0.1:3000"
local defaultKey = "dev_change_me"

local BaseUrl = readAttribute(script, "BaseUrl", nil)
BaseUrl = readAttribute(ServerScriptService, "API_BASE_URL", BaseUrl)
BaseUrl = readAttribute(ReplicatedStorage, "API_BASE_URL", BaseUrl)
BaseUrl = BaseUrl or defaultUrl

local ApiKey = readAttribute(script, "ApiKey", nil)
ApiKey = readAttribute(ServerScriptService, "API_KEY", ApiKey)
ApiKey = readAttribute(ReplicatedStorage, "API_KEY", ApiKey)
ApiKey = ApiKey or defaultKey

return {
	BaseUrl = tostring(BaseUrl),
	ApiKey = tostring(ApiKey),
}
