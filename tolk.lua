local ffi = require "ffi"
local encoding = require "encoding"
ffi.cdef[[
void Tolk_Load();
void Tolk_Output(const char *s, bool interrupt);
void Tolk_Silence();
]]
local tolk = ffi.load("tolk")
tolk.Tolk_Load()
local function output(s)
tolk.Tolk_Output(encoding.to_utf16(s), false)
end
local function silence()
tolk.Tolk_Silence()
end
return {output=output, silence=silence}
