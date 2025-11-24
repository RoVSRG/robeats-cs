local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)

local FlashEvery = {}

function FlashEvery:new(max_time_seconds)
	local self = {}	
	local _tick_increment = 0
	local _time = 0
	
	function self:update(dt_scale)
		_time = _time + _tick_increment * dt_scale
	end
	
	function self:set_flash_speed(max_time_seconds)
		_tick_increment = CurveUtil:SecondsToTick(max_time_seconds)
	end
	self:set_flash_speed(max_time_seconds)
	
	function self:flash_now()
		_time = 1
	end	
	
	function self:do_flash()
		local rtv = _time >= 1
		if rtv then
			_time = 0
		end		
		return rtv
	end
		
	return self
end

return FlashEvery
