local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPList = require(game.ReplicatedStorage.Shared.SPList)

local SPMultiDict = {}

function SPMultiDict:new()
	local self = {}
	
	self._dict = SPDict:new()
	
	local function verify_list_exists(key)		
		if not self._dict:contains(key) then
			self._dict:add(key, SPList:new())
		end
	end	
	
	function self:count_of(key)
		verify_list_exists(key)
		return self._dict:get(key):count()
	end
	function self:push_back_to(key,value)
		verify_list_exists(key)
		self._dict:get(key):push_back(value)
	end
	function self:pop_back_from(key)
		verify_list_exists(key)
		local rtv = self._dict:get(key):pop_back()
		if self._dict:get(key):count() == 0 then
			self._dict:add(key,nil)
		end
		return rtv
	end
	function self:list_of(key)
		verify_list_exists(key)
		return self._dict:get(key)
	end
	function self:key_itr()
		return self._dict:key_itr()
	end
	function self:count()
		return self._dict:count()
	end
	
	return self
end

return SPMultiDict
