local React = require(game:GetService("ReplicatedStorage").Packages.React)

local useState = React.useState
local useEffect = React.useEffect

--[[
	useDebounce - Debounce hook for delaying value updates

	Args:
		value: any - The value to debounce
		delay: number - Delay in seconds (default: 0.3)

	Returns:
		debouncedValue: any - The debounced value

	Example:
		local searchTerm, setSearchTerm = React.useState("")
		local debouncedSearch = useDebounce(searchTerm, 0.3)
		-- debouncedSearch only updates 300ms after searchTerm stops changing
]]
local function useDebounce(value, delay)
	delay = delay or 0.3 -- Default 300ms

	local debouncedValue, setDebouncedValue = useState(value)

	useEffect(function()
		-- Set up timer to update debounced value after delay
		local timeoutId = task.delay(delay, function()
			setDebouncedValue(value)
		end)

		-- Cleanup function: cancel timeout if value changes before delay expires
		return function()
			task.cancel(timeoutId)
		end
	end, { value, delay })

	return debouncedValue
end

return useDebounce
