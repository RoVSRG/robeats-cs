local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local _SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local NoteResultPopupEffect2D = {}
NoteResultPopupEffect2D.HitColor = {
	[0] = Color3.fromRGB(255, 0, 0),
	[1] = Color3.fromRGB(190, 10, 240),
	[2] = Color3.fromRGB(56, 10, 240),
	[3] = Color3.fromRGB(7, 232, 74),
	[4] = Color3.fromRGB(252, 244, 5),
	[5] = Color3.fromRGB(255, 255, 255),
}
NoteResultPopupEffect2D.Type = "NoteResultPopupEffect2D"

-- Static variable to track the last popup effect across all instances
local last_popup_effect = nil

function NoteResultPopupEffect2D:new(_game, _result)
	local self = EffectSystem:EffectBase()
	self.ClassName = NoteResultPopupEffect2D.Type

	local rng = Random.new(tick())
	local startorg = UDim2.new(0.6, 0, 0.04, 0)
	local missorg = UDim2.new(1, 0, 0.05, 0)
	local origin = UDim2.new(1, 0, 0.05, 0)
	local _orgpos = UDim2.new(0.5, 0, 0.54, 0)
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
			_effect_obj = Instance.new("ImageLabel")

			if upscroll then
				_effect_obj.Position = UDim2.fromScale(0.5, 0.54)
				_effect_obj.Rotation = 180
			else
				_effect_obj.Position = UDim2.fromScale(0.5, 0.56)
			end

			_effect_obj.Size = UDim2.fromScale(2, 0.05)
			_effect_obj.ScaleType = Enum.ScaleType.Fit
			_effect_obj.AnchorPoint = Vector2.new(0.5, 0.5)
			_effect_obj.BackgroundTransparency = 1
			_effect_obj.ZIndex = 4
			_effect_obj.SizeConstraint = Enum.SizeConstraint.RelativeXY
		end

		_text_label = _effect_obj

		if _result == NoteResult.Miss then
			_text_label.Image = "rbxassetid://1401704555"
		elseif _result == NoteResult.Bad then
			_text_label.Image = "rbxassetid://1401704690"
		elseif _result == NoteResult.Good then
			_text_label.Image = "rbxassetid://1401704848"
		elseif _result == NoteResult.Great then
			_text_label.Image = "rbxassetid://1401705001"
		elseif _result == NoteResult.Perfect then
			_text_label.Image = "rbxassetid://1401705141"
		elseif _result == NoteResult.Marvelous then
			_text_label.Image = "rbxassetid://1401705244"
		else
			_text_label.Image = ""
		end

		_text_label.ImageColor3 = NoteResultPopupEffect2D.HitColor[_result]

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
		self:update_visual() -- Initialize visual state
	end

	function self:get_anim_t()
		return _anim_t
	end
	function self:set_anim_t(val)
		_anim_t = val
	end

	function self:update_visual()
		-- Create bounce effect using a sine wave with decay - much faster bounce
		local bounce_frequency = 30 -- Increase frequency for faster bounces
		local bounce_amplitude = 0.4 -- Stronger bounce effect
		local decay = math.exp(-_anim_t * 6) -- Faster decay
		local bounce_offset = bounce_amplitude * math.sin(_anim_t * math.pi * bounce_frequency) * decay

		-- Fade out effect - starts fading after 30% of animation
		local fade_start = 0.3
		local fade_progress = math.max(0, (_anim_t - fade_start) / (1 - fade_start))
		local alpha = 1 - (fade_progress * fade_progress) -- Quadratic fade for smoother effect

		-- Calculate base target size - popup grows to full size
		local base_size = _result == NoteResult.Miss and missorg or startorg
		local target_size = origin

		-- Main size progression from start to target
		local size_t = math.min(_anim_t * 3, 1) -- Faster size transition (3x speed)
		local eased_t = 1 - math.pow(1 - size_t, 3) -- Ease out cubic for smooth arrival

		-- Apply bounce effect on top of base size
		local final_scale = eased_t + bounce_offset

		_effect_obj.Size = UDim2.new(
			CurveUtil:Lerp(base_size.X.Scale, target_size.X.Scale * final_scale, size_t),
			base_size.X.Offset,
			CurveUtil:Lerp(base_size.Y.Scale, target_size.Y.Scale * final_scale, size_t),
			base_size.Y.Offset
		)

		-- Apply fade
		_effect_obj.ImageTransparency = 1 - alpha
	end

	--[[Override--]]
	function self:add_to_parent(parent)
		local gameplayframe = EnvironmentSetup:get_player_gui_root().GameplayFrame
		local popupsfolder = gameplayframe.ResultPopups

		-- Clear any previous popup effect
		if last_popup_effect then
			local success = pcall(function()
				last_popup_effect.Parent = nil
			end)
			if not success then
				-- Previous effect was already destroyed, that's fine
			end
		end

		-- Set this effect as the current one and add to parent
		last_popup_effect = _effect_obj
		if _effect_obj ~= nil then
			local success = pcall(function() -- Prevent instance nil or parent locked whatever
				_effect_obj.Parent = popupsfolder
			end)

			if not success then
				DebugOut:warnf("Attempt to assign 'Destroyed' instance")
			end
		end
	end

	--[[Override--]]
	function self:update(dt_scale)
		_anim_t = _anim_t + CurveUtil:SecondsToTick(0.35) * dt_scale -- Faster animation - 0.35 seconds total
		self:update_visual()
	end
	--[[Override--]]
	function self:should_remove()
		return _anim_t >= 1
	end
	--[[Override--]]
	function self:do_remove()
		-- Clear the static reference if this is the current popup
		if last_popup_effect == _effect_obj then
			last_popup_effect = nil
		end
		_game._object_pool:repool(self.ClassName, _effect_obj)
	end

	self:cons()
	return self
end

return NoteResultPopupEffect2D
