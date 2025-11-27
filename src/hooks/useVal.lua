--[[
	useVal Hook

	Subscribe a React component to a Val instance and re-render on changes.

	Usage:
		local selectedSong = useVal(Transient.song.selected)
		local rating = useVal(Transient.profileAttributes.rating)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local useState = React.useState
local useEffect = React.useEffect

local function useVal(valInstance)
	-- Initialize with current value
	local value, setValue = useState(valInstance:get())

	-- Subscribe to changes
	useEffect(function()
		-- Register listener that updates state when Val changes
		local disconnect = valInstance:on(function(newValue)
			setValue(newValue)
		end)

		-- Cleanup: disconnect listener when component unmounts
		return disconnect
	end, { valInstance })

	return value
end

return useVal
