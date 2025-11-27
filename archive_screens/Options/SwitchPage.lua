local pages = script.Parent:WaitForChild("Pages")
local activePage = pages:WaitForChild("General")

return function(target: string)
	activePage.Visible = false
	activePage = pages:FindFirstChild(target)
	for _, page in pairs(pages:GetChildren()) do
		if page:IsA("Frame") then
			page.Visible = false
		end
	end

	activePage.Visible = true
end
