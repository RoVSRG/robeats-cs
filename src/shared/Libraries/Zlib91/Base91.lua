local module = {}

local ASSERTIONS_ENABLED = false -- Whether to run several checks when the module is first loaded
local MAKE_JSON_SAFE = false -- If this is true, " will be replaced by ' in the encoding

local CHAR_SET = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~"]]

local encode_CharSet = {}
local decode_CharSet = {}
for i = 1, 91 do
	encode_CharSet[i-1] = string.sub(CHAR_SET, i, i)
	decode_CharSet[string.sub(CHAR_SET, i, i)] = i-1
end

if MAKE_JSON_SAFE then
	encode_CharSet[90] = "'"
	decode_CharSet['"'] = nil
	decode_CharSet["'"] = 90
end

function module.encode(input)
	local output = {}
	local c = 1

	local counter = 0
	local numBits = 0

	for i = 1, #input do
		counter = bit32.bor(counter, bit32.lshift(string.byte(input, i), numBits))
		numBits = numBits+8
		if numBits > 13 then
			local entry = bit32.band(counter, 8191) -- 2^13-1 = 8191
			if entry > 88 then -- Voodoo magic (https://www.reddit.com/r/learnprogramming/comments/8sbb3v/understanding_base91_encoding/e0y85ot/)
				counter = bit32.rshift(counter, 13)
				numBits = numBits-13
			else
				entry = bit32.band(counter, 16383) -- 2^14-1 = 16383
				counter = bit32.rshift(counter, 14)
				numBits = numBits-14
			end
			output[c] = encode_CharSet[entry%91]..encode_CharSet[math.floor(entry/91)]
			c = c+1
		end
	end

	if numBits > 0 then
		output[c] = encode_CharSet[counter%91]
		if numBits > 7 or counter > 90 then
			output[c+1] = encode_CharSet[math.floor(counter/91)]
		end
	end

	return table.concat(output)
end

function module.decode(input)
	local output = {}
	local c = 1

	local counter = 0
	local numBits = 0
	local entry = -1

	for i = 1, #input do
		if decode_CharSet[string.sub(input, i, i)] then
			if entry == -1 then
				entry = decode_CharSet[string.sub(input, i, i)]
			else
				entry = entry+decode_CharSet[string.sub(input, i, i)]*91
				counter = bit32.bor(counter, bit32.lshift(entry, numBits))
				if bit32.band(entry, 8191) > 88 then
					numBits = numBits+13
				else
					numBits = numBits+14
				end

				while numBits > 7 do
					output[c] = string.char(counter%256)
					c = c+1
					counter = bit32.rshift(counter, 8)
					numBits = numBits-8
				end
				entry = -1
			end
		end
	end

	if entry ~= -1 then
		output[c] = string.char(bit32.bor(counter, bit32.lshift(entry, numBits))%256)
	end

	return table.concat(output)
end

return module
