local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerButton2D = {}

function TriggerButton2D:new(_game, _parent_note_track, _position)
	local self = {}

	local _triggerbutton_obj
	local _tar_glow_transparency = 1

	function self:cons()
		local _player_ui = EnvironmentSetup:get_player_gui_root()
		local _gameplay_frame = _player_ui:FindFirstChild("GameplayFrame")
		if not _gameplay_frame then
			error("GameplayFrame not found in player GUI. Make sure 2D environment is set up first.")
		end

		local _buttons = _gameplay_frame:FindFirstChild("TriggerButtons")
		if not _buttons then
			error("TriggerButtons not found in GameplayFrame")
		end

		_triggerbutton_obj = _buttons:FindFirstChild("Button" .. _position)
		if not _triggerbutton_obj then
			error("Button" .. _position .. " not found in TriggerButtons")
		end

		_triggerbutton_obj.ZIndex = 2
	end

	function self:press()
		_tar_glow_transparency = 0
	end

	function self:release()
		_tar_glow_transparency = 1
	end

	function self:update(dt_scale)
		_triggerbutton_obj.BackgroundTransparency = CurveUtil:Expt(
			_triggerbutton_obj.BackgroundTransparency,
			_tar_glow_transparency,
			CurveUtil:NormalizedDefaultExptValueInSeconds(0.2),
			dt_scale
		)

		_triggerbutton_obj.Fader.ImageTransparency = CurveUtil:Expt(
			_triggerbutton_obj.Fader.ImageTransparency,
			_tar_glow_transparency,
			CurveUtil:NormalizedDefaultExptValueInSeconds(0.2),
			dt_scale
		)
	end

	function self:teardown() end

	self:cons()
	return self
end

return TriggerButton2D
