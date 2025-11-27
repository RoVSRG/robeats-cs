--[[
	useTransient Hook

	Convenience hook for accessing Transient state with path strings.
	Automatically subscribes to changes using useVal.

	Usage:
		local selectedSong = useTransient("song.selected")
		local profile = useTransient("profile")
		local rating = useTransient("profileAttributes.rating")
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Transient = require(ReplicatedStorage.State.Transient)
local useVal = require(script.Parent.useVal)

local function useTransient(path)
	-- Navigate through Transient using dot notation
	local parts = string.split(path, ".")
	local target: any = Transient

	for _, part in ipairs(parts) do
		target = target[part]

		if not target then
			warn(("[useTransient] Invalid path: '%s' (failed at '%s')"):format(path, part))
			return nil
		end
	end

	-- Subscribe to the Val instance using useVal
	-- Type cast to suppress error since we know it's a Val at runtime
	return useVal(target :: any)
end

return useTransient
