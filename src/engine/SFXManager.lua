local SPMultiDict = require(game.ReplicatedStorage.Shared.SPMultiDict)

local SFXManager = {}

SFXManager.SFX_HITFXG_DRUM_1 = "rbxassetid://574838657"
SFXManager.SFX_HITFXG_DRUM_2 = "rbxassetid://574838433"

SFXManager.SFX_HITFXG_TAMB_1 = "rbxassetid://864172134"
SFXManager.SFX_HITFXG_TAMB_2 = "rbxassetid://864172106"

SFXManager.SFX_HITFXG_INDHIHAT_1 = "rbxassetid://864171976"
SFXManager.SFX_HITFXG_INDHIHAT_2 = "rbxassetid://864172006"
SFXManager.SFX_HITFXG_INDHIHAT_3 = "rbxassetid://864172044"

SFXManager.SFX_HITFXG_HIHAT_1 = "rbxassetid://870818834"
SFXManager.SFX_HITFXG_HIHAT_2 = "rbxassetid://870818951"
SFXManager.SFX_HITFXG_HIHAT_3 = "rbxassetid://870819035"

SFXManager.SFX_HITFXG_CLAP_1 = "rbxassetid://866504380"
SFXManager.SFX_HITFXG_CLAP_2 = "rbxassetid://866504511"

SFXManager.SFX_HITFXG_JAZZHH_1 = "rbxassetid://880947857"
SFXManager.SFX_HITFXG_JAZZHH_2 = "rbxassetid://880947978"
SFXManager.SFX_HITFXG_JAZZHH_3 = "rbxassetid://880948071"

SFXManager.SFX_DRUM_OKAY = "rbxassetid://574838536"
SFXManager.SFX_MISS = "rbxassetid://574838230"
SFXManager.SFX_TICK = "rbxassetid://574838785"

SFXManager.SFX_COUNTDOWN_READY = "rbxassetid://770375074"
SFXManager.SFX_COUNTDOWN_GO = "rbxassetid://770373595"

SFXManager.SFX_WOOSH = "rbxassetid://770375537"
SFXManager.SFX_ACQUIRE = "rbxassetid://770372288"
SFXManager.SFX_BUTTONPRESS = "rbxassetid://770372471"
SFXManager.SFX_COMBINE = "rbxassetid://770372702"

SFXManager.SFX_FANFARE = "rbxassetid://770373343"
SFXManager.SFX_MENU_BUY = "rbxassetid://770373814"
SFXManager.SFX_MENU_CLOSE = "rbxassetid://770373986"
SFXManager.SFX_MENU_OPEN = "rbxassetid://770374860"
SFXManager.SFX_MENU_CLOSE_LONG = "rbxassetid://770374214"
SFXManager.SFX_MENU_OPEN_LONG = "rbxassetid://770374514"
SFXManager.SFX_USE = "rbxassetid://770375349"

SFXManager.SFX_CROWD_TEMP = "rbxassetid://770373135"

SFXManager.SFX_BOO_1 = "rbxassetid://786602539"
SFXManager.SFX_ENDCHEER_1 = "rbxassetid://786602445"
SFXManager.SFX_FEVERCHEER_1 = "rbxassetid://786602324"
SFXManager.SFX_STARTCHEER_1 = "rbxassetid://786602174"

function SFXManager:new()
	local self = {}

	local _sfx_pooled_parent = Instance.new("Folder", game.Workspace)
	_sfx_pooled_parent.Name = "SFXPooledParent"
	local _sfx_active_parent = Instance.new("Folder", game.Workspace)
	_sfx_active_parent.Name = "SFXActiveParent"

	self._key_to_pooled_sound = SPMultiDict:new()
	self._key_to_active_sound = SPMultiDict:new()

	local function create_pooled(sfx_key, volume)
		if volume == nil then
			volume = 0.5
		end

		local rtv = Instance.new("Sound", _sfx_pooled_parent)
		rtv.SoundId = sfx_key
		rtv.Name = string.format("%s", sfx_key)
		rtv.Parent = _sfx_pooled_parent
		rtv.Playing = false
		rtv.Volume = volume

		self._key_to_pooled_sound:push_back_to(sfx_key, rtv)
	end

	function self:cons()
		for i = 0, 3 do
			create_pooled(SFXManager.SFX_DRUM_OKAY, 0.25)
			create_pooled(SFXManager.SFX_MISS)
		end
		for i = 0, 2 do
			create_pooled(SFXManager.SFX_COUNTDOWN_READY)
		end
		for i = 0, 1 do
			create_pooled(SFXManager.SFX_COUNTDOWN_GO)
		end

		create_pooled(SFXManager.SFX_COUNTDOWN_READY)
		create_pooled(SFXManager.SFX_COUNTDOWN_READY)
		create_pooled(SFXManager.SFX_COUNTDOWN_GO)

		create_pooled(SFXManager.SFX_WOOSH)
	end

	function self:preload(sfx_key, count, volume)
		for i = 1, count do
			create_pooled(sfx_key, volume)
		end
	end

	function self:play_sfx(sfx_key, volume)
		if self._key_to_pooled_sound:count_of(sfx_key) == 0 then
			create_pooled(sfx_key)
		end

		local play_sfx = self._key_to_pooled_sound:pop_back_from(sfx_key)
		play_sfx.TimePosition = 0
		play_sfx.Looped = false
		play_sfx.Playing = true
		play_sfx.Parent = _sfx_active_parent
		if volume ~= nil then
			play_sfx.Volume = volume
		end

		self._key_to_active_sound:push_back_to(sfx_key, play_sfx)
		return play_sfx
	end

	function self:update()
		for itr_key, _ in self._key_to_active_sound:key_itr() do
			local itr_list = self._key_to_active_sound:list_of(itr_key)
			for i = itr_list:count(), 1, -1 do
				local itr_sound = itr_list:get(i)
				if itr_sound.Looped == false and itr_sound.Playing == false then
					itr_sound.Parent = _sfx_pooled_parent
					self._key_to_pooled_sound:push_back_to(itr_key, itr_sound)
					itr_list:remove_at(i)
				end
			end
		end
	end

	function self:teardown()
		if _sfx_pooled_parent then
			_sfx_pooled_parent:Destroy()
			_sfx_pooled_parent = nil
		end

		if _sfx_active_parent then
			_sfx_active_parent:Destroy()
			_sfx_active_parent = nil
		end
	end

	self:cons()
	return self
end

return SFXManager
