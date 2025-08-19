local module = {}

local Compression = require(script.Compression)
local Base91 = require(script.Base91)

local function toSingleQuoto(str:string)
	return string.gsub(str,"\"","'")
end

function module.compress(data:string,useSingleQuote:boolean,level:number,strategy:"dynamic"|"fixed"|"huffman_only"):string
	local compressed = Compression.Zlib.Compress(data,{
		level = level or 6;
		strategy = strategy or "dynamic"
	})
	local base91Encoded = Base91.encode(compressed)
	return not useSingleQuote and base91Encoded or toSingleQuoto(base91Encoded)
end

function module.decompress(compressedData:string,useSingleQuote:boolean):string
	local base91Decoded = Base91.decode(not useSingleQuote and compressedData or toSingleQuoto(compressedData))
	local decompressed = Compression.Zlib.Decompress(base91Decoded)
	return decompressed
end

return module
