wait(1)
local hue = 0
local increment = 0.04
local rainbow = script.Parent
local ob = script.Parent.Parent

while true do
	wait(3)
	
	if rainbow.Value then
		repeat
			hue = hue + increment
			if hue > 1 then 
				hue = 0 
			end
			ob.TextColor3 = Color3.fromHSV(hue, 0.35, 1)
			wait()
		until rainbow.Value == false
	end
end