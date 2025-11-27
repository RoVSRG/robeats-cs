--[[
	useValSetter Hook

	Get a stable setter function for a Val instance.
	The returned function can be safely passed as a callback without causing re-renders.

	Usage:
		local setRate = useValSetter(Transient.song.rate)
		setRate(150) -- Updates Val to 150
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local useCallback = React.useCallback

local function useValSetter(valInstance)
	-- Return a stable callback that sets the Val instance's value
	return useCallback(function(newValue)
		valInstance:set(newValue)
	end, { valInstance })
end

return useValSetter
