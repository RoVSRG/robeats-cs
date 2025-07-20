local RobloxMaxImageSize = 1024
local function AnimateGif(ImageLabel:ImageLabel,ImageWidth,ImageHeight,Rows,Columns,NumberOfFrames,ImageId,FPS)

	if ImageId then ImageLabel.Image = "http://www.roblox.com/asset/?id=" .. ImageId end

	local RealWidth, RealHeight

	if math.max(ImageWidth,ImageHeight) > RobloxMaxImageSize then -- Compensate roblox size

		local Longest = ImageWidth > ImageHeight and "Width" or "Height"

		if Longest == "Width" then

			RealWidth = RobloxMaxImageSize
			RealHeight = (RealWidth / ImageWidth) * ImageHeight

		elseif Longest == "Height" then

			RealHeight = RobloxMaxImageSize
			RealWidth = (RealHeight / ImageHeight) * ImageWidth

		end

	else
		RealWidth,RealHeight = ImageWidth,ImageHeight
	end

	local FrameSize = Vector2.new(RealWidth/Columns,RealHeight/Rows)
	ImageLabel.ImageRectSize = FrameSize

	local CurrentRow, CurrentColumn = 0,0
	local Offsets = {}

	for i = 1,NumberOfFrames do

		local CurrentX = CurrentColumn * FrameSize.X
		local CurrentY = CurrentRow * FrameSize.Y

		table.insert(Offsets,Vector2.new(CurrentX,CurrentY))

		CurrentColumn += 1

		if CurrentColumn >= Columns then
			CurrentColumn = 0
			CurrentRow += 1
		end

	end

	local TimeInterval = FPS and 1/FPS or 0.1

	local Index = 0
	task.spawn(function()

		while task.wait(TimeInterval) and ImageLabel:IsDescendantOf(game) do
			Index += 1

			ImageLabel.ImageRectOffset = Offsets[Index]

			if Index >= NumberOfFrames then
				Index = 0
			end

		end

	end)

end

AnimateGif(script.Parent,1500,2100,8,5,18,15399653535,15)
