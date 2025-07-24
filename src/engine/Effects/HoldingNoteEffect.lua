local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local HoldingNoteEffect = {}
HoldingNoteEffect.Type = "HoldingNoteEffect"

local STARTING_ALPHA = 0.1
local ENDING_ALPHA = 0

function HoldingNoteEffect:new(
	_game,
	_position,
	_note_result
)
	local self = EffectSystem:EffectBase()
	self.ClassName = HoldingNoteEffect.Type
	
	self._effect_obj = nil;
	self._anim_t = 0
	
	local function update_visual()
		self._effect_obj.Body.Transparency = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,SPUtil:tra(STARTING_ALPHA)),
			Vector2.new(1,SPUtil:tra(ENDING_ALPHA)),
			self._anim_t
		)
		
		local size_val = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,2),
			Vector2.new(1,3.4),
			self._anim_t
		)
		self._effect_obj.Body.Size = Vector3.new(size_val,size_val,size_val)
	end	
	
	function self:cons()
		self._effect_obj = _game._object_pool:depool(self.ClassName)
		if self._effect_obj == nil then
			self._effect_obj = EnvironmentSetup:get_element_protos_folder().HoldingNoteEffectProto:Clone()
		end
		
		self._effect_obj.PrimaryPart.Position = _position
		
		if _note_result == NoteResult.Miss then
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(190, 30, 30)
		elseif _note_result == NoteResult.Bad then
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(174, 22, 194)
		elseif _note_result == NoteResult.Good then
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(12, 15, 151)
		elseif _note_result == NoteResult.Great then
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(57, 192, 16)
		elseif _note_result == NoteResult.Perfect then
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(235, 220, 13)
		else
			self._effect_obj.PrimaryPart.Color = Color3.fromRGB(255, 255, 255)
		end	
		
		self._anim_t = 0
		update_visual()
	end	
	
	--[[Override--]] function self:add_to_parent(parent)
		self._effect_obj.Parent = parent
	end
	
	--[[Override--]] function self:update(dt_scale)
		self._anim_t = self._anim_t + CurveUtil:SecondsToTick(0.35) * dt_scale
		update_visual()	
	end	
	--[[Override--]] function self:should_remove()
		return self._anim_t >= 1
	end	
	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,self._effect_obj)
	end		
	
	self:cons()
	return self
end

return HoldingNoteEffect

