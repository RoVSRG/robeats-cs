--[[
	FX Sound Manager with Object Pooling
	
	A high-performance sound effect manager that uses object pooling
	to enable rapid-fire sound effects without performance issues.
	
	Features:
	- Object pooling for Sound instances
	- Automatic sound ID mapping from Sounds.lua
	- Volume and pitch randomization support
	- Configurable pool sizes per sound effect
	- Automatic cleanup and memory management
]]

local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Sounds = require(script.Sounds)

local SoundManager = {}
SoundManager.__index = SoundManager

-- Configuration
local DEFAULT_POOL_SIZE = 5
local MAX_POOL_SIZE = 20
local CLEANUP_INTERVAL = 30 -- seconds
local SOUND_TIMEOUT = 10 -- seconds before a sound can be reused

-- Pool storage
local soundPools = {}
local activeSounds = {}
local lastCleanup = 0

-- Create a new Sound instance for the pool
local function createSound(soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = SoundService
	
	-- Clean up when sound finishes
	sound.Ended:Connect(function()
		if activeSounds[sound] then
			activeSounds[sound] = nil
		end
	end)
	
	return sound
end

-- Get or create a pool for a specific sound
local function getPool(soundName)
	if not soundPools[soundName] then
		soundPools[soundName] = {
			available = {},
			inUse = {},
			soundId = Sounds[soundName],
			poolSize = DEFAULT_POOL_SIZE
		}
		
		-- Pre-populate the pool
		for i = 1, DEFAULT_POOL_SIZE do
			local sound = createSound(Sounds[soundName])
			table.insert(soundPools[soundName].available, sound)
		end
	end
	
	return soundPools[soundName]
end

-- Get an available sound from the pool
local function getAvailableSound(soundName)
	local pool = getPool(soundName)
	
	-- Try to get from available sounds first
	if #pool.available > 0 then
		local sound = table.remove(pool.available)
		pool.inUse[sound] = tick()
		return sound
	end
	
	-- Check if any in-use sounds have finished and can be reused
	for sound, timestamp in pairs(pool.inUse) do
		if not sound.IsPlaying and (tick() - timestamp) > SOUND_TIMEOUT then
			pool.inUse[sound] = tick()
			return sound
		end
	end
	
	-- Create a new sound if pool isn't at max capacity
	local inUseCount = 0
	for _ in pairs(pool.inUse) do
		inUseCount = inUseCount + 1
	end
	
	if (#pool.available + inUseCount) < MAX_POOL_SIZE then
		local sound = createSound(pool.soundId)
		pool.inUse[sound] = tick()
		return sound
	end
	
	-- Return the oldest in-use sound as fallback
	local oldestSound = nil
	local oldestTime = math.huge
	for sound, timestamp in pairs(pool.inUse) do
		if timestamp < oldestTime then
			oldestTime = timestamp
			oldestSound = sound
		end
	end
	
	if oldestSound then
		oldestSound:Stop()
		pool.inUse[oldestSound] = tick()
		return oldestSound
	end
	
	return nil
end

-- Return a sound to the available pool
local function returnSoundToPool(sound, soundName)
	local pool = soundPools[soundName]
	if pool and pool.inUse[sound] then
		pool.inUse[sound] = nil
		sound:Stop()
		sound.Volume = 0.5
		sound.Pitch = 1
		sound.TimePosition = 0
		table.insert(pool.available, sound)
	end
end

-- Cleanup function to manage memory
local function cleanup()
	local currentTime = tick()
	
	for soundName, pool in pairs(soundPools) do
		-- Return finished sounds to available pool
		for sound, timestamp in pairs(pool.inUse) do
			if not sound.IsPlaying and (currentTime - timestamp) > SOUND_TIMEOUT then
				returnSoundToPool(sound, soundName)
			end
		end
		
		-- Trim available pool if it's too large
		while #pool.available > pool.poolSize do
			local sound = table.remove(pool.available)
			sound:Destroy()
		end
	end
	
	lastCleanup = currentTime
end

-- Main sound playing function
function SoundManager.PlaySound(soundName, options)
	options = options or {}
	
	-- Validate sound exists
	if not Sounds[soundName] then
		warn("Sound '" .. soundName .. "' not found in Sounds module")
		return nil
	end
	
	local sound = getAvailableSound(soundName)
	if not sound then
		warn("Could not get available sound for '" .. soundName .. "'")
		return nil
	end
	
	-- Apply options
	if options.Volume then
		sound.Volume = math.clamp(options.Volume, 0, 1)
	end
	
	if options.Pitch then
		sound.Pitch = math.clamp(options.Pitch, 0.1, 3)
	end
	
	if options.VolumeVariation then
		local variation = (math.random() - 0.5) * options.VolumeVariation
		sound.Volume = math.clamp(sound.Volume + variation, 0, 1)
	end
	
	if options.PitchVariation then
		local variation = (math.random() - 0.5) * options.PitchVariation
		sound.Pitch = math.clamp(sound.Pitch + variation, 0.1, 3)
	end
	
	-- Track as active
	activeSounds[sound] = {
		soundName = soundName,
		startTime = tick()
	}
	
	-- Play the sound
	sound:Play()
	
	return sound
end

-- Stop a specific sound instance
function SoundManager.StopSound(sound)
	if sound and sound.IsPlaying then
		sound:Stop()
		
		if activeSounds[sound] then
			local soundName = activeSounds[sound].soundName
			returnSoundToPool(sound, soundName)
			activeSounds[sound] = nil
		end
	end
end

-- Stop all instances of a sound type
function SoundManager.StopAllSounds(soundName)
	if soundName then
		local pool = soundPools[soundName]
		if pool then
			for sound, _ in pairs(pool.inUse) do
				SoundManager.StopSound(sound)
			end
		end
	else
		-- Stop all sounds
		for sound, _ in pairs(activeSounds) do
			SoundManager.StopSound(sound)
		end
	end
end

-- Configure pool size for a specific sound
function SoundManager.SetPoolSize(soundName, size)
	if not Sounds[soundName] then
		warn("Sound '" .. soundName .. "' not found in Sounds module")
		return
	end
	
	size = math.clamp(size, 1, MAX_POOL_SIZE)
	local pool = getPool(soundName)
	pool.poolSize = size
end

-- Get pool statistics for debugging
function SoundManager.GetPoolStats(soundName)
	if soundName then
		local pool = soundPools[soundName]
		if pool then
			local inUseCount = 0
			for _ in pairs(pool.inUse) do
				inUseCount = inUseCount + 1
			end
			
			return {
				available = #pool.available,
				inUse = inUseCount,
				poolSize = pool.poolSize,
				soundId = pool.soundId
			}
		end
		return nil
	else
		local stats = {}
		for name, pool in pairs(soundPools) do
			local inUseCount = 0
			for _ in pairs(pool.inUse) do
				inUseCount = inUseCount + 1
			end
			
			stats[name] = {
				available = #pool.available,
				inUse = inUseCount,
				poolSize = pool.poolSize,
				soundId = pool.soundId
			}
		end
		return stats
	end
end

-- Initialize cleanup routine
RunService.Heartbeat:Connect(function()
	if tick() - lastCleanup > CLEANUP_INTERVAL then
		cleanup()
	end
end)

-- Quick access functions for common sounds
function SoundManager.PlaySelect(options)
	return SoundManager.PlaySound("Select", options)
end

function SoundManager.PlayBack(options)
	return SoundManager.PlaySound("Back", options)
end

return SoundManager
