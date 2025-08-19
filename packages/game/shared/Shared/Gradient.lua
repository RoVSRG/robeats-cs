  
local SPList = require(game.ReplicatedStorage.Shared.SPList)

local Gradient = {}

function Gradient:new()
    local self = {}
    self._keypoints = SPList:new()

    function self:add_color_keypoint(time, color)
        self._keypoints:push_back(ColorSequenceKeypoint.new(time, color))
    end

    function self:add_number_keypoint(time, number)
        self._keypoints:push_back(NumberSequenceKeypoint.new(time, number))
    end

    function self:remove_keypoint(time)
        for i = 1, self._keypoints:count() do
            local itr_keypoint = self._keypoints:get(i)
            if itr_keypoint.Time == time then
                self._keypoints:remove_at(i)
            end
        end
    end

    function self:color_sequence()
        return ColorSequece.new(self._keypoints._table)
    end
    
    function self:number_sequence()
        return NumberSequence.new(self._keypoints._table)
    end

    return self
end

return Gradient