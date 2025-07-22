local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local SongErrorParser	= {}

local __tmpctr = 4
local function track_time_to_hash(p_track,p_time)

	return string.format("%d_%d",p_track,p_time)
end

function SongErrorParser:scan_audiodata_for_errors(audio_data)
	local tracked_notes = SPDict:new()	
	
	for i=1,#audio_data.HitObjects do
		local itr_hitobj = audio_data.HitObjects[i]
		
		local track = itr_hitobj.Track
		if track == nil then
			track = __tmpctr
			__tmpctr = __tmpctr + 1
		end		
		
		local itr_hitobj_hash = track_time_to_hash(itr_hitobj.Time,track)
		if tracked_notes:contains(itr_hitobj_hash) then
			error(string.format(
				"SongErrorParser - Likely duplicate time/track note for (%s) at note[%d](Type[%d] Time[%d] Track[%d])",
				audio_data.AudioFilename,
				i,
				itr_hitobj.Type,
				itr_hitobj.Time,
				track
			))	
		end
		tracked_notes:add(itr_hitobj_hash,true)
		
		if itr_hitobj.Type == 2 then
			local itr_hitobj_end_hash = track_time_to_hash(itr_hitobj.Time + itr_hitobj.Duration,track)
			if tracked_notes:contains(itr_hitobj_end_hash) then
				error(string.format(
					"SongErrorParser - Likely duplicate time/track (HELD NOTE END) for (%s) at note[%d](Type[%d] Time[%d] Track[%d])",
					audio_data.AudioFilename,
					i,
					itr_hitobj.Type,
					itr_hitobj.Time,
					track
				))	
			end		
			
			tracked_notes:add(itr_hitobj_end_hash,true)
		end		
	end	
	
end

return SongErrorParser 
