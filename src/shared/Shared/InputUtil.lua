local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPVector = require(game.ReplicatedStorage.Shared.SPVector)

local InputUtil = {}

InputUtil.KEY_TRACK1 = 0
InputUtil.KEY_TRACK2 = 1
InputUtil.KEY_TRACK3 = 2
InputUtil.KEY_TRACK4 = 3

InputUtil.KEY_SPEEDUP = 80
InputUtil.KEY_SPEEDDOWN = 81

InputUtil.KEY_DOWN = 11
InputUtil.KEY_LEFT = 12
InputUtil.KEY_RIGHT = 13
InputUtil.KEY_A = 14
InputUtil.KEY_B = 15

InputUtil.KEY_MOD1 = 21

InputUtil.KEY_MENU_OPEN = 31
InputUtil.KEY_MENU_ENTER = 32
InputUtil.KEY_MENU_BACK = 33

InputUtil.KEY_MENU_MATCHMAKING_CHAT_FOCUS = 34
InputUtil.KEY_CHAT_WINDOW_FOCUS = 35
InputUtil.KEY_MENU_SPUITEXTINPUT_ESC = 36

InputUtil.KEY_CLICK = 41

InputUtil.KEY_SCROLL_UP = 51
InputUtil.KEY_SCROLL_DOWN = 52

InputUtil.KEY_DEBUG_1 = 100
InputUtil.KEY_DEBUG_2 = 101
InputUtil.KEY_DEBUG_3 = 102
InputUtil.KEY_DEBUG_4 = 103

InputUtil.KEYCODE_TOUCH_TRACK1 = 10001
InputUtil.KEYCODE_TOUCH_TRACK2 = 10002
InputUtil.KEYCODE_TOUCH_TRACK3 = 10003
InputUtil.KEYCODE_TOUCH_TRACK4 = 10004

function InputUtil:new()
	local self = {}

	local userinput_service = game:GetService("UserInputService")
	local _just_pressed_keys = SPDict:new()
	local _down_keys = SPDict:new()
	local _just_released_keys = SPDict:new()

	local _textbox_focused = false
	local _do_textbox_unfocus = false

	self.InputBegan = Instance.new("BindableEvent")
	self.InputEnded = Instance.new("BindableEvent")

	local keybinds = {}
	local _is_key_inverted = false;

	function self:cons()
		userinput_service.TextBoxFocused:connect(function(textbox)
			_textbox_focused = true
		end)
		userinput_service.TextBoxFocusReleased:connect(function(textbox)
			_do_textbox_unfocus = true
		end)

		userinput_service.InputBegan:connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
				self:input_began(input.KeyCode)

			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:input_began(InputUtil.KEY_CLICK)

			elseif input.UserInputType == Enum.UserInputType.Touch then
				self:input_began(InputUtil.KEY_CLICK)

				self:touch_began(input.Position.X, input.Position.Y)
			end
		end)

		userinput_service.InputChanged:connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.Touch then
				self:touch_changed(input.Position.X, input.Position.Y)
			end
		end)

		userinput_service.InputEnded:connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1 then
				self:input_ended(input.KeyCode)

			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:input_ended(InputUtil.KEY_CLICK)

			elseif input.UserInputType == Enum.UserInputType.Touch then
				self:input_ended(InputUtil.KEY_CLICK)

				self:touch_ended(input.Position.X, input.Position.Y)
			end
		end)
		game.Players.LocalPlayer:GetMouse().WheelForward:connect(function()
			self:input_began(InputUtil.KEY_SCROLL_UP)
		end)
		game.Players.LocalPlayer:GetMouse().WheelBackward:connect(function()
			self:input_began(InputUtil.KEY_SCROLL_DOWN)
		end)
	end

	function self:set_keybinds(_keybinds)
		keybinds = _keybinds
	end

	function self:invert_keys(val)
		_is_key_inverted = val
	end
	
	local _track1_end = 0.25
	local _track2_end = 0.5
	local _track3_end = 0.75
	function self:set_touch_track_ends(track1_end, track2_end, track3_end)
		_track1_end = track1_end
		_track2_end = track2_end
		_track3_end = track3_end
	end

	function self:get_touch_track_ends() return _track1_end, _track2_end, _track3_end end

	local function get_touch_keycode(x,y)
		local screen_nx = x / SPUtil:screen_size().X
		if screen_nx <= _track1_end then
			return InputUtil.KEYCODE_TOUCH_TRACK1
		elseif screen_nx <= _track2_end then
			return InputUtil.KEYCODE_TOUCH_TRACK2
		elseif screen_nx <= _track3_end then
			return InputUtil.KEYCODE_TOUCH_TRACK3
		else
			return InputUtil.KEYCODE_TOUCH_TRACK4
		end
	end

	local _active_touches = SPList:new()
	local function get_nearest_touch(touch_spvec)
		if _active_touches:count() == 0 then return nil end
		local i_min = 1
		local touch_min = _active_touches:get(1)
		local val_min = touch_spvec:distance_to(touch_min)
		for i=2,_active_touches:count() do
			local itr = _active_touches:get(i)
			local itr_dist = touch_spvec:distance_to(itr)
			if itr_dist < val_min then
				i_min = i
				touch_min = itr
				val_min = itr_dist
			end
		end
		return touch_min, i_min
	end

	function self:touch_began(x,y)
		local neu_touch_keycode = get_touch_keycode(x,y)
		_active_touches:push_back(SPVector:new(x,y))
		self:input_began(neu_touch_keycode)
	end

	function self:touch_changed(x,y)
		local touch_moved_spvec = SPVector:new(x,y)
		local nearest_touch = get_nearest_touch(touch_moved_spvec)
		if nearest_touch == nil then return end

		local nearest_keycode = get_touch_keycode(nearest_touch._x, nearest_touch._y)
		local touch_moved_keycode = get_touch_keycode(touch_moved_spvec._x, touch_moved_spvec._y)
		if nearest_keycode ~= touch_moved_keycode then
			self:input_ended(nearest_keycode)
			self:input_began(touch_moved_keycode)
		end
		nearest_touch:set(x,y)
	end

	function self:touch_ended(x,y)
		local touch_ended_spvec = SPVector:new(x,y)
		local nearest_touch, i_nearest_touch = get_nearest_touch(touch_ended_spvec)
		if nearest_touch == nil then return end

		_active_touches:remove_at(i_nearest_touch)

		local nearest_keycode = get_touch_keycode(nearest_touch._x, nearest_touch._y)
		self:input_ended(nearest_keycode)
	end

	function self:input_began(keycode)
		_down_keys:add(keycode, true)
		_just_pressed_keys:add(keycode, true)

		self.InputBegan:Fire(keycode)
	end

	function self:input_ended(keycode)
		_down_keys:remove(keycode)
		_just_released_keys:add(keycode, true)

		self.InputEnded:Fire(keycode)
	end

	local _last_cursor = SPVector:new(0,0)
	local __get_cursor = SPVector:new(0,0)
	function self:get_cursor()
		local cursor = game.Players.LocalPlayer:GetMouse()
		__get_cursor:set(cursor.X,cursor.Y)
		return __get_cursor
	end
	local __get_cursor_delta = SPVector:new()
	function self:get_cursor_delta()
		local cursor = game.Players.LocalPlayer:GetMouse()
		__get_cursor_delta:set(
			cursor.X - _last_cursor._x,
			cursor.Y - _last_cursor._y
		)
		return __get_cursor_delta
	end

	local _has_frame_focused_element = false
	function self:set_has_frame_focused_element(val)
		_has_frame_focused_element = val
	end
	function self:get_has_frame_focused_element()
		return _has_frame_focused_element
	end

	function self:post_update()
		local cursor = game.Players.LocalPlayer:GetMouse()
		-- if (SPUtil:is_mobile() == false) then
		-- 	if self:control_pressed(InputUtil.KEY_TRACK1) or self:control_pressed(InputUtil.KEY_TRACK2) or self:control_pressed(InputUtil.KEY_TRACK3) or self:control_pressed(InputUtil.KEY_TRACK4) then
		-- 		self:set_mouse_visible(false)
		-- 	elseif cursor.X ~= _last_cursor._x or cursor.Y ~= _last_cursor._y then
		-- 		self:set_mouse_visible(true)
		-- 	end
		-- end
		_last_cursor:set(cursor.X,cursor.Y)

		_just_pressed_keys:clear()
		_just_released_keys:clear()

		if _down_keys:contains(InputUtil.KEY_SCROLL_UP) then
			self:input_ended(InputUtil.KEY_SCROLL_UP)
		end
		if _down_keys:contains(InputUtil.KEY_SCROLL_DOWN) then
			self:input_ended(InputUtil.KEY_SCROLL_DOWN)
		end
		if _do_textbox_unfocus == true then
			_do_textbox_unfocus = false
			_textbox_focused = false
		end
		self:set_has_frame_focused_element(false)
	end

	local function is_control_active(control,active_dict)

		if control == InputUtil.KEY_CLICK then
			return active_dict:contains(InputUtil.KEY_CLICK)
		end

		if _textbox_focused == true then
			return false
		end

		-- because how the upscroll work in the game, we need flip the control
		if control == InputUtil.KEY_TRACK1 then
			return if _is_key_inverted then 
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK4) or
				active_dict:contains(keybinds[4]) 
			else
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK1) or
				active_dict:contains(keybinds[1])

		elseif control == InputUtil.KEY_TRACK2 then
			return if _is_key_inverted then 
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK3) or
				active_dict:contains(keybinds[3]) 
			else
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK2) or
				active_dict:contains(keybinds[2])

		elseif control == InputUtil.KEY_TRACK3 then
			return if _is_key_inverted then 
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK2) or
				active_dict:contains(keybinds[2]) 
			else
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK3) or
				active_dict:contains(keybinds[3])

		elseif control == InputUtil.KEY_TRACK4 then
			return if _is_key_inverted then 
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK1) or
				active_dict:contains(keybinds[1]) 
			else
				active_dict:contains(InputUtil.KEYCODE_TOUCH_TRACK4) or
				active_dict:contains(keybinds[4])

		-- elseif control == InputUtil.KEY_SPEEDUP then
		-- 	return active_dict:contains(InputUtil.KEY_SPEEDUP) or
		-- 		active_dict:contains(Enum.KeyCode.Nine)

		-- elseif control == InputUtil.KEY_SPEEDDOWN then
		-- 	return active_dict:contains(InputUtil.KEY_SPEEDDOWN) or
		-- 		active_dict:contains(Enum.KeyCode.Zero)

		-- I wonder what these keys are for?
		elseif control == InputUtil.KEYCODE_TOUCH_TRACK1 then
			return _down_keys:contains(InputUtil.KEYCODE_TOUCH_TRACK1)

		elseif control == InputUtil.KEYCODE_TOUCH_TRACK2 then
			return _down_keys:contains(InputUtil.KEYCODE_TOUCH_TRACK2)

		elseif control == InputUtil.KEYCODE_TOUCH_TRACK3 then
			return _down_keys:contains(InputUtil.KEYCODE_TOUCH_TRACK3)

		elseif control == InputUtil.KEYCODE_TOUCH_TRACK4 then
			return _down_keys:contains(InputUtil.KEYCODE_TOUCH_TRACK4)

		else
			error("INPUTKEY NOT FOUND ",control)
			return false
		end
	end

	function self:control_just_pressed(control)
		return is_control_active(control,_just_pressed_keys)
	end
	function self:control_pressed(control)
		return is_control_active(control,_down_keys)
	end
	function self:control_just_released(control)
		return is_control_active(control,_just_released_keys)
	end
	function self:clear_just_pressed_keys()
		_just_pressed_keys:clear()
	end
	function self:clear_just_released_keys()
		_just_released_keys:clear()
	end

	self:cons()
	return self
end

local _keycode_enum_to_value = SPDict:new()
local _value_to_keycode_enum = SPDict:new()
for _,k in pairs(Enum.KeyCode:GetEnumItems()) do
	local v = k.Value
	_keycode_enum_to_value:add(k,v)
	_value_to_keycode_enum:add(v,k)
end
function InputUtil:keycode_enum_to_value(k) return _keycode_enum_to_value:get(k) end
function InputUtil:value_to_keycode_enum(v) return _value_to_keycode_enum:get(v) end

return InputUtil
