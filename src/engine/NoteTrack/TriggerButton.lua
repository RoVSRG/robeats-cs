local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local TriggerButton = {}

function TriggerButton:new(_game, _parent_note_track, _position)
	local self = {}

	local _triggerbutton_obj
	local _tar_glow_transparency = 1

	function self:cons()
		_triggerbutton_obj = EnvironmentSetup:get_element_protos_folder().TriggerButtonProto:Clone()
		_triggerbutton_obj.Parent = _parent_note_track:get_track_obj()
		_triggerbutton_obj:SetPrimaryPartCFrame(
			CFrame.new(
				Vector3.new(_position.X, _game:get_game_environment_center_position().Y + 1, _position.Z)
			) * SPUtil:part_cframe_rotation(_triggerbutton_obj.PrimaryPart)
		)
		_triggerbutton_obj.InteriorGlow.Transparency = _tar_glow_transparency
	end

	function self:press()
		_tar_glow_transparency = 0
	end

	function self:release()
		_tar_glow_transparency = 1
	end

	function self:update(dt_scale)
		_triggerbutton_obj.InteriorGlow.Transparency = CurveUtil:Expt(
			_triggerbutton_obj.InteriorGlow.Transparency,
			_tar_glow_transparency,
			CurveUtil:NormalizedDefaultExptValueInSeconds(0.45),
			dt_scale
		)
	end
	
	function self:teardown()
		_triggerbutton_obj:Destroy()
	end

	self:cons()
	return self
end

return TriggerButton

