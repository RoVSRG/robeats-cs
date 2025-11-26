local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local App = require(script.Parent.App)
local SongDatabase = require(ReplicatedStorage.SongDatabase)
local EnvironmentSetup = require(ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local GetSettings = ReplicatedStorage.Remotes.Functions.GetSettings
local SettingsSerializer = require(ReplicatedStorage.Serialization.SettingsSer)

local function handlePlayerSettings()
	local playerSettings = GetSettings:InvokeServer()
	SettingsSerializer.apply_serialized_opts(playerSettings)
end

local function setupLighting()
	local lighting = game:GetService("Lighting")
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.1
	bloom.Size = 24
	bloom.Threshold = 2
	bloom.Parent = lighting
end

local function initialize()
	-- 1. Cleanup
	game:GetService("StarterGui"):ClearAllChildren()
	
	-- 2. Setup Env
	setupLighting()
	EnvironmentSetup:initial_setup()
	
	-- 3. Start Loading (Async)
	for _, skin in require(ReplicatedStorage.Skins):key_itr() do
		task.spawn(function() ContentProvider:PreloadAsync({ skin }) end)
	end
	
	SongDatabase:LoadAllSongs() 
	
    -- 4. Load Settings
	task.spawn(handlePlayerSettings)

	-- 5. Mount App
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = ReactRoblox.createRoot(playerGui)
	root:render(React.createElement(App))
end

initialize()