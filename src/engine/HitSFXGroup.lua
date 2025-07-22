local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local HitSFXGroup = {}

local __has_preloaded_sfxg_id = SPDict:new()

function HitSFXGroup:new(_local_services,sfxg_id)
	local self = {}

	local _i_hitfx = 1
	local _hitfx = SPList:new()
	local _volume = 0.35

	function self:cons()
		if sfxg_id == 0 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_TAMB_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_TAMB_2)
			_volume = 0.1

		elseif sfxg_id == 1 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_INDHIHAT_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_INDHIHAT_2)
			_hitfx:push_back(SFXManager.SFX_HITFXG_INDHIHAT_3)
			_volume = 0.1

		elseif sfxg_id == 2 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_DRUM_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_DRUM_2)
			_volume = 0.1

		elseif sfxg_id == 3 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_CLAP_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_CLAP_2)
			_volume = 0.1

		elseif sfxg_id == 4 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_HIHAT_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_HIHAT_2)
			_hitfx:push_back(SFXManager.SFX_HITFXG_HIHAT_3)
			_volume = 0.1

		elseif sfxg_id == 5 then
			_hitfx:push_back(SFXManager.SFX_HITFXG_JAZZHH_1)
			_hitfx:push_back(SFXManager.SFX_HITFXG_JAZZHH_2)
			_hitfx:push_back(SFXManager.SFX_HITFXG_JAZZHH_3)
			_volume = 0.1

		else
			DebugOut:errf("invalid sfxg_id(%s)",tostring(sfxg_id))
		end
	end

	function self:preload()
		if __has_preloaded_sfxg_id:contains(sfxg_id) == false then
			for i=1,_hitfx:count() do
				local itr_id = _hitfx:get(i)
				_local_services._sfx_manager:preload(itr_id, 3, _volume)
			end
			__has_preloaded_sfxg_id:add(sfxg_id,true)
		end
	end

	function self:play_alternating()
		_local_services._sfx_manager:play_sfx(_hitfx:get(_i_hitfx),_volume)
		_i_hitfx = _i_hitfx + 1
		if _i_hitfx > _hitfx:count() then
			_i_hitfx = 1
		end
	end

	function self:play_first()
		_local_services._sfx_manager:play_sfx(_hitfx:get(1),_volume)
		_i_hitfx = 2
		if _i_hitfx > _hitfx:count() then
			_i_hitfx = 1
		end
	end

	self:cons()
	return self
end

return HitSFXGroup
