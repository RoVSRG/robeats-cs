local HttpService = game:GetService("HttpService")

local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SongErrorParser = require(game.ReplicatedStorage.RobeatsGameCore.SongErrorParser)

local SongMetadata = require(workspace:WaitForChild("Songs"):WaitForChild("SongMetadata"))

local SongDatabase = {}

SongDatabase.SongStatus = {
	RANKED = "RANKED";
	UNRANKED = "UNRANKED";
}

function SongDatabase:new()
	local self = {}
	self.SongMode = SongDatabase.SongMode

	local _all_keys = SongMetadata
	local _map_data_cache = SPDict:new()

	function self:cons()
		for itr_key, data in self:key_itr() do
			data.SongKey = itr_key
		end
	end

	function self:key_itr()
		return ipairs(_all_keys)
	end

	function self:get_key_count()
		return #_all_keys
	end

	function self:get_data_for_key(key)
		return _all_keys[key]
	end

	function self:contains_key(key)
		return _all_keys[key] ~= nil
	end

	function self:key_get_audiomod(key)
		local data = self:get_data_for_key(key)
		if data.AudioMod == 1 then
			return SongDatabase.SongMode.SupporterOnly
		end
		return SongDatabase.SongMode.Normal
	end

	function self:render_coverimage_for_key(cover_image, overlay_image, key)
		local songdata = self:get_data_for_key(key)
		cover_image.Image = songdata.AudioCoverImageAssetId

		if overlay_image then
			local audiomod = self:key_get_audiomod(key)
			if audiomod == SongDatabase.SongMode.SupporterOnly then
				overlay_image.Image = "rbxassetid://837274453"
				overlay_image.Visible = true
			else
				overlay_image.Visible = false
			end
		end
	end

	function self:get_image_for_key(key)
		local songdata = self:get_data_for_key(key)
		if songdata.AudioCoverImageAssetId ~= "" then
			return songdata.AudioCoverImageAssetId
		else
			return "rbxassetid://6799053340"
		end
	end

	function self:get_title_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioFilename
	end

	function self:get_artist_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioArtist
	end

	function self:get_md5_hash_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioMD5Hash
	end

	function self:get_difficulty_for_key(key, rate)
		rate = if rate then rate else 1

		local songdata = self:get_data_for_key(key)
		local difficulty = songdata.AudioDifficulty

		if rate == 1 then
			return difficulty
		elseif rate < 1 then
			return difficulty * (459616.4 + (-0.008317092 - 459616.4)/(1 + (rate/5051.127)^1.532436))
		else
			return difficulty * (946.4179 + (-6.728875 - 946.4179)/(1 + (rate/85114960)^0.2634697))
		end
	end

	function self:get_description_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioDescription
	end

	function self:get_mapper_for_key(key)
		local songdata = self:get_data_for_key(key)
		
		if songdata.AudioMapper ~= nil then
			return songdata.AudioMapper
		else
			return "Unknown"
		end
	end

	function self:get_song_length_for_key(key, rate)
		local hit_objects = self:get_hit_objects_for_key(key)
		local last_hit_ob = hit_objects[#hit_objects]

		if rate then
			return (last_hit_ob.Time + (last_hit_ob.Duration or 0)) / rate
		end
		
		return last_hit_ob.Time + (last_hit_ob.Duration or 0)
	end
	
	function self:get_nps_graph_for_key(key, resolution)
		resolution = resolution or 1

		local hitobjects = self:get_hit_objects_for_key(key)

		local lastTime = 0
		local nps = 0

		local graph = {}

		for itr_index, itr_hit_object in ipairs(hitobjects) do
			if itr_hit_object.Time - lastTime > 1000 then
				if itr_index % resolution == 0 then
					table.insert(graph, nps)
				end
				lastTime = itr_hit_object.Time
				nps = 0
				continue
			end
			nps += 1
		end

		return graph
	end

	function self:get_search_string_for_key(key)
		local data = self:get_data_for_key(key)
		if data ~= nil then
			local _search_data = {
				data.AudioArtist,
				data.AudioFilename,
				data.AudioDifficulty
			}

			return table.concat(_search_data, " "):lower()
		end
		return ""
	end

	function self:filter_keys(str)
		local ret = {}

		for key, data in self:key_itr() do
			if not str or str == "" then
				table.insert(ret, data)
			else
				local search_str = self:get_search_string_for_key(key)
				if string.find(search_str, str:lower()) ~= nil then
					table.insert(ret, data)
				end
			end
		end

		return ret
	end

	function self:get_hit_objects_for_key(key, rate, mirror)
		local data = self:get_data_for_key(key)
		local map_data = _map_data_cache:get(key)

		if not map_data then
			local splits = data.AudioMapData:GetChildren()

			-- Map data is split up into 200k character blocks due to Roblox's limit of 200k characters per StringValue instance.
			-- We use StringValues instead of ModuleScripts because using ModuleScripts causes massive performace problems in Studio.

			table.sort(splits, function(a, b)
				return tonumber(a.Name) < tonumber(b.Name)
			end)

			local map_json = ""

			for _, split in ipairs(splits) do
				map_json ..= split.Value
			end

			map_data = HttpService:JSONDecode(map_json)

			_map_data_cache:add(key, map_data)
		end

		if (rate == 1 or rate == nil) and (not mirror) then
			return map_data
		else
			local _rate_map_data = {}

			for i = 1, #map_data do
				local itr_hit_object = map_data[i]

				if itr_hit_object.Type == 1 then
					_rate_map_data[i] = {
						Time = itr_hit_object.Time / rate,
						Track = mirror and 5 - itr_hit_object.Track or itr_hit_object.Track,
						Type = itr_hit_object.Type
					}
				elseif itr_hit_object.Type == 2 then
					_rate_map_data[i] = {
						Time = itr_hit_object.Time / rate,
						Track = mirror and 5 - itr_hit_object.Track or itr_hit_object.Track,
						Duration = itr_hit_object.Duration / rate,
						Type = itr_hit_object.Type
					}
				end
			end

			return _rate_map_data
		end
	end

	function self:get_key_for_hash(hash)
		for itr_key, itr_audio_data in pairs(_all_keys) do
			if itr_audio_data.AudioMD5Hash == hash then
				return itr_key
			end
		end
		return self:invalid_songkey()
	end

	function self:get_hash_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioMD5Hash
	end

	function self:get_note_metrics_for_key(key)
		local total_notes = 0
		local total_holds = 0
		local total_left_hand_objects = 0
		local total_right_hand_objects = 0

		for _, hit_object in pairs(self:get_hit_objects_for_key(key)) do
			if hit_object.Type == 1 then
				total_notes += 1
			elseif hit_object.Type == 2 then
				total_holds += 1
			end

			if hit_object.Track > 2 then
				total_right_hand_objects += 1
			else
				total_left_hand_objects += 1
			end
		end

		return total_notes, total_holds, total_left_hand_objects, total_right_hand_objects
	end
	
	function self:invalid_songkey() return -1 end

	self:cons()

	return self
end

return SongDatabase:new()