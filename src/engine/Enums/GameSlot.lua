local GameSlot = {
	SLOT_1 = 1;
	SLOT_2 = 2;
	SLOT_3 = 3;
	SLOT_4 = 4;	
}

local WORLD_POSITION_DISTANCE = 50
function GameSlot:slot_to_world_position_offset(slot)
	if slot == GameSlot.SLOT_1 then
		return Vector3.new(-WORLD_POSITION_DISTANCE,0,WORLD_POSITION_DISTANCE)
	elseif slot == GameSlot.SLOT_2 then
		return Vector3.new(-WORLD_POSITION_DISTANCE,0,-WORLD_POSITION_DISTANCE)
	elseif slot == GameSlot.SLOT_3 then
		return Vector3.new(WORLD_POSITION_DISTANCE,0,-WORLD_POSITION_DISTANCE)
	else
		return Vector3.new(WORLD_POSITION_DISTANCE,0,WORLD_POSITION_DISTANCE)
	end
end

local DEFAULT_HORIZ_DISTANCE = 36.5
local DEFAULT_UP_DISTANCE = 14
local DEFAULT_LOOKAT_HORIZ_DISTANCE = 17.5
function GameSlot:slot_to_camera_cframe_offset(slot)
	
	if slot == GameSlot.SLOT_1 then	
		return 	CFrame.new(
			Vector3.new(-DEFAULT_HORIZ_DISTANCE, DEFAULT_UP_DISTANCE, DEFAULT_HORIZ_DISTANCE),
			Vector3.new(-DEFAULT_LOOKAT_HORIZ_DISTANCE, 0, DEFAULT_LOOKAT_HORIZ_DISTANCE)
		)		
		
	elseif slot == GameSlot.SLOT_2 then
		return 	CFrame.new(
			Vector3.new(-DEFAULT_HORIZ_DISTANCE, DEFAULT_UP_DISTANCE, -DEFAULT_HORIZ_DISTANCE),
			Vector3.new(-DEFAULT_LOOKAT_HORIZ_DISTANCE, 0, -DEFAULT_LOOKAT_HORIZ_DISTANCE)
		)		
		
	elseif slot == GameSlot.SLOT_3 then
		return 	CFrame.new(
			Vector3.new(DEFAULT_HORIZ_DISTANCE, DEFAULT_UP_DISTANCE, -DEFAULT_HORIZ_DISTANCE),
			Vector3.new(DEFAULT_LOOKAT_HORIZ_DISTANCE, 0, -DEFAULT_LOOKAT_HORIZ_DISTANCE)
		)			
		
	else
		return 	CFrame.new(
			Vector3.new(DEFAULT_HORIZ_DISTANCE, DEFAULT_UP_DISTANCE, DEFAULT_HORIZ_DISTANCE),
			Vector3.new(DEFAULT_LOOKAT_HORIZ_DISTANCE, 0, DEFAULT_LOOKAT_HORIZ_DISTANCE)
		)			
		
	end
end

function GameSlot:slot_to_track_color_and_transparency(slot)
	return BrickColor.new(226), 0.75
end

return GameSlot
