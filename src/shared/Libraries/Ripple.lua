--[[

Ripple: Creates tween sequences (no-loop ver.)

>> CREDITS <<
Creator: kisperal
Modified: SectorJack

]]

--// Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Libraries
local Modules = ReplicatedStorage.Modules

local Signal = require(Modules.Libraries.LemonSignal)
local Sweeper = require(Modules.Libraries.Sweeper)

--// Variables
local heartbeatSignal = Signal.wrap(RunService.Heartbeat)

--// System
local Ripple = {}
Ripple.__index = Ripple

function Ripple.new(tweens)
	return setmetatable({
		Step = 0,
		Tweens = tweens,
		isPlaying = false,
		isPaused = false,

		Started = Signal.new(),
		Stopped = Signal.new(),
		Paused = Signal.new(),
		Destroyed = Signal.new()
	}, Ripple)
end

function Ripple:_Play(step)
	local sweeper = Sweeper.new()
	
	local tween = self.Tweens[step]
	if typeof(tween) == "number" then
		local timeElapsed = 0
		
		local heartbeatConnection = heartbeatSignal:Connect(function(deltaTime)
			if not self.isPaused then
				timeElapsed += deltaTime
			end

			if timeElapsed >= tween then
				sweeper:Sweep()
				self:_PlayNext()
			end
		end)

		local stoppedConnection = self.Stopped:Connect(function()
			sweeper:Sweep()
			heartbeatConnection:Disconnect()
		end)
		
		sweeper:Add(heartbeatConnection)
		sweeper:Add(stoppedConnection)

	elseif typeof(tween) == "function" then
		tween()
		self:_PlayNext()
		
	else
		local tweenSignal = Signal.wrap(tween.Completed)
		local tweenConnection = tweenSignal:Connect(function()
			sweeper:Sweep()
			self:_PlayNext()
		end)
		
		local startedConnection = self.Started:Connect(function()
			tween:Play()
		end)
		
		local stoppedConnection = self.Stopped:Connect(function()
			sweeper:Sweep()
			tween:Cancel()
		end)
		
		local pausedConnection = self.Paused:Connect(function()
			tween:Pause()
		end)
		
		sweeper:Add(tweenConnection)
		sweeper:Add(startedConnection)
		sweeper:Add(stoppedConnection)
		sweeper:Add(pausedConnection)

		tween:Play()
	end
end

function Ripple:_PlayNext()
	if (self.Step + 1) > #self.Tweens then
		self:Stop()
		return
	else
		self.Step = self.Step + 1
	end
	
	self:_Play(self.Step)
end

function Ripple:_PlayCurrent()
	self:_Play(self.Step)
end

function Ripple:Play()
	if self.isPlaying then --Replays the sequence if already playing
		self:Stop()
	end
	
	local wasPaused = self.isPaused
	
	self.isPlaying = true
	self.isPaused = false
	
	self.Started:Fire()
	if not wasPaused then
		self:_PlayNext()
	end
end

function Ripple:Stop()
	self.isPlaying = false
	self.isPaused = false
	self.Step = 0
	
	self.Stopped:Fire()
end

function Ripple:Pause()
	self.isPlaying = false
	self.isPaused = true
	
	self.Paused:Fire()
end

function Ripple:Reset()
	self.Tweens[1]()
end

function Ripple:Destroy()
	self.Destroyed:Fire()
	
	setmetatable(self, nil)
	table.clear(self)
end

return Ripple
