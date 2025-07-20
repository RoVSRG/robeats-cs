--// Services
local UIS = game:GetService("UserInputService")
local UserService = game:GetService("UserService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules
local Modules = ReplicatedStorage.Modules

local Helper = require(Modules.Helper)
local Warp = require(Modules.Libraries.Warp)
local Flow = require(Modules.Libraries.Flow)
local Signal = require(Modules.Libraries.LemonSignal)
local Scenery = require(Modules.Libraries.Scenery)
local SoundPlayer = require(Modules.Libraries.SoundPlayer)

local Interfaces

--// Variables
local Remotes = {
	PurchaseDonation = Warp.Client("PurchaseDonation"),
	GetDonatedAmount = Warp.Client("GetDonatedAmount"),
	UpdateDonatedAmount = Warp.Client("UpdateDonatedAmount")
}

local db = true

local UI = script.MenuUI
local Templates = script.Templates

local DONATORS_MAX_SHOWN = 100
local DONATORS_REFRESH_COOLDOWN = 60
local DONATION_TYPES = {
	[1] = 10,
	[2] = 50,
	[3] = 200,
	[4] = 1000,
	[5] = 5000
}

local Donators = ReplicatedStorage:WaitForChild("Donators")
local DonateEntries = {}
local LastDonatorsRefresh = 0
local DonatedAmount = nil
local SelectedDonationType = 1

local Tweens = {
	ModesGoIn = TweenService:Create(
		UI.Modes,
		TweenInfo.new(.3, Enum.EasingStyle.Quint),
		{Position = UDim2.fromScale(0.1, 0.5)}
	),
	CharacterGoIn = TweenService:Create(
		UI.Character,
		TweenInfo.new(.3, Enum.EasingStyle.Quint),
		{Position = UDim2.fromScale(1.02, 1.05)}
	),
	CharacterSpin = TweenService:Create(
		UI.Character.Sprite,
		TweenInfo.new(2, Enum.EasingStyle.Elastic),
		{Rotation = 360}
	),
	DetailsSingleFadeIn = TweenService:Create(
		UI.Modes.Details.Single,
		TweenInfo.new(.1),
		{TextTransparency = 0}
	),
	DetailsSingleFadeOut = TweenService:Create(
		UI.Modes.Details.Single,
		TweenInfo.new(.1),
		{TextTransparency = 1}
	),
	DetailsMultiFadeIn = TweenService:Create(
		UI.Modes.Details.Multi,
		TweenInfo.new(.1),
		{TextTransparency = 0}
	),
	DetailsMultiFadeOut = TweenService:Create(
		UI.Modes.Details.Multi,
		TweenInfo.new(.1),
		{TextTransparency = 1}
	),
	DetailsLabFadeIn = TweenService:Create(
		UI.Modes.Details.Lab,
		TweenInfo.new(.1),
		{TextTransparency = 0}
	),
	DetailsLabFadeOut = TweenService:Create(
		UI.Modes.Details.Lab,
		TweenInfo.new(.1),
		{TextTransparency = 1}
	),
	DetailsRankingFadeIn = TweenService:Create(
		UI.Modes.Details.Ranking,
		TweenInfo.new(.1),
		{TextTransparency = 0}
	),
	DetailsRankingFadeOut = TweenService:Create(
		UI.Modes.Details.Ranking,
		TweenInfo.new(.1),
		{TextTransparency = 1}
	),
	DetailsSettingsFadeIn = TweenService:Create(
		UI.Modes.Details.Settings,
		TweenInfo.new(.1),
		{TextTransparency = 0}
	),
	DetailsSettingsFadeOut = TweenService:Create(
		UI.Modes.Details.Settings,
		TweenInfo.new(.1),
		{TextTransparency = 1}
	),
	DonationOpen = TweenService:Create(
		UI.Donation,
		TweenInfo.new(.1),
		{Position = UDim2.new(0.5, 0, 0.4, 1)}
	),
	DonationClose = TweenService:Create(
		UI.Donation,
		TweenInfo.new(.1),
		{Position = UDim2.new(0.5, 0, 1, 1)}
	)
}

local Flows = {
	ShearT = Flow.new({
		function()
			UI.Bars.ShearT.Position = UDim2.fromScale(0, 0.05)
		end,
		TweenService:Create(
			UI.Bars.ShearT,
			TweenInfo.new(30, Enum.EasingStyle.Linear),
			{Position = UDim2.fromScale(-1, 0.05)}
		)
	}),
	ShearB = Flow.new({
		function()
			UI.Bars.ShearB.Position = UDim2.fromScale(0, 0.95)
		end,
		TweenService:Create(
			UI.Bars.ShearB,
			TweenInfo.new(30, Enum.EasingStyle.Linear),
			{Position = UDim2.fromScale(-1, 0.95)}
		)
	}),
	Character = Flow.new({
		function()
			UI.Character.Sprite.Position = UDim2.fromScale(1, 1)
		end,
		TweenService:Create(
			UI.Character.Sprite,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{Position = UDim2.fromScale(1, 0.975)}
		),
		TweenService:Create(
			UI.Character.Sprite,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{Position = UDim2.fromScale(1, 1)}
		),
	}),
	GuideLabel = Flow.new({
		function()
			UI.Modes.Guide.Label.TextTransparency = 1
			UI.Modes.Guide.Label.Position = UDim2.fromScale(0.95, 0.5)
		end,
		TweenService:Create(
			UI.Modes.Guide.Label,
			TweenInfo.new(.2),
			{TextTransparency = 0, Position = UDim2.fromScale(0.975, 0.5)}
		),
		3,
		TweenService:Create(
			UI.Modes.Guide.Label,
			TweenInfo.new(.2),
			{TextTransparency = 1, Position = UDim2.fromScale(1, 0.5)}
		)
	})
}

local Modes = {
	Single = {
		Target = "SingleUI",
		Button = UI.Modes.List.Single,
		Details = {
			Label = UI.Modes.Details.Single,
			In = Tweens.DetailsSingleFadeIn,
			Out = Tweens.DetailsSingleFadeOut
		},
		Enabled = true
	},
	Multi = {
		Target = "MultiUI",
		Button = UI.Modes.List.Multi,
		Details = {
			Label = UI.Modes.Details.Multi,
			In = Tweens.DetailsMultiFadeIn,
			Out = Tweens.DetailsMultiFadeOut
		},
		Enabled = false
	},
	Lab = {
		Target = "LabUI",
		Button = UI.Modes.List.Lab,
		Details = {
			Label = UI.Modes.Details.Lab,
			In = Tweens.DetailsLabFadeIn,
			Out = Tweens.DetailsLabFadeOut
		},
		Enabled = false
	},
	Ranking = {
		Target = "RankingUI",
		Button = UI.Modes.List.Ranking,
		Details = {
			Label = UI.Modes.Details.Ranking,
			In = Tweens.DetailsRankingFadeIn,
			Out = Tweens.DetailsRankingFadeOut
		},
		Enabled = true
	},
	Settings = {
		Target = "SettingsUI",
		Button = UI.Modes.List.Settings,
		Details = {
			Label = UI.Modes.Details.Settings,
			In = Tweens.DetailsSettingsFadeIn,
			Out = Tweens.DetailsSettingsFadeOut
		},
		Enabled = true
	},
}

local Connections = {}

--// System
local Interface = {}
 
function Interface:Setup(interfaces, playergui)
	local connection
	for i, mode in pairs(Modes) do
		local button = mode.Button

		connection = Signal.wrap(button.MouseEnter):Connect(function()
			TweenService:Create(
				button,
				TweenInfo.new(.2, Enum.EasingStyle.Back),
				{Size = UDim2.fromScale(1.1, 0.22)}
			):Play()
			TweenService:Create(
				button.Sprite,
				TweenInfo.new(.2, Enum.EasingStyle.Back),
				{Size = UDim2.fromScale(1, 0.85)}
			):Play()
			mode.Details.In:Play()
			SoundPlayer:Play("ModeHover")
		end)
		connection:Disconnect()
		table.insert(Connections, connection)

		if not mode.Enabled then continue end

		connection = Signal.wrap(button.Activated):Connect(function()
			if db then return end
			db = true

			SoundPlayer:Play("ModeSelect")
			self:Switch(mode.Target)
		end)
		connection:Disconnect()
		table.insert(Connections, connection)	
	end

	connection = Signal.wrap(UI.Character.SpinButton.Activated):Connect(function()
		Tweens.CharacterSpin:Cancel()
		UI.Character.Sprite.Rotation = 0
		Tweens.CharacterSpin:Play()
		SoundPlayer:Play("Spinny")
	end)
	connection:Disconnect()
	table.insert(Connections, connection)	

	Interfaces = interfaces
	UI.Enabled = false
	UI.Parent = playergui
end

function Interface:Reset()
	for i, mode in pairs(Modes) do
		local button = mode.Button
		button.Size = UDim2.fromScale(0.9, 0.18)
		button.Sprite.Size = UDim2.fromScale(0.8, 0.75)

		mode.Details.Label.TextTransparency = 1
	end

	UI.Modes.Position = UDim2.fromScale(-0.5, 0.5)
	UI.Character.Position = UDim2.fromScale(1.65, 1.05)
end

function Interface:Open()
	self:Reset()

	Scenery:Setup("MenuUI")

	for i,flow in pairs(Flows) do
		flow:Play()
	end

	Interfaces.TrackPlayer:Play("MenuUI-Theme", true)

	UI.Enabled = true
end

function Interface:Close() --[[ Default ]]
	UI.Enabled = false
end

function Interface:Switch(target) --[[ Default ]]
	local target = Interfaces[target]

	self:Stop()
	Interfaces.Transition:Open()

	self:Close()
	target:Open(script.Name)

	Interfaces.Transition:Close()
	target:Play()
end

function Interface:Play()
	for i, connection in pairs(Connections) do
		connection:Reconnect()
	end

	Tweens.ModesGoIn:Play()
	Tweens.CharacterGoIn:Play()

	db = false
end

function Interface:Stop()
	for i,connection in pairs(Connections) do
		connection:Disconnect()
	end

	Interfaces.TrackPlayer:Stop(true)
end

return Interface
