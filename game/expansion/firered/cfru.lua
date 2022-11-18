-- Complete Fire Red Update

RAM_EXPANDED_FLAGS = 0x203b174
EXPANDED_FLAGS_START = 0x900

function get_flag(index)
local flags_addres
if index < SPECIAL_FLAGS_START then
if index < EXPANDED_FLAGS_START then
flags_address = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_FLAGS
else
flags_address = RAM_EXPANDED_FLAGS
index = index - EXPANDED_FLAGS_START
end
else
flags_address = RAM_SPECIAL_FLAGS
index = index - SPECIAL_FLAGS_START
end
local flag = index % 8
local flag_byte = memory.readbyte(flags_address + bit.rshift(index, 3))
return hasbit(flag_byte, flag)
end

function jump_ledge(tile, x, y)
if (tile < 0x38 or tile > 0x3F)
and tile ~= 0x7F then
return false
end
if tile == 0x7F then
if (y == 0
and (x == 1 or x == -1))
or (x == 0
and (y == 1 or y == -1)) then
return true
end
elseif y == 0 then
if x == 1
and (tile == 0x38
or tile == 0x3C
or tile == 0x3E) then
return true
elseif x == -1
and (tile == 0x39
or tile == 0x3D
or tile == 0x3F) then
return true
end
elseif x == 0 then
if y == -1
and (tile == 0x3A
or tile == 0x3C
or tile == 0x3D) then
return true
elseif y == 1
and (tile == 0x3B
or tile == 0x3E
or tile == 0x3F) then
return true
end
end
return false
end


-- custom data

chars[0xFB18] = message.translate("fairy")
