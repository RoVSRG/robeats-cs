local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerNoteEffect2D = {}
TriggerNoteEffect2D.Type = "TriggerNoteEffect2D"

function TriggerNoteEffect2D:new(_game, _track_index)
	local self = EffectSystem:EffectBase()
	self.ClassName = TriggerNoteEffect2D.Type

	local _effect_obj = nil
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
			_effect_obj.ImageTransparency = .5
		end

		_anim_t = 0
		update_visual()
	end

	--[[Override--]] function self:add_to_parent(parent)
		local _player_gui_root = EnvironmentSetup:get_player_gui_root()
		local _gameplay_frame = _player_gui_root.GameplayFrame
		local buttons = _gameplay_frame.TriggerButtons
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
		_game._object_pool:repool(self.ClassName, _effect_obj)
	end

	self:cons(_game)
	return self
end

return TriggerNoteEffect2D
