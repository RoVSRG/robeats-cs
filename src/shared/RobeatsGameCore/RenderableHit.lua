local RenderableHit = {}

function RenderableHit:new(_hit_object_time, _time_left, _judgement)
    return {
        hit_object_time = _hit_object_time + _time_left;
        time_left = _time_left;
        judgement = _judgement;
    }
end

return RenderableHit
