local NoteResult = {
	Miss = 0;
	Bad = 1;
	Good = 2;
	Great = 3;
	Perfect = 4;
	Marvelous = 5;
}

NoteResult.Colors = {
	[NoteResult.Miss] = Color3.fromRGB(190, 30, 30),
	[NoteResult.Bad] = Color3.fromRGB(174, 22, 194),
	[NoteResult.Good] = Color3.fromRGB(12, 15, 151),
	[NoteResult.Great] = Color3.fromRGB(57, 192, 16),
	[NoteResult.Perfect] = Color3.fromRGB(235, 220, 13),
	[NoteResult.Marvelous] = Color3.fromRGB(255, 255, 255)
}

function NoteResult:timedelta_to_result(time_to_end, _game)
	local note_bad_max, note_good_max, note_great_max, note_perfect_max, note_marvelous_max, note_marvelous_min,  note_perfect_min, note_great_min, note_good_min,note_bad_min = _game._audio_manager:get_note_result_timing()
	if time_to_end >= note_bad_min and time_to_end <= note_bad_max then
		local note_result
		if time_to_end > note_bad_min and time_to_end <= note_good_min then
			note_result = NoteResult.Bad
		elseif time_to_end > note_good_min and time_to_end <= note_great_min then
			note_result = NoteResult.Good
		elseif time_to_end > note_great_min and time_to_end <= note_perfect_min then
			note_result = NoteResult.Great
		elseif time_to_end > note_perfect_min and time_to_end <= note_marvelous_min then
			note_result = NoteResult.Perfect
		elseif time_to_end > note_marvelous_min and time_to_end <= note_marvelous_max then
			note_result = NoteResult.Marvelous
		elseif time_to_end > note_marvelous_max and time_to_end <= note_perfect_max then
			note_result = NoteResult.Perfect
		elseif time_to_end > note_perfect_max and time_to_end <= note_great_max then
			note_result = NoteResult.Great
		elseif time_to_end > note_great_max and time_to_end <= note_good_max then
			note_result = NoteResult.Good
		else
			note_result = NoteResult.Bad
		end
		return true, note_result
	end	
	
	return false, NoteResult.Miss
end

function NoteResult:release_timedelta_to_result(time_to_end, _game)
	local note_bad_max, note_good_max, note_great_max, note_perfect_max, note_marvelous_max, note_marvelous_min,  note_perfect_min, note_great_min, note_good_min,note_bad_min = _game._audio_manager:get_note_result_timing()
	if time_to_end >= note_bad_min and time_to_end <= note_bad_max then
		local note_result
		if time_to_end > note_bad_min * 2 and time_to_end <= note_good_min * 2 then
			note_result = NoteResult.Bad
		elseif time_to_end > note_good_min * 2 and time_to_end <= note_great_min * 2 then
			note_result = NoteResult.Good
		elseif time_to_end > note_great_min * 2 and time_to_end <= note_perfect_min * 2 then
			note_result = NoteResult.Great
		elseif time_to_end > note_perfect_min * 2 and time_to_end <= note_marvelous_min * 2 then
			note_result = NoteResult.Perfect
		elseif time_to_end > note_marvelous_min * 2 and time_to_end <= note_marvelous_max * 2 then
			note_result = NoteResult.Marvelous
		elseif time_to_end > note_marvelous_max * 2 and time_to_end <= note_perfect_max * 2 then
			note_result = NoteResult.Perfect
		elseif time_to_end > note_perfect_max * 2 and time_to_end <= note_great_max * 2 then
			note_result = NoteResult.Great
		elseif time_to_end > note_great_max * 2 and time_to_end <= note_good_max * 2 then
			note_result = NoteResult.Good
		else
			note_result = NoteResult.Bad
		end
		return true, note_result
	end	

	return false, NoteResult.Miss
end

function NoteResult:result_to_color(result)
	return self.Colors[result]
end

return NoteResult