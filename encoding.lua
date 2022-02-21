local ffi = require "ffi"
local kernel32 = ffi.load("kernel32")
ffi.cdef[[
int Beep(int x, int y);
typedef unsigned int UINT;
typedef unsigned int DWORD;
typedef const char * LPCSTR;
typedef char * LPSTR;
typedef wchar_t * LPWSTR;
typedef const wchar_t *LPCWSTR;
typedef int *LPBOOL;
int WideCharToMultiByte(UINT CodePage,
DWORD    dwFlags,
LPCWSTR   lpWideCharStr, int cchWideChar,
LPSTR  lpMultiByteStr, int cbMultiByte,
LPCSTR  lpDefaultChar,
LPBOOL lpUsedDefaultChar
);
int MultiByteToWideChar(UINT CodePage,
DWORD    dwFlags,
LPCSTR   lpMultiByteStr, int cbMultiByte,
LPWSTR  lpWideCharStr, int cchWideChar);
]]

local CP_UTF8 = 65001
local function to_utf16(s)
local needed = kernel32.MultiByteToWideChar(CP_UTF8, 0, s, -1, nil, 0)
local buf = ffi.new("wchar_t[?]", needed)
local written = kernel32.MultiByteToWideChar(CP_UTF8, 0, s, -1, buf, needed)
return ffi.string(ffi.cast("char *", buf), written*2)
end

local function to_utf8(s)
local needed = kernel32.WideCharToMultiByte(CP_UTF8, 0, s, -1, nil, 0, nil, nil)
local buf = ffi.new("char[?]", needed)
local written = kernel32.WideCharToMultiByte(CP_UTF8, 0, s, -1, buf, needed, nil, nil)
return ffi.string(buf, written - 1)
end

return {to_utf8=to_utf8, to_utf16=to_utf16}
