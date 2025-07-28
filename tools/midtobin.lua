local mid = io.open(arg[1], 'rb')
local bin = io.open(arg[2], 'wb')

local nextblock = 0
local checksum = 0
local function handlesysex(sysex)
	if sysex:sub(1, 2) ~= string.char(0x43, 0x7D) then
		error('unexpected sysex')
	end
	local type = sysex:byte(3)
	if type == 0x30 and sysex:sub(4, 12) == 'DTA1ERASE' then
		if #sysex ~= 14 then
			error('unexpected DTA1ERASE size')
		end
		if sysex:byte(13) ~= 2 then
			error('unexpected flash section')
		end
	elseif type == 0x40 and sysex:sub(6, 13) == 'DTA1MAIN' then
		local size = sysex:byte(4) * 128 + sysex:byte(5)
		if size ~= #sysex - 7 then
			error('unexpected DTA1MAIN size')
		end
		local sum = 0
		for i = 6, #sysex - 1 do
			sum = sum + sysex:byte(i)
		end
		if sum & 0x7F ~= 0 then
			error('bad checksum')
		end

		local block = sysex:byte(14) * 128 + sysex:byte(15)
		if block ~= nextblock then
			error(string.format('blocks out of order %d %d', block, nextblock))
		end
		nextblock = block + 1
		local num = sysex:byte(16) * 128 + sysex:byte(17)
		if num ~= 0x3FFF then
			error('unexpected DTA1MAIN')
		end
		if (#sysex - 19) % 8 ~= 0 then
			error('unexpected sysex length '..#sysex)
		end
		local datasize = (#sysex - 19) // 8 * 7 & ~7
		for i = 18, #sysex - 2, 8 do
			local bytes = table.pack(sysex:byte(i, i + math.min(7, datasize) - 1))
			local high = sysex:byte(i + 7)
			for j = 1, #bytes do
				local b = bytes[j] | (high << j & 0x80)
				bytes[j] = b
				checksum = (checksum + b) & 0x7F
			end
			bin:write(string.char(table.unpack(bytes)))
			datasize = datasize - #bytes
		end
	elseif type == 0x70 and sysex:sub(4, 11) == 'DTA1CSUM' then
		if #sysex ~= 13 then
			error('unexpected DTA1CSUM size')
		end
		local dta1csum = sysex:byte(12)
		if dta1csum ~= ~checksum + 1 & 0x7F then
			error('bad checksum, expected '..dta1csum..' got '..checksum)
		end
		print('checksum matched')
	else
		error(string.format('unknown type %02X', type))
	end
end

local midifile, miditrack = {}, {}

function midifile:new(file)
	self.__index = self
	local obj = setmetatable({
		file=file,
	}, self)
	local type, length = obj:readchunk()
	if type ~= 'MThd' then
		error('expected MThd chunk')
	end
	obj.header = file:read(length)
	return obj
end
function midifile:readchunk()
	local head = self.file:read(8)
	if not head then return nil end
	return string.unpack('>c4I4', head)
end
function midifile:readtrack()
	local type, length = self:readchunk()
	if not type then return nil end
	if type ~= 'MTrk' then
		error('expected MTrk chunk')
	end
	return miditrack:new(self.file, length)
end
function midifile:tracks()
	return self.readtrack, self
end

function miditrack:new(file, length)
	self.__index = self
	return setmetatable({
		file=file,
		length=length,
		offset=0,
	}, self)
end
function miditrack:readbyte()
	if self.offset == self.length then
		error('midi track is truncated')
	end
	assert(self.offset < self.length)
	local byte = self.file:read(1)
	if not byte then
		error('midi track is truncated')
	end
	self.offset = self.offset + 1
	return string.byte(byte, 1)
end
function miditrack:readvarint()
	local val = 0
	repeat
		local byte = self:readbyte()
		val = val << 7 | byte & 0x7F
	until byte & 0x80 == 0
	return val
end
function miditrack:readevent()
	if self.offset == self.length then
		return nil
	end
	assert(self.offset < self.length)
	local event = {delta=self:readvarint(), status=self:readbyte()}
	if event.status == 0xF0 then
		local length = self:readvarint()
		if self.length - self.offset < length then
			error('midi sysex event is truncated')
		end
		event.sysex = self.file:read(length)
		self.offset = self.offset + length
	elseif event.status == 0xFF then
		event.metatype = self:readbyte()
		local length = self:readvarint()
		if self.length - self.offset < length then
			error('midi meta event is truncated')
		end
		event.metadata = self.file:read(length)
		self.offset = self.offset + length
	else
		error(string.format('unexpected event status %02X', event.status))
	end
	return event
end
function miditrack:events()
	return self.readevent, self
end

local f = midifile:new(mid)
for track in f:tracks() do
	for event in track:events() do
		if event.status == 0xF0 then
			handlesysex(event.sysex)
		elseif event.status == 0xFF then
			if event.metatype == 0x03 then
				local name = event.metadata
			elseif event.metatype == 0x51 then
				local tempo = string.unpack('>I3', event.metadata)
			elseif event.metatype == 0x58 then
			elseif event.metatype == 0x2F then
				break
			end
		end
	end
end
