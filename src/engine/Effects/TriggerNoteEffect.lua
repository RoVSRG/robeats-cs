local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerNoteEffect = {}
TriggerNoteEffect.Type = "TriggerNoteEffect"

local STARTING_ALPHA = 0.1
local ENDING_ALPHA = 0

function TriggerNoteEffect:new(_game, _position, _result)
	local self = EffectSystem:EffectBase()
	self.ClassName = TriggerNoteEffect.Type

	local proto = EnvironmentSetup:get_element_protos_folder().TriggerHitEffectProto
	proto.Parent = nil

	local _effect_obj = nil
	local _anim_t = 0

	local function update_visual()
		_effect_obj.Body.Transparency = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0, SPUtil:tra(STARTING_ALPHA)),
			Vector2.new(1, SPUtil:tra(ENDING_ALPHA)),
			_anim_t
		)

		local size_val = CurveUtil:YForPointOf2PtLine(Vector2.new(0, 2.25), Vector2.new(1, 4.25), _anim_t)

		if _result == NoteResult.Good then
			size_val = size_val * 0.25
		elseif _result == NoteResult.Great then
			size_val = size_val * 0.5
		else
			size_val = size_val * 1
		end

		_position = _position + Vector3.new(0, 0.01, 0)
		_effect_obj:SetPrimaryPartCFrame(CFrame.new(_position) * SPUtil:part_cframe_rotation(_effect_obj.PrimaryPart))
		_effect_obj.Body.Size = Vector3.new(70, size_val, size_val)
	end

	function self:cons()
		_effect_obj = _game._object_pool:depool(self.ClassName)
		if _effect_obj == nil then
			_effect_obj = proto:Clone()
		end

		if _result == NoteResult.Marvelous then
			_effect_obj.PrimaryPart.BrickColor = BrickColor.new(Color3.fromRGB(255, 255, 255))
		elseif _result == NoteResult.Perfect then
			_effect_obj.PrimaryPart.BrickColor = BrickColor.new(Color3.fromRGB(233, 211, 15))
		elseif _result == NoteResult.Great then
			_effect_obj.PrimaryPart.BrickColor = BrickColor.new(Color3.fromRGB(17, 204, 0))
		elseif _result == NoteResult.Good then
			_effect_obj.PrimaryPart.BrickColor = BrickColor.new(Color3.fromRGB(0, 20, 204))
		elseif _result == NoteResult.Bad then
			_effect_obj.PrimaryPart.BrickColor = BrickColor.new(Color3.fromRGB(112, 0, 204))
		end

		_position = Vector3.new(_position.X, _game:get_game_environment_center_position().Y, _position.Z)
		_effect_obj:SetPrimaryPartCFrame(CFrame.new(_position) * SPUtil:part_cframe_rotation(_effect_obj.PrimaryPart))

		_anim_t = 0
		update_visual()
	end

	--[[Override--]]
	function self:add_to_parent(parent)
		_effect_obj.Parent = parent
	end

	--[[Override--]]
	function self:update(dt_scale)
		_anim_t = _anim_t + CurveUtil:SecondsToTick(0.25) * dt_scale
		update_visual()
	end
	--[[Override--]]
	function self:should_remove()
		return _anim_t >= 1
	end
	--[[Override--]]
	function self:do_remove()
		_game._object_pool:repool(self.ClassName, _effect_obj)
	end

	self:cons(_game)
	return self
end

return TriggerNoteEffect
