local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui

local screens = playerGui:WaitForChild("Screens")
local live = playerGui:WaitForChild("Main")

local ScreenChief = {}

function ScreenChief:GetCurrentScreen()
	return live:FindFirstChildWhichIsA("Frame")
end

function ScreenChief:GetScreen(name)
	local screen = screens:FindFirstChild(name) or live:FindFirstChild(name)
	
	if not screen then
		error(`"{screen}" is not a valid screen.`)
	end
	
	return screen
end

local function _getTaggedTemplates(screen: Frame)
	local templates = {}

	for _, child in screen:GetDescendants() do
		if CollectionService:HasTag(child, "Template") then
			templates[child.Name] = child
		end
	end

	return templates
end

local templatesCache = {}

function ScreenChief:GetTemplates(name: string)
	if templatesCache[name] then
		return templatesCache[name]
	end

	local screen: Frame = self:GetScreen(name)
	local templates = _getTaggedTemplates(screen)

	templatesCache[name] = templates

	return templates
end

function ScreenChief:GetScreenGui()
	return live
end

function ScreenChief:Switch(target)
	local current: CanvasGroup = self:GetCurrentScreen()
	local targetScreen: CanvasGroup = self:GetScreen(target)

	current.Parent = screens -- hide old screen
	targetScreen.Parent = live -- ensure target is visible (if not already)
end


return ScreenChief
