local SPMultiDict = require(game.ReplicatedStorage.Shared.SPMultiDict)
local ObjectPool = {}

function ObjectPool:new()
	local self = {}

	local _pooled_parent = Instance.new("Folder",game.Lighting)
	_pooled_parent.Name = "ObjPooledParent"

	self._key_to_pooled = SPMultiDict:new()

	function self:cons()
	end

	function self:repool(key, obj)
		self._key_to_pooled:push_back_to(key,obj)

		obj.Parent = nil
	end

	function self:depool(key)
		if self._key_to_pooled:count_of(key) == 0 then
			return nil
		end
		return self._key_to_pooled:pop_back_from(key)
	end

	self:cons()
	return self;
end

return ObjectPool
