local EffectSystem = require("@shared/RobeatsGameCore/Effects/EffectSystem")
local SPUtil = require("@shared/Shared/SPUtil")
local CurveUtil = require("@shared/Shared/CurveUtil")
local NoteResult = require("@shared/RobeatsGameCore/Enums/NoteResult")
local DebugOut = require("@shared/Shared/DebugOut")
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")

local NoteResultPopupEffect2D = {}
NoteResultPopupEffect2D.HitColor = {
	[0] = Color3.fromRGB(255, 0, 0);
	[1] = Color3.fromRGB(190, 10, 240);
	[2] = Color3.fromRGB(56, 10, 240);
	[3] = Color3.fromRGB(7, 232, 74);
	[4] = Color3.fromRGB(252, 244, 5);
	[5] = Color3.fromRGB(255, 255, 255);
}
NoteResultPopupEffect2D.Type = "NoteResultPopupEffect2D"

function NoteResultPopupEffect2D:new(_game, _result)
	local self = EffectSystem:EffectBase()
	self.ClassName = NoteResultPopupEffect2D.Type

	local rng = Random.new(tick())
	local startorg = UDim2.new(0,0,0.025,0)
	local missorg = UDim2.new(1,0,0.05,0)
	local origin = UDim2.new(1,0,0.05,0)
	local orgpos = UDim2.new(0.5,0,0.54,0)
	local _effect_obj
	local _anim_t = 0
	
	local _frame
	local _text_label

	local function pool_str()
		return string.format("%s_%d", self.ClassName, _result)
	end
	
	function self:cons()
		local upscroll = _game:is_upscroll()
		_anim_t = 0
	
		_effect_obj = _game._object_pool:depool(pool_str())
		if _effect_obj == nil then
			_effect_obj = Instance.new("TextLabel")
			if upscroll then
				_effect_obj.Position = UDim2.fromScale(0.5, 0.54)
				_effect_obj.Rotation = 180
			else
				_effect_obj.Position = UDim2.fromScale(0.5, 0.56)
			end

			_effect_obj.Size = UDim2.fromScale(2, 0.05)
			_effect_obj.TextSize = 14
			_effect_obj.TextScaled = true
			_effect_obj.Font = "Gotham"
			_effect_obj.AnchorPoint = Vector2.new(0.5, 0.5)
			_effect_obj.BackgroundTransparency = 1
			_effect_obj.ZIndex = 4
			_effect_obj.SizeConstraint = Enum.SizeConstraint.RelativeXY
			_effect_obj.TextXAlignment = Enum.TextXAlignment.Center
			_effect_obj.TextYAlignment = Enum.TextYAlignment.Center
		end
		_text_label = _effect_obj

		if _result == NoteResult.Miss then
			_text_label.Text = "Miss"
		elseif _result == NoteResult.Bad then
			_text_label.Text = "Bad"
		elseif _result == NoteResult.Good then
			_text_label.Text = "Good"
		elseif _result == NoteResult.Great then
			_text_label.Text = "Great"
		elseif _result == NoteResult.Perfect then
			_text_label.Text = "Perfect"
		elseif _result == NoteResult.Marvelous then
			_text_label.Text = "Marvelous"
		else
			_text_label.Text = ""
		end

		_text_label.TextColor3 = NoteResultPopupEffect2D.HitColor[_result]

		if _result == NoteResult.Miss then
			local _rotation_inc = 0
			if upscroll then
				_rotation_inc = 180
			end
			
			_effect_obj.Size = missorg
			_effect_obj.Rotation = (rng:NextInteger(-2000, 2000) / 200) + _rotation_inc
		else
			_effect_obj.Size = startorg
		end
		
		_anim_t = 0
	end
	
	function self:get_anim_t() return _anim_t end
	function self:set_anim_t(val) _anim_t = val end

	function self:update_visual() end

	--[[Override--]] function self:add_to_parent(parent)
		local gameplayframe = EnvironmentSetup:get_player_gui_root().GameplayFrame
		local popupsfolder = gameplayframe.ResultPopups
		if prev then 
			prev.Parent = nil
		end
		
		prev = _effect_obj
		if prev ~= nil then
			local success = pcall(function() -- Prevent instance nil or parent locked whatever
				prev.Parent = popupsfolder
			end)
			
			if not success then
				DebugOut:warnf("Attempt to assign 'Destroyed' instance")
			end
		end
		
		_effect_obj:TweenSize(origin, "Out", "Quint", .2, true)
	end

	--[[Override--]] function self:update(dt_scale)
	_anim_t = _anim_t + CurveUtil:SecondsToTick(0.2) * dt_scale
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

return NoteResultPopupEffect2D