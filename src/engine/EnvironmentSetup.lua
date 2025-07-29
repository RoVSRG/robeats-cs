local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local _SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local _Skins = require(game.ReplicatedStorage.Skins)
local Config = require(game.ReplicatedStorage.RobeatsGameCore.Types.Config)

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
local _dynamic_floor

function EnvironmentSetup:initial_setup()
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	local environment = workspace:WaitForChild("Environment")

	if not environment then
		error("Environment folder not found in workspace")
	end

	_game_environment = environment:WaitForChild("GameEnvironment")
	_game_environment.Parent = nil

	_element_protos_folder = environment:WaitForChild("ElementProtos")
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

function EnvironmentSetup:setup_2d_environment(skin: Instance, config: Config.GameConfig)
	local gameplayFrame = skin:FindFirstChild("GameplayFrame")
	if not gameplayFrame then
		error("GameplayFrame not found in skin")
	end
	
	local _gameplay_frame = gameplayFrame:Clone() :: GuiObject
	_gameplay_frame.Position = UDim2.fromScale(0.5, 1)
	_gameplay_frame.Size = UDim2.new(0, 500, 1.2, 0)
	_gameplay_frame.ZIndex = 0;

	local hit_pos = 10
	local upscroll = config.upscroll or false

	local tracks = (_gameplay_frame :: any).Tracks
	local _trigger_buttons = (_gameplay_frame :: any).TriggerButtons
	if #_trigger_buttons:GetChildren() == 0 then
		local skinGameplayFrame = (skin :: any).GameplayFrame
		for i,proto in pairs(skinGameplayFrame.TriggerButtons:Clone():GetChildren()) do
			proto.Parent = _trigger_buttons
		end
	end

	_trigger_buttons.Size = UDim2.new(1, 0, hit_pos/100, 0)
	tracks.Size = UDim2.new(1, 0, 1-hit_pos/100, 0)

	for _, trigger_button in (_gameplay_frame :: any).TriggerButtons:GetChildren() do
		if trigger_button:FindFirstChild("ReceptorImage") then
			trigger_button.ReceptorImage.ImageTransparency = config.ReceptorTransparency or 0
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

	local gameplayFrame = (_gameplay_frame :: any)
	gameplayFrame.ResultPopups:ClearAllChildren()
	local _trigger_buttons = gameplayFrame.TriggerButtons
	for i=1,4 do
		for _, proto in pairs(_trigger_buttons["Button"..i]:GetChildren()) do
			if proto.Name == "EffectProto" then
				proto:Destroy()
			end
		end
	end

	_gameplay_frame:Destroy()
end

function EnvironmentSetup:setup_3d_environment()
	-- Create dynamic floor for 3D mode
	if _game_environment and _game_environment.Parent == game.Workspace then
		self:create_dynamic_floor(self:get_game_environment_center_position(), nil, nil)
	end
end

function EnvironmentSetup:teardown_3d_environment()
	-- Remove dynamic floor when tearing down 3D environment
	self:remove_dynamic_floor()
end

function EnvironmentSetup:set_mode(mode)
	AssertType:is_enum_member(mode, EnvironmentSetup.Mode)
	if mode == EnvironmentSetup.Mode.Game then
		_game_environment.Parent = game.Workspace
		-- Create dynamic floor when entering game mode
		-- Note: Tracksystem info might not be available yet, so we'll use defaults
		self:create_dynamic_floor(self:get_game_environment_center_position(), nil, nil)
	else
		_game_environment.Parent = nil
		-- Remove dynamic floor when leaving game mode
		self:remove_dynamic_floor()
	end
end

function EnvironmentSetup:update_dynamic_floor_with_tracksystem(tracksystem, game_slot)
	-- Update the floor with actual track information when tracksystem is available
	if _game_environment and _game_environment.Parent == game.Workspace then
		self:create_dynamic_floor(self:get_game_environment_center_position(), tracksystem, game_slot)
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

function EnvironmentSetup:create_dynamic_floor(center_position: Vector3, tracksystem, game_slot)
	if _dynamic_floor then
		_dynamic_floor:Destroy()
		_dynamic_floor = nil
	end

	local track_angle = math.rad(6)
	local floor_depth = 50
	local floor_thickness = 0.5
	local floor_y_offset = -2

	-- Default dimensions
	local near_width = 5
	local far_width = near_width + 2 * floor_depth * math.tan(track_angle)

	local half_near = near_width * 0.5
	local half_depth = floor_depth * 0.5
	local wedge_width = (far_width - near_width) * 0.5

	-- Calculate rotation based on game slot
	local floor_rotation = 0
	if game_slot then
		if game_slot == 1 then -- SLOT_1: Looking towards (+Z, +X) - needs 45° rotation
			floor_rotation = math.rad(45)
		elseif game_slot == 2 then -- SLOT_2: Looking towards (-Z, +X) - needs 135° rotation
			floor_rotation = math.rad(135)
		elseif game_slot == 3 then -- SLOT_3: Looking towards (-Z, -X) - needs 225° rotation
			floor_rotation = math.rad(225)
		else -- SLOT_4: Looking towards (+Z, -X) - needs 315° rotation  
			floor_rotation = math.rad(315 + 90)
		end
	end

	local floor_model = Instance.new("Model")
	floor_model.Name = "DynamicFloor"
	floor_model.Parent = _local_elements_folder

	-- Create invisible primary part at the front edge (closest to player) for rotation pivot
	local rotation_pivot = Instance.new("Part")
	rotation_pivot.Name = "RotationPivot"
	rotation_pivot.Size = Vector3.new(0.1, 0.1, 0.1) -- Very small
	rotation_pivot.CFrame = CFrame.new(
		center_position.X,
		center_position.Y + floor_y_offset,
		center_position.Z -- At the front edge, not offset by half_depth
	)
	rotation_pivot.Transparency = 1 -- Invisible
	rotation_pivot.CanCollide = false
	rotation_pivot.Anchored = true
	rotation_pivot.Parent = floor_model

	-- Set invisible pivot as primary part
	floor_model.PrimaryPart = rotation_pivot

	local SHIFT_BACK = 4

	local center_part = Instance.new("Part")
	center_part.Transparency = 1
	center_part.Name = "FloorCenter"
	center_part.Size = Vector3.new(near_width, floor_thickness, floor_depth)
	center_part.CFrame = CFrame.new(
		center_position.X,
		center_position.Y + floor_y_offset,
		center_position.Z + half_depth - SHIFT_BACK
	)
	center_part.Material = Enum.Material.Neon
	center_part.BrickColor = BrickColor.new("Black")
	center_part.Anchored = true
	center_part.CanCollide = true
	center_part.Parent = floor_model

	-- Wedges slope along +X by default, so we swap X/Z and rotate on Y
	local wedge_size = Vector3.new(floor_thickness, floor_depth, wedge_width)

	local left_wedge = Instance.new("WedgePart")
	left_wedge.Transparency = 1
	left_wedge.Name = "FloorLeft"
	left_wedge.Size = wedge_size
	left_wedge.CFrame = CFrame.new(
		center_position.X - (half_near + wedge_width * 0.5),
		center_position.Y + floor_y_offset,
		center_position.Z + half_depth - SHIFT_BACK
	) * CFrame.Angles(0, math.rad(90), math.rad(-90))
	left_wedge.Material = center_part.Material
	left_wedge.BrickColor = center_part.BrickColor
	left_wedge.Transparency = center_part.Transparency
	left_wedge.Anchored = true
	left_wedge.CanCollide = true
	left_wedge.Parent = floor_model
	
	local right_wedge = Instance.new("WedgePart")
	right_wedge.Transparency = 1
	right_wedge.Name = "FloorRight"
	right_wedge.Size = wedge_size
	right_wedge.CFrame = CFrame.new(
		center_position.X + (half_near + wedge_width * 0.5),
		center_position.Y + floor_y_offset,
		center_position.Z + half_depth - SHIFT_BACK
	) * CFrame.Angles(0, math.rad(-90), math.rad(90))
	right_wedge.Material = center_part.Material
	right_wedge.BrickColor = center_part.BrickColor
	right_wedge.Transparency = center_part.Transparency
	right_wedge.Anchored = true
	right_wedge.CanCollide = true
	right_wedge.Parent = floor_model

	-- Apply rotation to the entire model if game slot is specified
	if game_slot and floor_rotation ~= 0 then
		floor_model:SetPrimaryPartCFrame(
			floor_model.PrimaryPart.CFrame * CFrame.Angles(0, floor_rotation, 0)
		)
	end

	center_part.Transparency = 0
	left_wedge.Transparency = 0
	right_wedge.Transparency = 0

	_dynamic_floor = floor_model
	return _dynamic_floor
end

function EnvironmentSetup:remove_dynamic_floor()
	if _dynamic_floor then
		_dynamic_floor:Destroy()
		_dynamic_floor = nil
	end
end

function EnvironmentSetup:get_dynamic_floor()
	return _dynamic_floor
end

return EnvironmentSetup

