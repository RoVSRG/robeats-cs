--!strict

-- VisualEffectsSystem: Clean wrapper around the existing EffectSystem
local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore._legacy.Effects.EffectSystem)

export type VisualEffectsSystem = {
	-- Core functionality
	addEffect: (self: VisualEffectsSystem, effect: any) -> any,
	update: (self: VisualEffectsSystem, dtScale: number) -> (),
	teardown: (self: VisualEffectsSystem) -> (),
}

local VisualEffectsSystem = {}

function VisualEffectsSystem.new(): VisualEffectsSystem
	local self = {} :: VisualEffectsSystem
	
	local effectSystem = EffectSystem:new()
	
	function self:addEffect(effect: any): any
		return effectSystem:add_effect(effect)
	end
	
	function self:update(dtScale: number)
		effectSystem:update(dtScale)
	end
	
	function self:teardown()
		effectSystem:teardown()
	end
	
	return self
end

return VisualEffectsSystem

