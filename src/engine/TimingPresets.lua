local TimingPresets = {}

function TimingPresets.calculateTimingWindows(od)
	local timing_windows = {}

	-- osu! OD-based timing window calculations
	-- MAX (marvelous) is constant at 16ms
	timing_windows.NoteMarvelousMaxMS = 16
	timing_windows.NoteMarvelousMinMS = -16

	-- 300 (perfect): 64 - 3 × OD
	local perfect_window = 64 - 3 * od
	timing_windows.NotePerfectMaxMS = perfect_window
	timing_windows.NotePerfectMinMS = -perfect_window

	-- 200 (great): 97 - 3 × OD
	local great_window = 97 - 3 * od
	timing_windows.NoteGreatMaxMS = great_window
	timing_windows.NoteGreatMinMS = -great_window

	-- 100 (good): 127 - 3 × OD
	local good_window = 127 - 3 * od
	timing_windows.NoteGoodMaxMS = good_window
	timing_windows.NoteGoodMinMS = -good_window

	-- 50 (bad): 151 - 3 × OD
	local bad_window = 151 - 3 * od
	timing_windows.NoteBadMaxMS = bad_window
	timing_windows.NoteBadMinMS = -bad_window

	return timing_windows
end

return TimingPresets
