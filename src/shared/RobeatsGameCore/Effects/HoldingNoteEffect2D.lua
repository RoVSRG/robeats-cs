local EffectSystem = require("@shared/RobeatsGameCore/Effects/EffectSystem")
local SPUtil = require("@shared/Shared/SPUtil")
local CurveUtil = require("@shared/Shared/CurveUtil")
local NoteResult = require("@shared/RobeatsGameCore/Enums/NoteResult")
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")
local Skins = require("@shared/Skins")

local HoldingNoteEffect2D = {}
HoldingNoteEffect2D.Type = "HoldingNoteEffect2D"

local STARTING_ALPHA = 0.1
local ENDING_ALPHA = 0

function HoldingNoteEffect2D:new(_game, _track_index)
	local self = EffectSystem:EffectBase()
	self.ClassName = HoldingNoteEffect2D.Type
	
	local _effect_obj = nil;
	local _anim_t = 0
	
	local function update_visual()
		_effect_obj.ImageTransparency = _anim_t
	end	
	
	function self:cons()
		local _skin = _game:get_skin()
		local proto = _skin.EffectProto

		_effect_obj = _game._object_pool:depool(self.ClassName)
		if _effect_obj == nil then
			_effect_obj = proto:Clone()
		end
		
		_anim_t = 0
		update_visual()
	end	
	
	--[[Override--]] function self:add_to_parent(parent)
		local gameplayframe = EnvironmentSetup:get_player_gui_root().GameplayFrame
		local buttons = gameplayframe.TriggerButtons
		_effect_obj.Parent = buttons['Button'.._track_index]
	end
	
	--[[Override--]] function self:update(dt_scale)
		_anim_t = _anim_t + CurveUtil:SecondsToTick(0.25) * dt_scale
		update_visual()	
	end	
	--[[Override--]] function self:should_remove()
		return _anim_t >= 1
	end	
	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,_effect_obj)
	end		
	
	self:cons()
	return self
end

return HoldingNoteEffect2D
