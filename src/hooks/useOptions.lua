--[[
	useOptions Hook

	Access Options state with metadata for form components.
	Returns the current value, a setter function, and the option configuration.

	Usage:
		local scrollSpeed, setScrollSpeed, config = useOptions("ScrollSpeed")
		-- config contains: { type, displayName, category, increment, min, max, ... }
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Options = require(ReplicatedStorage.State.Options)
local useVal = require(script.Parent.useVal)

local function useOptions(optionKey: string)
	local optionVal: any = Options[optionKey]

	if not optionVal then
		warn(("[useOptions] Option '%s' not found in Options"):format(optionKey))
		-- Return dummy values to maintain type signature
		local function noop(...: any) end
		return nil :: any, noop, nil
	end

	local value, setValue = useVal(optionVal)
	local config = optionVal._optionConfig

	return value, setValue, config
end

return useOptions
