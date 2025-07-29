local label = script.Parent

local Messages = {
	"Welcome to a classic RCS 💖",
	"Sponsored by kisperal and astral/ary ✨",
	"We're a commoonity ofd gamers",
	"Robeats is require a lot of skill",
	"go away and play some songs",
	"STOP STARING AT ME",
	"we listened?!?",
	"kisperal is the best dev",
	"no astral is",
}

while true do
	local selected = Messages[math.random(1,#Messages)]
	
	-- Use utf8.codes to properly iterate through unicode characters
	local displayText = ""
	for pos, codepoint in utf8.codes(selected) do
		local char = utf8.char(codepoint)
		displayText = displayText .. char
		label.Text = displayText
		task.wait(.06)
	end
	task.wait(6.5)
end