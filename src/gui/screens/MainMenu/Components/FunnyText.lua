local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Util.UI)

local useEffect = React.useEffect
local useState = React.useState

local MESSAGES = {
	"Welcome to a classic RCS 💖",
	"Sponsored by kisperal and astral/ary ✨",
	"We're a commoonity ofd gamers",
	"Robeats is require a lot of skill",
	"go away and play some songs",
	"STOP STARING AT ME",
	"we listened?!?",
	"kisperal is the best dev",
	"no astral is",
	"welcome back wheelchair gang 🧑‍🦽🧑‍🦽🧑‍🦽"
}

local function FunnyText(props)
	local text, setText = useState("")
	
	useEffect(function()
		local isMounted = true
		
		local function loop()
			while isMounted do
				local selected = MESSAGES[math.random(1, #MESSAGES)]
				local currentText = ""
				
				for _, codepoint in utf8.codes(selected) do
					if not isMounted then break end
					currentText = currentText .. utf8.char(codepoint)
					setText(currentText)
					task.wait(0.06)
				end
				
				if isMounted then
					task.wait(6.5)
				end
			end
		end
		
		task.spawn(loop)
		
		return function()
			isMounted = false
		end
	end, {})

	return UI.Text({
		Text = text,
		Font = props.Font or Enum.Font.SourceSansLight,
		TextSize = props.TextSize or 24,
		TextScaled = props.TextScaled or false,
		TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255),
		Size = props.Size or UDim2.new(1, 0, 0, 30),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

return FunnyText
