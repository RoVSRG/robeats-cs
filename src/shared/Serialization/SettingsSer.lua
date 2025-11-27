local opts = require(game.ReplicatedStorage.State.Options)
local ss = {}
ss.get_serialized_opts = function()
	local EX = { "StartTimeMs", "GameSlot", "RecordReplay", "Mods" }
	local data = {}
	for itemname, option in pairs(opts) do
		if table.find(EX, itemname) then
			continue
		end
		if type(option) == "function" then
			continue
		end
		if option.get == nil then
			continue
		end
		if option:get() == nil then
			if itemname == "Skin2D" then
				data[itemname] = nil
			end
			continue
		end

		if typeof(option:get()) == "Color3" then
			data[itemname] = {
				r = option:get().R,
				g = option:get().G,
				b = option:get().B,
			}
		else
			data[itemname] = option:get()
		end
	end
	print("[Options.lua] Successfully serialized option state.")
	return data
end

ss.apply_serialized_opts = function(serialized_data)
	for itemname, value in pairs(serialized_data) do
		local option = opts[itemname]

		if option == nil then
			continue
		end

		if typeof(value) == "table" and value.r and value.g and value.b then
			option:set(Color3.new(value.r, value.g, value.b))
		else
			option:set(value)
		end
	end
	print("[Options.lua] Successfully applied options from serialized data.")
end

return ss
