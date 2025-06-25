local bin = io.open(arg[1], 'r')
local mid = io.open(arg[2], 'w')

local div = 500 -- 500 ticks / beat * 120 beat / minute = 1 tick / msec
mid:write('MThd')
mid:write(string.pack('>I4I2I2I2', 6, 0, 1, div))
mid:write('MTrk')
local lenoff = mid:seek('cur')
mid:write(string.pack('>I4', 0))  -- written later

local function varint(n)
	local bytes = {n & 0x7F}
	while n > 0x7F do
		n = n >> 7
		table.insert(bytes, 1, (n & 0x7F) | 0x80)
	end
	return string.char(table.unpack(bytes))
end

local function int14_7bit(n)
	return string.char(n // 0x80, n & 0x7F)
end

local function sum(data, s)
	if not s then s = 0 end
	for i = 1, #data do
		s = s + data:byte(i) & 0x7F
	end
	return s
end

local function writemeta(delta, type, data)
	mid:write(varint(delta))
	mid:write(string.char(0xFF, type))
	mid:write(varint(#data))
	mid:write(data)
end

local function writesysex(delta, data)
	mid:write(varint(delta))
	if string.byte(data) == 0xF0 then
		mid:write('\xF0')
		mid:write(varint(#data - 1))
		mid:write(data:sub(2))
	else
		mid:write('\xF7')
		mid:write(varint(#data))
		mid:write(data)
	end
end

writemeta(0, 0x51, string.pack('>I3', 500000))
writemeta(0, 0x58, string.char(0x04, 0x02, 0x18, 0x08))

writesysex(0, '\xF0\x43\x7D\x30DTA1ERASE\x02\xF7')
local prefix = '\xF0\x43\x7D\x40'
local block = 0
local delta = 16000
local datasum = 0
local bytes = {}
while true do
	local data = bin:read(448)
	if not data then break end
	datasum = sum(data, datasum)
	local parts = {
		'DTA1MAIN',
		int14_7bit(block),
		int14_7bit(0x3FFF),
	}
	for i = 1, #data - 1, 7 do
		local high = 0
		for j = 1, 7 do
			local byte = data:byte(i + j - 1) or 0
			high = high | (byte & 0x80) >> j
			bytes[j] = byte & 0x7F
		end
		bytes[8] = high
		table.insert(parts, string.char(table.unpack(bytes)))
	end
	local data7 = table.concat(parts)
	writesysex(delta, prefix..int14_7bit(#data7)..data7..string.char(~sum(data7) + 1 & 0x7F)..'\xF7')
	block = block + 1
	delta = 50
end
writesysex(delta, '\xF0\x43\x7D\x70DTA1CSUM'..string.char(~datasum + 1 & 0x7F)..'\xF7')
writemeta(0, 0x2F, '')

local len = mid:seek('cur') - (lenoff + 4)
mid:seek('set', lenoff)
mid:write(string.pack('>I4', len))

mid:close()
