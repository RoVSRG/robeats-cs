local SPUtil = require("@shared/Shared/SPUtil")
local CurveUtil = require("@shared/Shared/CurveUtil")
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")

local TriggerButton2D = {}

function TriggerButton2D:new(_game, _parent_note_track, _position)
	local self = {}

	local _triggerbutton_obj
	local _tar_glow_transparency = 1

	function self:cons()
		local _player_ui = EnvironmentSetup:get_player_gui_root()
		local _buttons = _player_ui.GameplayFrame.TriggerButtons
		_triggerbutton_obj = _buttons['Button'.._position]
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
