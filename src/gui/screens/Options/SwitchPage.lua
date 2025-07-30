local pages = script.Parent:WaitForChild("OptionsPages")
local activePage = pages:WaitForChild("General")

return function(target: string)
    activePage.Visible = false
    activePage = pages:FindFirstChild(target)
    for _, page in pairs(pages:GetChildren()) do
        page.Visible = false
    end

    activePage.Visible = true
end