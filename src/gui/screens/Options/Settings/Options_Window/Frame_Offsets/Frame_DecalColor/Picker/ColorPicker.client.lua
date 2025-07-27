--------------------------
-- Localize
--------------------------
local ceil,clamp,atan2,pi	= math.ceil,math.clamp,math.atan2,math.pi
local tostr,sub				= tostring,string.sub
local fromHSV				= Color3.fromHSV
local v2,udim2				= Vector2.new,UDim2.new
--------------------------
-- GUI Elements
--------------------------
local wheel		= script.Parent:WaitForChild("Wheel");
local ring		= wheel:WaitForChild("Ring");

local slider	= wheel:WaitForChild("Slider")
local slide		= slider:WaitForChild("Slide")

local colour	= script.Parent:WaitForChild("Colour");

--------------------------
-- Input variables
--------------------------
local UserInputService	= game:GetService("UserInputService")
local Mouse				= game.Players.LocalPlayer:GetMouse()

local WheelDown			= false
local SlideDown			= false

--------------------------
-- Math
--------------------------

local function toPolar(v)
	return atan2(v.y, v.x), v.magnitude;
end

local function radToDeg(x)
	return ((x + pi) / (2 * pi)) * 360;
end

--------------------------
-- Color control
--------------------------
local hue, saturation, value = 0, 0, 1;

local function update()
	local c = fromHSV(hue, saturation, value);
	
	colour.BackgroundColor3 = c
	colour.TextLabel.Text	=	sub(tostr(ceil(clamp(c.r*255,0,255))),1,3)..", "..
								sub(tostr(ceil(clamp(c.g*255,0,255))),1,3)..", "..
								sub(tostr(ceil(clamp(c.b*255,0,255))),1,3)
end

--------------------------
-- GUI control
--------------------------
local function UpdateSlide(mouseX,mouseY)	
	local differenceY = mouseY - slider.AbsolutePosition.y;
	local maxValue = slider.AbsoluteSize.y - slide.AbsoluteSize.y
	local clampedY = clamp(differenceY, 0, maxValue);
	slide.Position = udim2(0, 0, 0, clampedY);
	
	value = 1-(clampedY / maxValue);
	slide.BackgroundColor3 = fromHSV(0, 0, 1-value);
	
	update();
end
local function UpdateRing(iX,iY)
	local r = wheel.AbsoluteSize.x/2
	local d = v2(iX, iY) - wheel.AbsolutePosition - wheel.AbsoluteSize/2;

	if (d:Dot(d) > r*r) then
		d = d.unit * r;
	end
	
	ring.Position = udim2(0.5, d.x, 0.5, d.y);
	
	local phi, len = toPolar(d * v2(1, -1));
	hue, saturation = radToDeg(phi)/360, len / r;
	slider.BackgroundColor3 = fromHSV(hue, saturation, 1);
	
	update();
end


wheel.MouseButton1Down:Connect(function()
	WheelDown = true
	UpdateRing(Mouse.X,Mouse.Y)
end)
slider.MouseButton1Down:Connect(function()
	SlideDown = true
	UpdateSlide(Mouse.X,Mouse.Y)
end)


UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		WheelDown = false
		SlideDown = false
	end
end)

wheel.MouseMoved:Connect(function()
	if WheelDown then
		UpdateRing(Mouse.X,Mouse.Y)
	end
end)
slider.MouseMoved:Connect(function()
	if SlideDown then
		UpdateSlide(Mouse.X,Mouse.Y)
	end
end)