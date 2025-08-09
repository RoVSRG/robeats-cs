local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui

local screens = playerGui:WaitForChild("Screens")
local live = playerGui:WaitForChild("Main")

local function _getTaggedTemplates(screen: Frame)
	local templates = {}

	for _, child in screen:GetDescendants() do
		if CollectionService:HasTag(child, "Template") then
			templates[child.Name] = child
		end
	end

	return templates
end

local templates = {}

local function _extractTemplates(screen: Frame)
	templates[screen.Name] = {}
	local screenTemplates = templates[screen.Name]

	local tagged = _getTaggedTemplates(screen)

	for name, template in tagged do
		screenTemplates[name] = template
		template.Parent = nil
	end

	if screen:FindFirstChild("Templates") then
		for _, child in screen:GetChildren() do
			if not screenTemplates[child.Name] then
				screenTemplates[child.Name] = child
			end
		end
	end
end

_extractTemplates(live)
_extractTemplates(screens)

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

function ScreenChief:GetTemplates(screen: string)
	return templates[screen] or {}
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
