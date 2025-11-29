--[[
	useOptionCategory Hook

	Returns a stable, sorted list of option entries for a given category.
	Each entry includes the option key, Val instance, and configuration.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Options = require(ReplicatedStorage.State.Options)

local useMemo = React.useMemo

local function useOptionCategory(category: string)
	return useMemo(function()
		local entries = {}

		for key, val in pairs(Options) do
			if typeof(val) == "table" and val._optionConfig and val._optionConfig.category == category then
				table.insert(entries, {
					key = key,
					val = val,
					config = val._optionConfig,
				})
			end
		end

		table.sort(entries, function(a, b)
			local orderA = a.config.layoutOrder or math.huge
			local orderB = b.config.layoutOrder or math.huge

			if orderA == orderB then
				local nameA = a.config.displayName or a.key
				local nameB = b.config.displayName or b.key
				return nameA < nameB
			end

			return orderA < orderB
		end)

		return entries
	end, { category })
end

return useOptionCategory
