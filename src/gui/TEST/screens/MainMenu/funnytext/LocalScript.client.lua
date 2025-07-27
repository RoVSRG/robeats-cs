local label = script.Parent

local Messages = {
	"Welcome to a classic RCS 💖",
	"Sponsored by kisperal and astral ✨"
}

while true do
	local selected = Messages[math.random(1,#Messages)]

	for char = 1, #selected do
		label.Text = string.sub(selected, 1, char)
		task.wait(.06)
	end
	task.wait(6.5)
end