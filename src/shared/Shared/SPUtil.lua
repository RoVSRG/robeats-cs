local UserInputService = game:GetService("UserInputService")

local RunService = game:GetService("RunService")

local FX = require(game.ReplicatedStorage.Modules.FX)

local function noop() end

local SPUtil = {}

function SPUtil:inverse_lerp(min, max, num)
	return ((num - min) / (max - min))
end

-- https://stackoverflow.com/questions/4353525/floating-point-linear-interpolation
function SPUtil:lerp(min, max, alpha)
    return (min * (1.0 - alpha)) + (max * alpha);
end

function SPUtil:rad_to_deg(rad)
	return rad * 180.0 / math.pi
end

function SPUtil:deg_to_rad(degrees)
	return degrees * math.pi / 180
end

function SPUtil:dir_ang_deg(x,y)
	return SPUtil:rad_to_deg(math.atan2(y,x))
end

function SPUtil:ang_deg_dir(deg)
	local rad = SPUtil:deg_to_rad(deg)
	return Vector2.new(
		math.cos(rad),
		math.sin(rad)
	)
end

function SPUtil:part_cframe_rotation(part)
	return CFrame.new(-part.CFrame.p) * (part.CFrame)
end

function SPUtil:table_clear(tab)
	for k, _ in pairs(tab) do tab[k]=nil end
end

function SPUtil:vec3_lerp(a,b,t)
	return a:Lerp(b,t)
end

function SPUtil:clamp(val,min,max)
	return math.min(max,math.max(min,val))
end

function SPUtil:tra(val)
	return 1 - val
end

function SPUtil:format_ms_time(ms_time)
	ms_time = math.floor(ms_time)
	return string.format(
		"%d:%d%d",
		ms_time/60000,
		(ms_time/10000)%6,
		(ms_time/1000)%10
	)
end

local __cached_camera = nil
local function get_camera()
	if __cached_camera == nil then __cached_camera = game.Workspace.Camera end
	return __cached_camera
end
function SPUtil:get_camera() return get_camera() end

function SPUtil:lookat_camera_cframe(position)
	local camera_cf = SPUtil:get_camera().CFrame
	local look_vector = camera_cf.LookVector.Unit
	local normal_dir = look_vector * -1
	return CFrame.new(position, position + normal_dir)
end

function SPUtil:try(call)
	return xpcall(function()
		call()
	end, function(err)
		return {
			Error = err;
			StackTrace = debug.traceback();
		}
	end)
end

function SPUtil:look_at(eye, target)
	local forwardVector = (target - eye).Unit
	local upVector = Vector3.new(0, 1, 0)
	local rightVector = forwardVector:Cross(upVector)
	local upVector2 = rightVector:Cross(forwardVector)
	return CFrame.fromMatrix(eye, rightVector, upVector2)
end

function SPUtil:is_mobile()
	return game:GetService("UserInputService").TouchEnabled
end

local _sputil_screengui = nil
local function verify_sputil_screengui()
	if _sputil_screengui ~= nil then return true end
	if game.Players.LocalPlayer == nil then
		return false
	end
	if game.Players.LocalPlayer:FindFirstChild("PlayerGui") == nil then
		return false
	end
	local TESTGUI_NAME = "SPUtil_test"
	if game.Players.LocalPlayer.PlayerGui:FindFirstChild(TESTGUI_NAME) == nil then
		_sputil_screengui = Instance.new("ScreenGui",game.Players.LocalPlayer.PlayerGui)
		_sputil_screengui.Name = TESTGUI_NAME
		_sputil_screengui.ResetOnSpawn = false
	end
	return true
end

function SPUtil:topbar_size() return 36 end

local __cached_screen_size = Vector2.new(0,0)
local __cached_absolute_size = Vector2.new()
function SPUtil:screen_size()
	if verify_sputil_screengui() == false then
		return __cached_screen_size
	end
	local abs_size = _sputil_screengui.AbsoluteSize
	if __cached_absolute_size ~= abs_size then
		__cached_absolute_size = abs_size
		__cached_screen_size = Vector2.new(abs_size.X + 0, abs_size.Y + SPUtil:topbar_size())
	end
	return __cached_screen_size
end

function SPUtil:time_to_str(time)
	return os.date("%H:%M %d/%m/%Y",time)
end

function SPUtil:bind_input_fire(object_, callback_)
	local cb = function(i,n)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			callback_(i,n)
		end
	end
	local suc, _ = pcall(function()
		object_.Activated:Connect(cb)
	end)
	if not suc then
		object_.InputBegan:Connect(cb)
	end
end

function SPUtil:shallow_equal(t1, t2, ignore_subtables)
	if typeof(t1) ~= "table" or typeof(t2) ~= "table" then
		return t1 == t2
	end

	if t1 == t2 then
		return true
	end

	for i, v in pairs(t1) do
		if not (typeof(v) == "table" and ignore_subtables) then
			if t2[i] ~= v then
				return false
			end
		end
	end

	for i, v in pairs(t2) do
		if not (typeof(v) == "table" and ignore_subtables) then
			if t1[i] ~= v then
				return false
			end
		end
	end

	return true
end

function SPUtil:copy_table(datatable)
	local tblRes={}
	if type(datatable)=="table" then
		for k,v in pairs(datatable) do tblRes[k]=SPUtil:copy_table(v) end
	else
		tblRes=datatable
	end
	return tblRes
end

function SPUtil:deparent_element(_element_to_deparent)
	_element_to_deparent.Parent = nil
	return _element_to_deparent
end

function SPUtil:make(type, properties, children)
	local rtv = Instance.new(type)

	if properties then
		for i,v in pairs(properties) do
			rtv[i] = v
		end
	end
	
	if children then
		for key,child in pairs(children) do
			child.Name = key
			child.Parent = rtv
		end		
	end

	return rtv
end

function SPUtil:get_user_thumbnail(u_id)
	if typeof(u_id) == "Instance" then
		return game.Players:GetUserThumbnailAsync(u_id.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end

	return game.Players:GetUserThumbnailAsync(u_id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

function SPUtil:find_distance(x1, y1, x2, y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function SPUtil:get_vec2_angle(vec1, vec2)
	local x = vec1.X - vec2.X
	local y = vec1.Y - vec2.Y

	return math.deg(math.atan2(y, x))
end

function SPUtil:bind_to_frame(_callback)
	return RunService.Heartbeat:Connect(_callback)
end

function SPUtil:bind_to_key(key_code, _callback)
	_callback = _callback or noop
	return UserInputService.InputBegan:Connect(function(inputob, wasGuiFocused)
		if inputob.KeyCode == key_code or key_code == Enum.KeyCode then
			if inputob.KeyCode ~= Enum.KeyCode.Unknown then
				_callback(inputob.KeyCode, wasGuiFocused)
			end
		end
	end)
end

function SPUtil:bind_to_key_release(key_code, _callback)
	_callback = _callback or noop
	return UserInputService.InputEnded:Connect(function(inputob, wasGuiFocused)
		if inputob.KeyCode == key_code or key_code == Enum.KeyCode then
			if inputob.KeyCode ~= Enum.KeyCode.Unknown then
				_callback(inputob.KeyCode, wasGuiFocused)
			end
		end
	end)
end

function SPUtil:bind_to_key_combo(key_combo, _callback)
	return SPUtil:bind_to_key(key_combo[1], function(key_code)
		local comboPressed = true

		for i, v in ipairs(key_combo) do
			if i ~= 1 then
				if not UserInputService:IsKeyDown(v) then
					comboPressed = false
					break
				end
			end
		end

		if comboPressed then
			_callback(key_code)
		end
	end)
end

function SPUtil:switch(val)
	local switchInstance = {}

	local _wasCalled = false

	function switchInstance:case(compar, _callback)
		if val == compar and not _wasCalled then
			_wasCalled = true
			_callback(compar)
		end
		return self
	end

	return switchInstance
end

function SPUtil:attach_sound(guiObject: any, sound: string)
	return guiObject.Activated:Connect(function()
		FX.PlaySound(sound)
	end)
end

return SPUtil
