local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local Skins = require(game.ReplicatedStorage.Skins)

local EnvironmentSetup = {}
EnvironmentSetup.Mode = {
	Menu = 0;
	Game = 1;
}

EnvironmentSetup.LaneMode = {
	['2D'] = 0;
	['3D'] = 1;
}

local _game_environment
local _element_protos_folder
local _local_elements_folder
local _player_gui

function EnvironmentSetup:initial_setup()
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	_game_environment = workspace.GameEnvironment
	_game_environment.Parent = nil
	
	_element_protos_folder = workspace.ElementProtos
	_element_protos_folder.Parent = game.ReplicatedStorage

	_local_elements_folder = Instance.new("Folder")
	_local_elements_folder.Name = "LocalElements"
	_local_elements_folder.Parent = workspace

	_player_gui = Instance.new("ScreenGui")
	_player_gui.Parent = game.Players.LocalPlayer.PlayerGui
	_player_gui.IgnoreGuiInset = false
	_player_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
end

function EnvironmentSetup:set_gui_inset(val)
	_player_gui.IgnoreGuiInset = val
end

function EnvironmentSetup:setup_2d_environment(skin, config)
	local _gameplay_frame = skin:FindFirstChild("GameplayFrame"):Clone()
	_gameplay_frame.Position = UDim2.fromScale(0.5, 1)
	_gameplay_frame.Size = UDim2.fromScale(config.playfieldWidth / 100, 1.1)
	_gameplay_frame.ZIndex = 0;

	local hit_pos = config.playfieldHitPos
	local upscroll = config.upscroll

	local tracks = _gameplay_frame.Tracks
	local _trigger_buttons = _gameplay_frame.TriggerButtons
	if #_trigger_buttons:GetChildren() == 0 then
		for i,proto in pairs(skin.GameplayFrame.TriggerButtons:Clone():GetChildren()) do
			proto.Parent = _trigger_buttons
		end
	end

	_trigger_buttons.Size = UDim2.new(1, 0, hit_pos/100, 0)
	tracks.Size = UDim2.new(1, 0, 1-hit_pos/100, 0)

	for _, trigger_button in _gameplay_frame.TriggerButtons:GetChildren() do
		if trigger_button:FindFirstChild("ReceptorImage") then
			trigger_button.ReceptorImage.ImageTransparency = config.ReceptorTransparency
		end
	end

	if upscroll then
		_gameplay_frame.Rotation = 180
		_gameplay_frame.Position = _gameplay_frame.Position + UDim2.new(0, 0, 0.05, 0)
	end

	_gameplay_frame.Parent = self:get_player_gui_root()
end

function EnvironmentSetup:teardown_2d_environment()
	local _gameplay_frame = EnvironmentSetup:get_player_gui_root():FindFirstChild("GameplayFrame")
	if _gameplay_frame == nil then
		DebugOut:warnf("[EnvironmentSetup] >> This shouldn't happen if 2D setting enabled >>")
		return
	end

	_gameplay_frame.ResultPopups:ClearAllChildren()
	local _trigger_buttons = _gameplay_frame.TriggerButtons
	for i=1,4 do
		for _, proto in pairs(_trigger_buttons["Button"..i]:GetChildren()) do
			if proto.Name == "EffectProto" then
				proto:Destroy()
			end
		end
	end

	_gameplay_frame:Destroy()
end

function EnvironmentSetup:set_mode(mode)
	AssertType:is_enum_member(mode, EnvironmentSetup.Mode)
	if mode == EnvironmentSetup.Mode.Game then
		_game_environment.Parent = game.Workspace
	else
		_game_environment.Parent = nil
	end
end

function EnvironmentSetup:get_game_environment_center_position()
	return _game_environment.GameEnvironmentCenter.Position
end

function EnvironmentSetup:get_game_environment()
	return _game_environment
end

function EnvironmentSetup:get_element_protos_folder()
	return _element_protos_folder
end

function EnvironmentSetup:get_local_elements_folder()
	return _local_elements_folder
end

function EnvironmentSetup:get_player_gui_root()
	return _player_gui
end

function EnvironmentSetup:get_robeats_game_stage()
	return EnvironmentSetup:get_element_protos_folder().NoteTrackSystemProto.TrackBG.Union
end

return EnvironmentSetup
