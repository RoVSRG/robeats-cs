--[[

SoundPlayer: Sound effects player

>> CREDITS <<
Creator: SectorJack

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// Modules
local Modules = ReplicatedStorage.Modules

local Helper = require(Modules.Helper)
local HitsoundIndexes = Helper:GetHitsoundIndexes()

--// Variables
local SFX = SoundService:WaitForChild("SFX")
local Hitsounds = SoundService:WaitForChild("Hitsounds")

local Rng = Random.new(tick())

--// System
local Player = {
	Hitsound = Hitsounds:FindFirstChild(HitsoundIndexes[1])
}

function Player:Play(soundname, randompitch)
	task.spawn(function()
		local sound = SFX:FindFirstChild(soundname)
		if not sound then
			print(`[SoundPlayer] Failed to play sound {soundname}; Reason: Not found`)
			return
		end

		if randompitch then
			sound.PlaybackSpeed = Rng:NextNumber(1 - randompitch, 1 + randompitch)
		else
			sound.PlaybackSpeed = 1
		end
		
		SoundService:PlayLocalSound(sound)
	end)
end

function Player:SetHitsound(index)
	local sound = Hitsounds:FindFirstChild(HitsoundIndexes[index])
	if sound then
		Player.Hitsound = sound
	else
		print(`[SoundPlayer] Failed to set hitsound; Reason: Not found`)
	end
end

function Player:AdjustHitsound(volume)
	local sound = Player.Hitsound
	if sound then
		sound.Volume = volume
	else
		print(`[SoundPlayer] Failed to change hitsound volume; Reason: Not found`)
	end
end

function Player:PlayHitsound()
	task.spawn(function()
		local sound = Player.Hitsound
		if sound then
			SoundService:PlayLocalSound(sound)
		else
			print(`[SoundPlayer] Failed to play hitsound; Reason: Not found`)
		end
	end)
end

return Player
