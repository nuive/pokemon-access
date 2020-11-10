local ffi = require "ffi"
local encoding = require "encoding"
local kernel32 = ffi.load("kernel32")
local dll = ffi.load("inputbox")
ffi.cdef[[
const char *InputBox(const char *title, const char *caption, const char *default);
void free_string(const char *s);
]]

local function inputbox(title, caption, default)
default = default or ""
local res = dll.InputBox(encoding.to_utf16(title), encoding.to_utf16(caption), encoding.to_utf16(default))
if res ~= nil then
local s = encoding.to_utf8(ffi.cast("const wchar_t *", res))
dll.free_string(res)
return s
end
end
return {inputbox=inputbox}
