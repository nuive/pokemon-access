local ffi = require "ffi"
local encoding = require "encoding"
local kernel32 = ffi.load("kernel32")
local dll = ffi.load("crc32")
ffi.cdef[[
uint32_t crc32(uint32_t crc, const void *buf, size_t size);
]]

local function crc32(src, crc)

	if type(src) == "string" then
		src = ffi.new("const char[" .. #src .. "]", src)
	elseif type(src) == "table" then
		src = ffi.new("const uint8_t[" .. #src .. "]", src)
	else
		return nil
	end
	len = ffi.sizeof(src)

	if not crc then
	crc = 0
	end

	return dll.crc32(crc, src, len)
end

return {crc32 = crc32}
