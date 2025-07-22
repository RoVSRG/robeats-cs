local HitParams = {}

--Hit Parameters associated with every ScoreManager:register_hit call
function HitParams:new()
	local self = {}
	--Should play SFX for this hit
	self.PlaySFX = true
	
	--Should create Hit Effect
	self.PlayHoldEffect = false
	self.HoldEffectPosition = Vector3.new()

	self.GhostTap = false
	
	--Is a whiff miss (miss not associated with any note, aka a "ghost tap")
	self.WhiffMiss = false
	
	--Is the beginning of a held note
	self.IsHeldNoteBegin = false
	
	--Is a time miss (miss caused by not pressing a note)
	self.TimeMiss = false
	
	function self:set_play_sfx(val) 
		self.PlaySFX = val
		return self 
	end
	
	function self:set_play_hold_effect(val, position) 
		self.PlayHoldEffect = val
		if position ~= nil then
			self.HoldEffectPosition = position
		end
		return self 
	end
	
	function self:set_whiff_miss(val) 
		self.WhiffMiss = val
		return self
	end
	
	function self:set_held_note_begin(val) 
		self.IsHeldNoteBegin = val
		return self 
	end
	
	function self:set_time_miss(val) 
		self.TimeMiss = val
		return self 
	end

	function self:set_ghost_tap(val)
		self.GhostTap = val
		return self
	end
	
	return self
end

return HitParams