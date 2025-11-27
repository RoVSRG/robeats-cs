local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function inverseLerp(a: number, b: number, value: number): number
    if a == b then
        return 0 -- Avoid division by zero
    end
    return (value - a) / (b - a)
end

return {
	lerp = lerp,
	inverseLerp = inverseLerp,
}