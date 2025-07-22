local DebugOut = {}

function DebugOut:puts(str,...)
	local out_str =	 string.format(str,...)
	print(out_str)
end

function DebugOut:warnf(str,...)
	local out_str =	string.format(str,...)
	warn(out_str)
end

function DebugOut:errf(str,...)
	local out_str =	string.format(str,...)
	error(out_str)
end

return DebugOut
