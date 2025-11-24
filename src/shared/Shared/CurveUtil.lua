local CurveUtil = {	}
local DEFAULT_THRESHOLD = 0.01
local TARGET_FPS = 60.0

function CurveUtil:Lerp(a,b,t)
	return (b-a)*t+a
end

function CurveUtil:Expt(start, to, pct, dt_scale)
	if math.abs(to - start) < DEFAULT_THRESHOLD then
		return to
	end

	local y = CurveUtil:Expty(start,to,pct,dt_scale)

	--rtv = start + (to - start) * timescaled_friction--
	local delta = (to - start) * y
	return start + delta
end
function CurveUtil:expt(start,to,pct,dt_scale)
	return CurveUtil:Expt(start,to,pct,dt_scale)
end

function CurveUtil:Expty(start, to, pct, dt_scale)
	--y = e ^ (-a * timescale)--
	local friction = 1 - pct
	local a = -math.log(friction)
	return 1 - math.exp(-a * dt_scale)
end

function CurveUtil:Sign(val)
	if val > 0 then
		return 1
	elseif val < 0 then
		return -1
	else
		return 0
	end
end

function CurveUtil:BezierValForT(p0, p1, p2, p3, t)
	local cp0 = (1 - t) * (1 - t) * (1 - t)
	local cp1 = 3 * t * (1-t)*(1-t)
	local cp2 = 3 * t * t * (1 - t)
	local cp3 = t * t * t
	return cp0 * p0 + cp1 * p1 + cp2 * p2 + cp3 * p3
end

CurveUtil._BezierPt2ForT = { X = 0; Y = 0 }
function CurveUtil:BezierPt2ForT(
	p0x, p0y,
	p1x, p1y,
	p2x, p2y,
	p3x, p3y,
	t)

	CurveUtil._BezierPt2ForT.X = CurveUtil:BezierValForT(p0x,p1x,p2x,p3x,t)
	CurveUtil._BezierPt2ForT.Y = CurveUtil:BezierValForT(p0y,p1y,p2y,p3y,t)
	return CurveUtil._BezierPt2ForT
end

function CurveUtil:YForPointOf2PtLine(pt1, pt2, x)
	--(y - y1)/(x - x1) = m--
	local m = (pt1.y - pt2.y) / (pt1.x - pt2.x)
	--y - mx = b--
	local b = pt1.y - m * pt1.x
	return m * x + b
end

function CurveUtil:DeltaTimeToTimescale(s_frame_delta_time)
	return s_frame_delta_time / (1.0 / TARGET_FPS)
end

function CurveUtil:TimescaleToDeltaTime(dt_scale)
	return dt_scale * (1.0 / TARGET_FPS)
end

function CurveUtil:SecondsToTick(sec)
	return (1 / TARGET_FPS) / sec
end

function CurveUtil:sec_to_tick(sec)
	return CurveUtil:SecondsToTick(sec)
end

function CurveUtil:ExptValueInSeconds(threshold, start, seconds)
		return 1 - math.pow((threshold / start), 1 / (TARGET_FPS * seconds))
end

local __NormalizedDefaultExptValueInSeconds = {}
function CurveUtil:NormalizedDefaultExptValueInSeconds(seconds)
		if __NormalizedDefaultExptValueInSeconds[seconds] == nil then
			__NormalizedDefaultExptValueInSeconds[seconds] = self:ExptValueInSeconds(DEFAULT_THRESHOLD, 1, seconds)
		end
		return __NormalizedDefaultExptValueInSeconds[seconds]
end
function CurveUtil:exptvsec(seconds)
	return self:NormalizedDefaultExptValueInSeconds(seconds)
end
function CurveUtil:expt_sec(start,to,sec,dt_scale)
	return CurveUtil:Expt(start,to,CurveUtil:exptvsec(sec),dt_scale)
end

function CurveUtil:IncrementWrap(val, incr, wrap)
	local rtv = (val + incr) % wrap
	local did_wrap = (val + incr) ~= rtv
	return rtv, did_wrap
end
function CurveUtil:incr_wrap(val,incr,wrap)
	return CurveUtil:IncrementWrap(val,incr,wrap)
end

return CurveUtil
