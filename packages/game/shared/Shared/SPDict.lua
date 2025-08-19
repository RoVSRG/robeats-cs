local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SPList = require(game.ReplicatedStorage.Shared.SPList)

local SPDict = {}

function SPDict:new()
	local self = {}

	local _count = 0
	self._table = {}

	function self:add(key, value)
		if self:contains(key) then
			self._table[key] = value
			return
		end
		self._table[key] = value
		_count = _count + 1
	end
	function self:remove(key)
		if not self:contains(key) then
			return false
		end
		self._table[key] = nil
		_count = _count - 1

		return true
	end
	function self:get(key)
		return self._table[key]
	end
	function self:contains(key)
		return self._table[key] ~= nil
	end
	function self:contains_any(any_table)
		for i=1,#any_table do
			if self:contains(any_table[i]) then
				return true
			end
		end
		return false
	end
	function self:count()
		return _count
	end
	function self:clear()
		_count = 0
		SPUtil:table_clear(self._table)
	end
	function self:key_itr()
		return pairs(self._table)
	end
	function self:key_list()
		local rtv = SPList:new()
		for k,v in self:key_itr() do
			rtv:push_back(k)
		end
		return rtv
	end
	function self:add_table(tbl)
		for k,v in pairs(tbl) do
			self:add(k,v)
		end
		return self
	end

	return self
end

return SPDict
