local SPList = require(game.ReplicatedStorage.Shared.SPList)

local EffectSystem = {}

function EffectSystem:new()
	local self = {}	
	
	local _effect_root = Instance.new("Folder",game.Workspace)
	_effect_root.Name = "EffectRoot"
	local _effects = SPList:new();	
	
	function self:cons()
	end
	
	function self:teardown()
		for i=_effects:count(),1,-1 do
			local itr_effect = _effects:get(i)
			itr_effect:do_remove()
		end
		_effects:clear()
		_effect_root:Destroy()
	end
	
	function self:update(dt_scale)
		for i=_effects:count(),1,-1 do
			local itr_effect = _effects:get(i)
			itr_effect:update(dt_scale)
			if itr_effect:should_remove() then
				itr_effect:do_remove()
				_effects:remove_at(i)
			end
		end
	end
		
	function self:add_effect(effect)
		effect:add_to_parent(_effect_root)
		_effects:push_back(effect)
		return effect
	end	
	
	self:cons()	
	return self
end

function EffectSystem:EffectBase()
	local self = {}
	
	function self:add_to_parent(parent) error("EffectBase must implement add_to_parent") end
	function self:update(dt_scale) error("EffectBase must implement update") end	
	function self:should_remove() error("EffectBase must implement should_remove") end	
	function self:do_remove() error("EffectBase must implement do_remove") end	
	
	return self
end

return EffectSystem
