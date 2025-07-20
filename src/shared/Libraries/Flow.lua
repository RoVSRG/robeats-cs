--[[

Flow: Creates tween sequences

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
local Flow = {}
Flow.__index = Flow

function Flow.new(tweens)
	return setmetatable({
		Step = 0,
		Tweens = tweens,
		isPlaying = false,
		isPaused = false,

		Started = Signal.new(),
		Stopped = Signal.new(),
		Paused = Signal.new(),
		Destroyed = Signal.new()
	}, Flow)
end

function Flow:_Play(step)
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

function Flow:_PlayNext()	
	self.Step = (self.Step + 1) > #self.Tweens and 1 or self.Step + 1
	
	self:_Play(self.Step)
end

function Flow:_PlayCurrent()
	self:_Play(self.Step)
end

function Flow:Play()
	if self.isPlaying then return end
	
	local wasPaused = self.isPaused
	
	self.isPlaying = true
	self.isPaused = false
	
	self.Started:Fire()
	if not wasPaused then
		self:_PlayNext()
	end
end

function Flow:Stop()
	self.isPlaying = false
	self.isPaused = false
	self.Step = 0
	
	self.Stopped:Fire()
end

function Flow:Pause()
	self.isPlaying = false
	self.isPaused = true
	
	self.Paused:Fire()
end

function Flow:Reset()
	self.Tweens[1]()
end

function Flow:Destroy()
	self.Destroyed:Fire()
	
	setmetatable(self, nil)
	table.clear(self)
end

return Flow
