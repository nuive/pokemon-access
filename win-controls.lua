local ffi = require "ffi"
local encoding = require "encoding"
local kernel32 = ffi.load("kernel32")
local dll = ffi.load("win-controls")
ffi.cdef[[
const char* InputBox(const char* title, const char* caption, const char* default);
int* ComboBox(const char* title, const char* caption, const char** list, const int index, const int** sublist);
void free_pointer(void *p);
]]

local function inputbox(title, caption, default)
default = default or ""
local res = dll.InputBox(encoding.to_utf16(title), encoding.to_utf16(caption), encoding.to_utf16(default))
if res ~= nil then
local s = encoding.to_utf8(ffi.cast("const wchar_t *", res))
dll.free_pointer(ffi.cast("void*", res))
return s
end
end

local function combobox(title, caption, list, data)
list = list or {}
data = data or 1
local encoded_list = {}
for _,v in pairs(list) do
table.insert(encoded_list, encoding.to_utf16(v))
end
local list_cstruct = "const char*[" .. #encoded_list + 1 .. "]"
local list_cdata = ffi.new(list_cstruct, encoded_list)
local sublist_cdata = nil
local index
if type(data) == "table" then
local encoded_sublist = {}
for _,v in pairs(data) do
table.insert(encoded_sublist, v -1)
end
local sublist_cstruct = "const int[" .. #encoded_sublist .. "]"
sublist_cdata = ffi.new("const int*[1]", ffi.new(sublist_cstruct, encoded_sublist))
index = #data
else
index = data -1
end
local res = dll.ComboBox(encoding.to_utf16(title), encoding.to_utf16(caption), list_cdata, index, sublist_cdata)
if res ~= nil then
local i = res[0]
if sublist_cdata then
sublist = {}
for j = 0, (i -1) do
table.insert(sublist, sublist_cdata[0][j] +1)
end
dll.free_pointer(ffi.cast("void*", res))
return sublist
else
dll.free_pointer(ffi.cast("void*", res))
return i +1
end
end
end

return {inputbox=inputbox, combobox=combobox}
