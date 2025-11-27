local Selection = game:GetService("Selection")
local Toolbar = plugin:CreateToolbar("Workflow")
local Button = Toolbar:CreateButton("Change Working Screen", "Change the working screen to the selected GUI", "rbxassetid://4458901886")

local function parseRobloxPath(path: string, up: number?)
	local pathParts = {}

	for part in path:gmatch("[^%.]+") do
		table.insert(pathParts, part)
	end

    if up and up > 0 then
        for i = 1, up do
            table.remove(pathParts) -- Remove last part for each level up
        end
    end

	return pathParts
end

local function getCurrentSelection()
    local selection = Selection:Get()
    if #selection == 0 then
        return nil
    end

    local selected = selection[1]
    if not selected:IsA("GuiObject") then
        return nil
    end

    -- Check if the selected object is from StarterGui.Screens
    local screens = game.StarterGui:FindFirstChild("Screens")
    if not screens then
        return nil
    end

    -- Check if the selected object is a child of StarterGui.Screens
    local current = selected
    while current do
        if current == screens then
            return selected
        end
        current = current.Parent
    end

    return nil
end

local function swap()
    local selected = getCurrentSelection()
    if not selected then
        warn("No GUI object selected, selection is not a GuiObject, or selection is not from StarterGui.Screens.")
        return
    end

    -- Get the parent of the selected GUI object
    local parent = selected.Parent
    if not parent then
        warn("Selected GUI object has no parent.")
        return
    end

    local dev = game.StarterGui:FindFirstChildWhichIsA("ScreenGui")

    if not dev then
        warn("No ScreenGui found in StarterGui.")
        return
    end

    dev:ClearAllChildren()

    local instancePath = "game." .. selected:GetFullName()
    local containingPath = parseRobloxPath(instancePath, 1)

    dev:SetAttribute("__BASEPATH", table.concat(containingPath, "."))

    -- Create a copy of the selected GUI object
    local selectedClone = selected:Clone()

    -- Set the parent of the cloned object to the ScreenGui
    selectedClone.Parent = dev
    
    -- Select the cloned object for further operations
    Selection:Set({selectedClone})
end

Button.Click:Connect(swap)