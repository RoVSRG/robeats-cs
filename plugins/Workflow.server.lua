local Selection = game:GetService("Selection")
local Toolbar = plugin:CreateToolbar("Workflow")
local Button = Toolbar:CreateButton("Change Working Screen", "Change the working screen to the selected GUI", "rbxassetid://4458901886")

local function getCurrentSelection()
    local selection = Selection:Get()
    if #selection == 0 then
        return nil
    end

    local selected = selection[1]
    if not selected:IsA("GuiObject") then
        return nil
    end

    return selected
end

local function swap()
    local selected = getCurrentSelection()
    if not selected then
        warn("No GUI object selected or the selection is not a GuiObject.")
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

    -- Create a copy of the selected GUI object
    local selectedClone = selected:Clone()

    -- Set the parent of the cloned object to the ScreenGui
    selectedClone.Parent = dev
end

Button.Click:Connect(swap)