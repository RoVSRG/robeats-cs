local function formatDuration(ms)
	local totalSeconds = math.floor(ms / 1000)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

return {
    formatDuration = formatDuration,
}