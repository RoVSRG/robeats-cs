local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local NoteResultPopupEffect = {}
-- NoteResultPopupEffect.HitColor = {
-- 	[0] = Color3.fromRGB(255, 0, 0);
-- 	[1] = Color3.fromRGB(190, 10, 240);
-- 	[2] = Color3.fromRGB(56, 10, 240);
-- 	[3] = Color3.fromRGB(7, 232, 74);
-- 	[4] = Color3.fromRGB(252, 244, 5);
-- 	[5] = Color3.fromRGB(255, 255, 255);
-- }
NoteResultPopupEffect.Type = "NoteResultPopupEffect"

local INITIAL_FRAME_Y = 90
local FINAL_FRAME_Y = 190

function NoteResultPopupEffect:new(_game, _position, _result)
	local self = EffectSystem:EffectBase()
	self.ClassName = NoteResultPopupEffect.Type

	local _effect_obj
	local _anim_t = 0

	local _frame
	local image

	function self:cons()
		_anim_t = 0

		_effect_obj = _game._object_pool:depool(self.ClassName)
		if _effect_obj == nil then
			_effect_obj = EnvironmentSetup:get_element_protos_folder().PopupScoreEffectProto:Clone()
		end

		_frame = _effect_obj.Panel.SurfaceGui.Judgement
		image = _frame.JudgementImage

		image.ScaleType = Enum.ScaleType.Crop

		if _result == NoteResult.Miss then
			image.Image = "rbxassetid://1401704555"
		elseif _result == NoteResult.Bad then
			image.Image = "rbxassetid://1401704690"
		elseif _result == NoteResult.Good then
			image.Image = "rbxassetid://1401704848"
		elseif _result == NoteResult.Great then
			image.Image = "rbxassetid://1401705001"
		elseif _result == NoteResult.Perfect then
			image.Image = "rbxassetid://1401705141"
		elseif _result == NoteResult.Marvelous then
			image.Image = "rbxassetid://1401705244"
		else
			image.Image = ""
		end

		_effect_obj:SetPrimaryPartCFrame(SPUtil:lookat_camera_cframe(_position))

		_anim_t = 0
	end

	function self:get_anim_t()
		return _anim_t
	end
	function self:set_anim_t(val)
		_anim_t = val
	end

	local _alpha_min = Vector3.new(0, 0.65)
	local _alpha_max = Vector3.new(1, 0)
	function self:update_visual()
		_frame.Position = UDim2.new(0, 0, 0, CurveUtil:Lerp(INITIAL_FRAME_Y, FINAL_FRAME_Y, _anim_t))

		local alpha = CurveUtil:YForPointOf2PtLine(_alpha_min, _alpha_max, _anim_t)
		local transparency = SPUtil:tra(alpha)
		image.ImageTransparency = transparency
	end

	--[[Override--]]
	function self:add_to_parent(parent)
		_effect_obj.Parent = parent
	end

	--[[Override--]]
	function self:update(dt_scale)
		--This animation completes in 0.55 seconds (_anim_t goes from 0 to 1)
		_anim_t = _anim_t + CurveUtil:SecondsToTick(0.55) * dt_scale
		self:update_visual()
	end
	--[[Override--]]
	function self:should_remove()
		return _anim_t >= 1
	end
	--[[Override--]]
	function self:do_remove()
		_game._object_pool:repool(self.ClassName, _effect_obj)
	end

	self:cons()
	return self
end

return NoteResultPopupEffect
