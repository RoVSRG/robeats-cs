local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)

local SPVector = {}

function SPVector:from_vec3(vec3)
	return SPVector:new(vec3.X,vec3.Y,vec3.Z)
end
function SPVector:from_vec2(vec2)
	return SPVector:new(vec2.X,vec2.Y)
end

function SPVector:new(x,y,z)
	local self = {
		_x = x;
		_y = y;
		_z = z;
	}

	function self:add_scaled(vec, scale)
		self._x = self._x +	vec._x * scale
		self._y = self._y +	vec._y * scale
		self._z = self._z +	vec._z * scale
	end
	function self:set(x,y,z)
		if x ~= nil then
			self._x = x
		end
		if y ~= nil then
			self._y = y
		end
		if z ~= nil then
			self._z = z
		end
	end
	function self:magnitude()
		local x = 0
		local y = 0
		local z = 0
		if self._x ~= nil then x = self._x end
		if self._y ~= nil then y = self._y end
		if self._z ~= nil then z = self._z end

		return math.sqrt(math.pow(x,2) + math.pow(y,2) + math.pow(z,2))
	end
	
	function self:distance_to(other)
		local x = 0
		local y = 0
		local z = 0
		if self._x ~= nil then x = self._x end
		if self._y ~= nil then y = self._y end
		if self._z ~= nil then z = self._z end
		
		local ox = 0
		local oy = 0
		local oz = 0
		if other._x ~= nil then ox = other._x end
		if other._y ~= nil then oy = other._y end
		if other._z ~= nil then oz = other._z end
		
		return math.sqrt(math.pow(ox - x, 2) + math.pow(oy - y, 2) + math.pow(oz - z,2))
	end

	function self:expt_to(tx,ty,tz,drptval_sec,dt_scale)
		self._x = CurveUtil:Expt(
			self._x,
			tx,
			CurveUtil:NormalizedDefaultExptValueInSeconds(drptval_sec),
			dt_scale
		)
		self._y = CurveUtil:Expt(
			self._y,
			ty,
			CurveUtil:NormalizedDefaultExptValueInSeconds(drptval_sec),
			dt_scale
		)
		self._z = CurveUtil:Expt(
			self._z,
			tz,
			CurveUtil:NormalizedDefaultExptValueInSeconds(drptval_sec),
			dt_scale
		)
	end

	function self:to_color3()
		return Color3.new(self._x/255.0,self._y/255.0,self._z/255.0)
	end
	function self:to_vector2()
		return Vector2.new(self._x,self._y)
	end
	function self:to_vector3()
		return Vector3.new(self._x,self._y,self._z)
	end
	function self:to_string()
		return string.format("{%s, %s, %s}", tostring(self._x), tostring(self._y), tostring(self._z))
	end

	return self
end

return SPVector
