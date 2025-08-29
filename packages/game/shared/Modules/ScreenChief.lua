local CollectionService = game:GetService("CollectionService")

local FX = require(game.ReplicatedStorage.Modules.FX)

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

local templates = Instance.new("Folder")
templates.Name = "TemplateCache"
templates.Parent = playerGui

local function _extractTemplatesForScreen(screenFrame: Frame)
	local screenTemplatesFolder = templates:FindFirstChild(screenFrame.Name)
	if not screenTemplatesFolder then
		screenTemplatesFolder = Instance.new("Folder")
		screenTemplatesFolder.Name = screenFrame.Name
		screenTemplatesFolder.Parent = templates
	end

	-- 1) Move all descendants tagged as Template into the cache for this screen
	local tagged = _getTaggedTemplates(screenFrame)
	for _, template in tagged do
		template.Parent = screenTemplatesFolder
	end

	local sourceTemplates = screenFrame:FindFirstChild("Templates")

	if sourceTemplates and sourceTemplates:IsA("ScreenGui") then
		for _, child in sourceTemplates:GetChildren() do
			if not screenTemplatesFolder:FindFirstChild(child.Name) then
				child.Parent = screenTemplatesFolder
			end
		end
	end
end

local function _extractTemplates(root: Instance)
	local framesToProcess = {}

	for _, wrappedScreen in root:GetChildren() do
		local screen = wrappedScreen:FindFirstChildWhichIsA("Frame")

		if screen then
			table.insert(framesToProcess, screen)
		end
	end

	for _, frame in framesToProcess do
		_extractTemplatesForScreen(frame)
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
	local folder = templates:FindFirstChild(screen)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = screen
		folder.Parent = templates
	end
	return folder
end

function ScreenChief:GetScreenGui()
	return live
end

function ScreenChief:Switch(target)
	FX.PlaySound("Select")

	local current: CanvasGroup = self:GetCurrentScreen()
	local targetScreen: CanvasGroup = self:GetScreen(target)

	current.Parent = screens -- hide old screen
	targetScreen.Parent = live -- ensure target is visible (if not already)
end

return ScreenChief
