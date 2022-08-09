ROM_TITLE_ADDRESS = 0x80000A0
ROM_GAMECODE_START = 12
REQUIRED_FILES = {"chars.lua", "memory.lua"}
codemap = {
["BPR"] = "firered",
["BPG"] = "leafgreen",
-- ["BPE"] = "emerald",
}
CHAR_NAME_END = 0xFF
DOWN = 1
UP = 2
LEFT = 3
RIGHT = 4
MAPNAME_PATTERN = "\x00\x23\x00\x24\x00\x24\x00\x25"
DEFAULT_CAMERA_X = -8
DEFAULT_CAMERA_Y = -8
connection_point = {
[0] = "unknown",
[1] = "south",
[2] = "north",
[3] = "west",
[4] = "east",
[5] = "dive",
[6] = "emerge"
}
SPECIAL_FLAGS_START = 0x4000
VARS_START = 0x4000
SPECIAL_VARS_START = 0x8000
PRIMARY_METATILES = 0x280
TOTAL_METATILES = 0x400
BADGES_START = 0x820
BADGE_CUT = 2
BADGE_SURF = 5
BADGE_WATERFALL = 0

TEXTBOX_BORDER = {
"\x00\x13\x00\x14\x00\x15\x00\x16\x00\x17",
"\x08\x13\x08\x14\x08\x15\x08\x16\x08\x17",
"\x02\x00\x02\x01\x02\x02\x02\x03\x02\x04",
"\x0A\x00\x0A\x01\x0A\x02\x0A\x03\x0A\x04",
"\x00\x01\x00\x02\x00\x02\x00\x03",
"\x00\x08\x00\x09\x00\x09\x00\x0A",
"\x00\x02\x00\x03\x00\x03\x00\x04",
"\x00\x08\x00\x09\x00\x09\x00\x0A",
"\x00\x30\x00\x31\x00\x32\x00\x33\x00\x34",
"\x00\x36\x00\x37\x00\x38\x00\x39\x00\x3a",
"\x00\x4f\x00\x50\x00\x50\x00\x51",
"\x00\x55\x00\x56\x00\x56\x00\x57",
"\x00\x58\x00\x59\x00\x59\x00\x5A",
"\x00\x5E\x00\x5F\x00\x5F\x00\x60",
"\x00\x64\x00\x65\x00\x65\x00\x66",
"\x00\x6a\x00\x6b\x00\x6b\x00\x6c",
"\x00\x81\x00\x82\x00\x82\x00\x83",
"\x00\x87\x00\x88\x00\x88\x00\x89",
"\x03\xA3\x03\xA4\x03\xA4\x03\xA5",
"\x03\xA9\x03\xAA\x03\xAA\x03\xAB",
"\x03\xC0\x03\xC1\x03\xC1\x03\xC2",
"\x03\xC6\x03\xC7\x03\xC7\x03\xC8",
}

KEYBOARD_KEYS = {
[0] = "keyboard_change",
[1] = "keyboard_backspace",
[2] = "keyboard_ok"
}

IO_BG_X = 0x4000010
IO_BG_Y = 0x4000012
SCREEN_PIXELS = 38400
SCREEN_WIDTH = 240
SCREEN_HEIGHT = 160
BG_PIXELS = 262144
BG_WIDTH = 512
BG_HEIGHT = 512
MAX_WINDOWS = 32
MAX_SPRITES = 64
SPRITE_DIMS = {
[0] = {
width = 8,
height = 8
},
[1] = {
width = 16,
height = 8
},
[2] = {
width = 8,
height = 16
},
[4] = {
width = 16,
height = 16
},
[5] = {
width = 32,
height = 8
},
[6] = {
width = 8,
height = 32
},
[8] = {
width = 32,
height = 32
},
[9] = {
width = 32,
height = 16
},
[10] = {
width = 16,
height = 32
},
[12] = {
width = 64,
height = 64
},
[13] = {
width = 64,
height = 32
},
[14] = {
width = 32,
height = 64
}
}
SPRITE_TILES = 1024
DOUBLE_COORDS = {
[0] = {71, 72},
[1] = {15},
[2] = {96, 97},
[3] = {40}
}
window_screen = {}
bg_screen = {}
last_scroll_x = {}
last_scroll_y = {}
text_window = {}
sprite_tile = {}

function free_memory()
local address = memory.getregister("r0")
for i=0, 3 do
if address == get_bg_tilemap(i) then
clear_bg_screen(i)
clear_window_screen(i)
return
end
end
end

function copy_window_to_vram()
if memory.getregister("r1") > 1 then
copy_window_to_screen(get_window(memory.getregister("r0")))
end
end

function fill_window_pixel_rect()
local id = memory.getregister("r0")
if not text_window[id] then
return
end
local window = get_window_header(id)
local left = memory.getregister("r2")
local top = memory.getregister("r3")
local width = memory.readword(memory.getregister("r13"))
local height = memory.readword(memory.getregister("r13")+4)
for i = top * window.width, (top + (height -1)) * window.width, window.width do
for j = left, (left + (width -1)) do
text_window[window.id][i+j] = 0xFF
end
end
end

function remove_window()
local window = memory.getregister("r0")
text_window[window] = clear_window(get_window(window), 0xFE)
copy_window_to_screen(get_window(window))
end

function blit_bitmap_rect_to_window()
if ignore_bitmap then
ignore_bitmap = false
return
end

local id = memory.getregister("r0")
if not text_window[id] then
return
end
local window = get_window_header(id)
local left = memory.readdword(memory.getregister("r13")+8)
local top = memory.readdword(memory.getregister("r13")+12)
local width = memory.readword(memory.getregister("r13")+16)
local height = memory.readdword(memory.getregister("r13")+20)
for i = top * window.width, (top + (height -1)) * window.width, window.width do
for j = left, (left + (width -1)) do
text_window[window.id][i+j] = 0xFF
end
end
end

function blit_move_info_icon()
local window = get_window(memory.getregister("r0"))
if not window.data then
return
end

local type = memory.getregister("r1")
local x = memory.getregister("r2")
local y = memory.getregister("r3") +8
window.data[y *window.width +x] = bit.bor(type, 0xFB00)
ignore_bitmap = true
end

function scroll_window()
local id = memory.getregister("r0")
if not text_window[id] then
return
end
local window = get_window_header(id)
local direction = memory.getregister("r1")
local distance = memory.getregister("r2")
local size = window.width * window.height
if direction == 0 then
for i = 0, size - 1 do
local new_i = i + distance * window.width
if new_i < size then
text_window[window.id][i] = text_window[window.id][new_i]
else
text_window[window.id][i] = 0xFF
end
end
elseif direction == 1 then
for i = size - 1, 0, -1 do
local new_i = i - distance * window.width
if new_i < 0 then
text_window[window.id][i] = 0xFF
else
text_window[window.id][i] = text_window[window.id][new_i]
end
end
end
end

function put_window_tilemap()
copy_window_to_screen(get_window(memory.getregister("r0")))
end

function get_window_tilelines(window)
if not window.data then
return {}
end
local tile_lines = {}
for i = 0, (window.width * window.height)-1, window.width do
local tile_line = ""
for j = 0, window.width-1 do
local char = window.data[i+j]
if char ~= nil then
if char > 0xFF then
tile_line = tile_line .. string.char(bit.rshift(char, 8)) .. string.char(char % 0x100)
else
tile_line = tile_line .. string.char(char)
end
else
tile_line = tile_line .. string.char(0xFF)
end
end
table.insert(tile_lines, tile_line)
end
return tile_lines
end

function get_window_tilelines_from_screen(window)
if not window.data then
return {}
end
local screen_tilelines = get_window_screen().tile_lines
local tile_lines = {}
for i = window.top +1, window.top +window.height do
table.insert(tile_lines, screen_tilelines[i]:sub(window.left +1, window.left +window.width))
end
return tile_lines
end

function get_last_window()
for i = 31, 0, -1 do
if memory.readbyte(RAM_WINDOWS +12 *i) ~= 0xFF then
return i
end
end

return nil
end

function window_is_empty(window)
if window.data == nil then
return true
end

for i = 0, (window.width * window.height)-1 do
if window.data[i] ~= 0xFE and window.data[i] ~= 0xFF then
return false
end
end
return true
end

function fill_window_pixel_buffer()
local id = memory.getregister("r0")
text_window[id] = clear_window(get_window(id))
end

function get_window_header(id, pixels)
if pixels == nil then
pixels = true
end
local window = {}
window.id = id
window.bg = memory.readbyte(RAM_WINDOWS+id*12)
window.left = memory.readbyte(RAM_WINDOWS+id*12+1)
window.top = memory.readbyte(RAM_WINDOWS+id*12+2)
window.width = memory.readbyte(RAM_WINDOWS+id*12+3)
window.height = memory.readbyte(RAM_WINDOWS+id*12+4)
window.data_address = memory.readdword(RAM_WINDOWS+id*12+8)
if pixels then
window.left = window.left * 8
window.top = window.top * 8
window.width = window.width * 8
window.height = window.height * 8
end
return window
end

function get_window(id, pixels)
window = get_window_header(id, pixels)
window.data = text_window[id]
return window
end

function copy_window_to_screen(window)
if not window.data then
return
end

local screen_width, screen_height = get_bg_screen_size(window.bg)
local left = bit.band(window.left, screen_width *8 -1)
local top = bit.band(window.top, screen_height *8 -1)

for i = 0, (window.height - 1) do
for j = 0, (window.width - 1) do
window_screen[window.bg][((top + i)*BG_WIDTH) + (left + j)] = window.data[i*window.width+j]
end
end
for i = 0, ((window.height /8) -1) do
for j = 0, ((window.width /8) *2 -1) do
bg_screen[window.bg][(((top /8)+ i)*BG_WIDTH/4) + ((left/8)*2 + j)] = 0x00
end
end
end

function create_window(bg, left, top, width, height, fill)
if not fill then
fill = 0xFE
end
local window = {}
for i = 0, (width * height) -1 do
window[i] = fill
end
return {
bg=bg,
left=left,
top=top,
width=width,
height=height,
data_address=0,
data=window}
end

function clear_window(window, value)
if not value then
value = 0xFF
end
window.data = {}
for i = 0, (window.width * window.height) -1 do
window.data[i] = value
end
return window.data
end

function clear_window_from_screen(window)
local screen_width, screen_height = get_bg_screen_size(window.bg)
local left = bit.band(window.left, screen_width *8 -1)
local top = bit.band(window.top, screen_height *8 -1)
for i = 0, (window.height - 1) do
for j = 0, (window.width - 1) do
window_screen[window.bg][((top + i)*BG_WIDTH) + (left + j)] = 0xFE
end
end
end

function get_screen_starting_position(bg, pixels)
if pixels == nil then
pixels = true
end
local screen_width, screen_height = get_bg_screen_size(bg)
local left = bit.band(memory.readword(IO_BG_X +4 *bg), screen_width *8 -1)
local top = bit.band(memory.readword(IO_BG_Y +4 *bg), screen_height *8 -1)
if not pixels then
left = math.floor(left /4)
top = math.floor(top /8)
end
return left, top
end

function is_scrolling()
local scrolling = false
for i = 0, 3 do
local scroll_x, scroll_y = get_screen_starting_position(i)
if scroll_x ~= last_scroll_x[i] or scroll_y ~= last_scroll_y[i] then
if not unread_text
and last_scroll_x[i] ~= nil and last_scroll_y[i] ~= nil
and (math.abs(scroll_x - last_scroll_x[i]) >= 240
or math.abs(scroll_y -last_scroll_y[i]) >= 160) then
want_read = true
end
scrolling = true
end

last_scroll_x[i] = scroll_x
last_scroll_y[i] = scroll_y
end

return scrolling
end

function get_hidden_bg()
if keyboard_showing() then
return memory.readbyte(memory.readdword(RAM_NAMING_DATA_POINTER) + 0x1E21) + 1
end
return nil
end

function get_bg_screen_size(id)
local size = bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id), 0xC), 2)
return 32 *(1 +bit.band(size, 1)), 32 *(1 +bit.rshift(size, 1))
end

function get_bg_priority(id)
return bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id), 0x30), 4)
end

function get_bg_tilemap(id)
return memory.readdword(RAM_BG_TILEMAPS +16 *id)
end

function sort_bgs()
local bgs = {0, 1, 2, 3}
for i = 1, 4 do
local priority = get_bg_priority(bgs[i])
for j = i -1, 1, -1 do
local new_priority = get_bg_priority(bgs[j])
if new_priority > priority then
local tmp = bgs[j +1]
bgs[j +1] = bgs[j]
bgs[j] = tmp
end
end
end
return bgs
end

function fill_bg_tilemap_buffer_rect()
local bg = memory.getregister("r0")
if bg > 3 then
return
end

local screen_width, screen_height = get_bg_screen_size(bg)
local tile = memory.getregister("r1")
local left = bit.band(memory.getregister("r2"), screen_width -1) * 2
local top = bit.band(memory.getregister("r3"), screen_height -1)
local width = memory.readword(memory.getregister("r13")) * 2
local height = memory.readword(memory.getregister("r13")+4)
local bg_width = BG_WIDTH / 4
for i = top * bg_width, (top + (height -1)) * bg_width, bg_width do
for j = left, (left + (width -1)), 2 do
bg_screen[bg][i+j] = bit.rshift(tile, 8)
bg_screen[bg][i+j+1] = bit.band(tile, 0xFF)
end
end
left = left * 4
top = top * 8
width = width * 4
height = height * 8
local window_fill
if tile == 0 then
window_fill = 0xFE
else
window_fill = 0xff
end
for i = top * BG_WIDTH, (top + (height -1)) * BG_WIDTH, BG_WIDTH do
for j = left, (left + (width -1)) do
window_screen[bg][i+j] = window_fill
end
end
end

function handle_battle_window()
local flags = memory.readdword(memory.getregister("r13"))
if bit.band(flags, 1) == 0 then
return
end

local bg
if bit.band(flags, 80) ~= 0 then
bg = 1
else
bg = 0
end

local screen_width, screen_height = get_bg_screen_size(bg)
local start_x = bit.band(memory.getregister("r0"), screen_width -1) * 2
local start_y = bit.band(memory.getregister("r1"), screen_height -1)
local end_x = bit.band(memory.getregister("r2"), screen_width -1) * 2
local end_y = bit.band(memory.getregister("r3"), screen_height -1)
local bg_width = BG_WIDTH / 4
for i = start_y * bg_width, end_y * bg_width, bg_width do
for j = start_x, end_x +1 do
bg_screen[bg][i+j] = 0
end
end
start_x = start_x * 4
start_y = start_y * 8
end_x = (end_x+1) *4 -1
end_y = (end_y +1) *8 -1
for i = start_y * BG_WIDTH, end_y * BG_WIDTH, BG_WIDTH do
for j = start_x, end_x do
window_screen[bg][i+j] = 0xFE
end
end
end

function check_window_present(template, first_window, windows_to_check)
if not first_window then
first_window = 0
end
if not windows_to_check then
windows_to_check = 32
end
local current_windows = RAM_WINDOWS + 12 * first_window
local i = 0
while i < windows_to_check and memory.readbyte(template) ~= 0xFF do
local req_window = memory.readbyterange(template, 8)
local window = memory.readbyterange(current_windows, 8)
if not compare(window, req_window) then
return false
end
template = template + 8
current_windows = current_windows + 12
i = i + 1
end
return true
end

function questlog_clean()
local id = memory.getregister("r0")
if not text_window[id] then
return
end
for i = 0, 0x2D00 do
text_window[id][i] = 0xFF
end
end

function sprite_tile_num(id)
return bit.band(memory.readword(RAM_SPRITES + (0x44*id) +4), 0x3FF)
end

function sprite_flags(id)
return memory.readword(RAM_SPRITES + (0x44*id) +0x3E)
end

function sprite_in_use(id)
return bit.band(sprite_flags(id), 1) ~= 0
end

function sprite_invisible(id)
return bit.band(sprite_flags(id), 4) ~= 0
end

function sprite_coords(id)
return bit.band(memory.readword(RAM_SPRITES + (0x44*id) +2), 0x1FF), memory.readbyte(RAM_SPRITES + (0x44*id))
end

function sprite_dimensions(id)
local index = bit.rshift(memory.readbyte(RAM_SPRITES + (0x44*id) +3), 6) *4 +bit.rshift(memory.readbyte(RAM_SPRITES + (0x44*id) +1), 6)
return SPRITE_DIMS[index].width, SPRITE_DIMS[index].height
end

function sprite_priority(id)
return bit.rshift(bit.band(memory.readbyte(RAM_SPRITES + (0x44*id) +5), 0xC), 2)
end

function build_sprite_data(id, sprite)
local left = sprite_tile_num(id)
local width = SPRITE_TILES * 8
local width_tiles = sprite.width /8
for i = 0, sprite.height -1 do
for j = 0, sprite.width -1 do
sprite.data[i * sprite.width + j] = sprite_tile[(i % 8)*width + (left + math.floor(i /8) *width_tiles) *8 +j]
end
end
end

function copy_sprite_to_screen(sprite, screen)
if not sprite.data then
return
end
for i = 0, (sprite.height - 1) do
for j = 0, (sprite.width - 1) do
if sprite.data[i*sprite.width+j] ~= 0xfe then
screen[((sprite.top + i)*SCREEN_WIDTH) + (sprite.left + j)] = sprite.data[i*sprite.width+j]
end
end
end
end

function animate_sprites(last_sprite, bg_priority, screen)
for i = last_sprite, 0, -1 do
local current = memory.readbyte(RAM_SPRITE_ORDER +i)
if sprite_priority(current) >= bg_priority then
if sprite_in_use(current) and not sprite_invisible(current) then
sprite = create_window(nil, nil, nil, sprite_dimensions(current))
build_sprite_data(current, sprite)
sprite.left, sprite.top = sprite_coords(current)
copy_sprite_to_screen(sprite, screen)
end
else
return i
end
end
return -1
end

function draw_text_to_tile_buffer()
local window = get_last_window()
if window == nil then
return
end

window = get_window(window)
if window.data == nil then
return
end

tmp_sheet = create_window(4, 0, 0, 384, 8)

local size = memory.getregister("r0")

local left = 0
for time = size, 1, -1 do
for i = 0, window.height -1 do
for j = 0, 31 do
tmp_sheet.data[(i % 8)*tmp_sheet.width + math.floor(i /8) *32 + left *2 +j] = window.data[i*window.width +left +j]
end
end
left = left +32
end
end

function load_sprite_sheet()
local dest_data = bit.band(memory.getregister("r1"), 0xFFFF)
local size = memory.getregister("r2") *2

local left = dest_data /4
local width = SPRITE_TILES * 8
local copy_width = size /8
local copy_height = 8

local sheet
if tmp_sheet then
sheet = tmp_sheet
tmp_sheet = nil
else
sheet = create_window(nil, 0, 0, copy_width, copy_height)
end

for i = 0, copy_height -1 do
for j = 0, copy_width -1 do
sprite_tile[i*width + left + j] = sheet.data[i *copy_width +j]
end
end
end

function copy_window_to_sprite_tiles(window, source_data, dest_data, line_start, sprite_width, copy_width, copy_height)
if window.data == nil then
return
end

source_data = source_data - window.data_address
dest_data = bit.band(dest_data, 0xFFFF)

local window_left = (source_data /4) %window.width
local window_top = math.floor((source_data /4) /window.width)
local left = dest_data /4
local width = SPRITE_TILES * 8

for i = line_start, copy_height -1 do
for j = 0, copy_width -1 do
sprite_tile[(i % 8)*width + left + math.floor(i /8) *sprite_width + j] = window.data[(window_top + i)*window.width+(window_left + j)]
end
end
end

function add_healthbox_text()
local window = get_last_window()
if window == nil then
return
end

copy_window_to_sprite_tiles(get_window(window), memory.getregister("r1"), memory.getregister("r0"), 5, 64, memory.getregister("r2") *8, 16)
end

function safari_add_healthbox_text()
local window = get_last_window()
if window == nil then
return
end

copy_window_to_sprite_tiles(get_window(window), memory.getregister("r1"), memory.getregister("r0"), 0, 64, memory.getregister("r2") *8, 16)
end

function show_status_in_healthbox()
local window = create_window(nil, 0, 0, 32, 8, 0xFF)

local status = memory.getregister("r4")
local fill = 0xFF
if bit.band(status, 0x07) ~= 0 then
fill = 0xFC03
elseif bit.band(status, 0x88) ~= 0 then
fill = 0xFC01
elseif bit.band(status, 0x10) ~= 0 then
fill = 0xFC05
elseif bit.band(status, 0x20) ~= 0 then
fill = 0xFC04
elseif bit.band(status, 0x40) ~= 0 then
fill = 0xFC02
end

local line = window.width *4
window.data[line] = fill

local dest_data = (sprite_tile_num(memory.getregister("r9")) +memory.getregister("r8")) *32
copy_window_to_sprite_tiles(window, 0, dest_data, 0, 32, 24, 8)
end

function show_status_in_summary()
tmp_sheet = create_window(nil, 0, 0, 256, 8, 0xFF)

local line = tmp_sheet.width *4
for i = 1, 7 do
tmp_sheet.data[line +32 *(i -1) +4] = 0xFC00 +i
end
end

function print_box_data_to_sprite()
local window = get_last_window()
if window == nil then
return
end

copy_window_to_sprite_tiles(get_window(window), memory.getregister("r0"), memory.getregister("r1"), 0, 64, memory.getregister("r2") /2, 16)
end

function clear_window_screen(id)
window_screen[id] = {}
for i = 0, BG_PIXELS-1 do
window_screen[id][i] = 0xFE
end
end

function clear_bg_screen(id)
bg_screen[id] = {}
for i = 0, (BG_PIXELS /32)-1 do
bg_screen[id][i] = 0x00
end
end

function clear_sprite_tiles()
sprite_tiles = {}
for i = 0, (SPRITE_TILES *64) -1 do
sprite_tile[i] = 0xFE
end
end

function clear_all_window_screens()
clear_textbox()
for i = 0, 3 do
clear_window_screen(i)
end
end

function clear_all_bg_screens()
for i = 0, 3 do
clear_bg_screen(i)
end
end

function clear_screen_areas()
clear_all_bg_screens()
clear_all_window_screens()
end

function clear_windows_and_screen_areas()
clear_screen_areas()
text_window = {}
end

function clear_vram()
clear_all_bg_screens()
clear_all_window_screens()
clear_sprite_tiles()
end

function clear_all_graphics()
clear_windows_and_screen_areas()
clear_sprite_tiles()
end

function get_bg_screen()
local screen = {}
for i = 0, (SCREEN_PIXELS /32)-1 do
screen[i] = 0x00
end
local bgs = sort_bgs()
for i = 4, 1, -1 do
local current = bgs[i]
local hidden_bg = get_hidden_bg()
if not hidden_bg or hidden_bg ~= current then
local left, top = get_screen_starting_position(current, false)
for y = 0, (SCREEN_HEIGHT /8) -1 do
for x = 0, (SCREEN_WIDTH /4) -1 do
local value = bg_screen[current][(top +y) *BG_WIDTH /4 +left +x]
if value and value ~= 0x00 then
screen[y *SCREEN_WIDTH /4 +x] = value
end
end
end
end
end
local tile_lines = {}
for i = 0, (SCREEN_PIXELS /32) -1, SCREEN_WIDTH / 4 do
local tile_line = ""
local j = 0
while j < SCREEN_WIDTH/4 do
tile_line = tile_line .. string.char(screen[i+j])
j = j + 1
end
table.insert(tile_lines, tile_line)
end -- i
return tile_lines
end

function get_window_screen()
local screen = {}
for i = 0, SCREEN_PIXELS-1 do
screen[i] = 0xFF
end

local bgs = sort_bgs()
local last_sprite = MAX_SPRITES -1
for i = 4, 1, -1 do
local current = bgs[i]
local hidden_bg = get_hidden_bg()
if not hidden_bg or hidden_bg ~= current then
local left, top = get_screen_starting_position(current)
for y = 0, SCREEN_HEIGHT -1 do
for x = 0, SCREEN_WIDTH -1 do
local value = window_screen[current][(top +y) *BG_WIDTH +left +x]
if value and value ~= 0xFE then
screen[y *SCREEN_WIDTH +x] = value
end
end
end
end
last_sprite = animate_sprites(last_sprite, get_bg_priority(current), screen)
end
local lines = {}
local tile_lines = {}
for i = 0, SCREEN_PIXELS-1, SCREEN_WIDTH do
local line = ""
local tile_line = ""
local empty_pixels = 0
local j = 0
while j < SCREEN_WIDTH do
local char = screen[i+j]
if char ~= 0xFF then
empty_pixels = 0
if char > 0xFF then
tile_line = tile_line .. string.char(bit.rshift(char, 8)) .. string.char(char % 0x100)
else
tile_line = tile_line .. string.char(char)
end
line = line .. translate(char)
else
tile_line = tile_line .. string.char(char)
empty_pixels = empty_pixels + 1
if empty_pixels == 8 then
line = line .. " "
empty_pixels = 0
end
end
j = j + 1
end
table.insert(lines, line)
table.insert(tile_lines, tile_line)
end -- i
return {lines=lines, tile_lines=tile_lines, get_textbox=get_textbox}
end

function translate_tileline(tileline)
local l = ""
local empty_pixels = 0
local i = 1
while i <= #tileline do
local char = tileline:sub(i, i):byte()
if char ~= 0xFE and char ~= 0xFF then
if char > 0xF7 then
i = i + 1
char = char * 0x100 + tileline:sub(i, i):byte()
end
empty_pixels = 0
l = l .. translate(char)
else
empty_pixels = empty_pixels + 1
if empty_pixels == 8 then
l = l .. " "
empty_pixels = 0
end
end
i = i + 1
end
return trim(l)
end

function read_window(window, from_screen)
local tilelines
if from_screen then
tilelines = get_window_tilelines_from_screen(window)
else
tilelines = get_window_tilelines(window)
end
for _, tileline in pairs(tilelines) do
local line = translate_tileline(tileline)
if line ~= "" then
tolk.output(line)
end
end
end

function read_menu_item(grid)
local window = memory.getregister("r0")
if not text_window[window] or window >= MAX_WINDOWS then
return
end
local left = memory.getregister("r3")
local position = memory.readword(memory.getregister("r13")) +9
local tiles = get_window_tilelines(get_window(window))
if tiles[position] then
local item = ""
if grid then
local width = memory.readbyte(RAM_MENU + 7)
item = translate_tileline(tiles[position]:sub(left, left + width - 1))
else
item = translate_tileline(tiles[position]:sub(left))
end
tolk.output(item)
end
end

function read_mainmenu_item()
local position = memory.getregister("r2") / 0x100
local lines = get_window_screen().lines
tolk.output(lines[position + 19])
end

function read_list_menu_item()
local window = memory.getregister("r0")
if not text_window[window] then
return
end
local left = memory.getregister("r2")
local top = memory.getregister("r3") +9
local tiles = get_window_tilelines(get_window(window))
if tiles[top] then
tolk.output(translate_tileline(tiles[top]:sub(left)))
end
end

function draw_menu_cursor()
read_menu_item(false)
end

function draw_grid_menu_cursor()
read_menu_item(true)
end

function draw_list_menu_cursor()
if memory.readdword(memory.getregister("r13") + 0x10) == ROM_LIST_CURSOR_TILE then
read_list_menu_item()
end
end

function read_option_menu_item()
local top = memory.getregister("r2")
local lines = get_window_screen().lines
option_menu_pos = top +9
last_selected_option = trim(lines[option_menu_pos])
tolk.output(last_selected_option)
end

function read_battle_menu_item()
local lines = get_window_tilelines(get_window(2))
local option = memory.getregister("r0")
local startpos, endpos
if option % 2 == 0 then
startpos = 1
endpos = 56
else
startpos = 57
endpos = 96
end
if option > 1 then
option = 2
else
option = 0
end
local position = 11 + option*8
if lines[position] then
tolk.output(translate_tileline(lines[position]:sub(startpos, endpos)))
end
end

function read_battle_yesno()
local window = 14
if not text_window[window] then
return
end
local position = (memory.getregister("r3") -9) *8 +11
local tiles = get_window_tilelines(get_window(window))
if tiles[position] then
tolk.output(translate_tileline(tiles[position]))
end
end

function read_battle_move_menu_item()
local move = memory.getregister("r0")
local lines = get_window_tilelines(get_window(move + 3))
local top = 10
if lines[top] then
tolk.output(translate_tileline(lines[top]))
end
end

function read_target_menu_item()
local name = get_in_doubles(memory.readdword(memory.getregister("r0")))
if name then
tolk.output(name)
end
end

function read_pkmn_menu_item()
local id = memory.getregister("r0")
if not text_window[id] then
return
end
if memory.getregister("r1") == 1 then
read_window(get_window(id), true)
end
end

function read_how_many()
tolk.output(tostring(memory.getregister("r1")))
end

function read_tm_case_info()
local lines = get_window_screen().tile_lines
if lines[113] then
local type = translate_tileline(lines[113])
if type ~= "" then
tolk.output(type)
end
end
if lines[125] then
local power = translate_tileline(lines[125])
if power ~= "" then
tolk.output(power)
end
end
if lines[137] then
local accuracy = translate_tileline(lines[137])
if accuracy ~= "" then
tolk.output(accuracy)
end
end
if lines[149] then
pp = translate_tileline(lines[149])
if pp ~= "" then
tolk.output(pp)
end
end
end

function read_move_menu_item()
local move = memory.readbyte(RAM_SELECTED_MOVE)
local lines = get_window_tilelines(get_window(3))
local index = 14 +28 *move
if lines[index] then
tolk.output(translate_tileline(lines[index]))
local pp = index +11
if lines[pp] then
pp = translate_tileline(lines[index +11])
if pp ~= "" then
tolk.output(pp)
end
end
lines = get_window_tilelines(get_window(4))
if lines[10] then
local power = translate_tileline(lines[10])
if power ~= "" then
tolk.output(string.format(message.translate("power") .. " %s", power))
end
end
if lines[24] then
local accuracy = translate_tileline(lines[24])
if accuracy ~= "" then
tolk.output(string.format(message.translate("accuracy") .. " %s", accuracy))
end
end
end
end

function read_deposit_box()
local lines = get_window_screen().lines
if trim(lines[19]) ~= "" then
tolk.output(trim(lines[19]))
tolk.output(trim(lines[35]))
elseif trim(lines[83]) ~= "" then
tolk.output(trim(lines[83]))
tolk.output(trim(lines[99]))
end
end

function read_pc_pokemon()
read_window(get_window(0))
end

function get_in_doubles(id)
local lines = get_window_screen().lines
local line = ""
for _, v in pairs(DOUBLE_COORDS[id]) do
if trim(line) == "" then
line = lines[v]
end
end
if line:match(translate(0xF905)) then
return trim(line:sub(1, line:find(translate(0xF905)) -1))
end
return nil
end

function handle_fake_textbox()
if check_window_present(WINDOW_BATTLE) then
if not window_is_empty(get_window(0)) then
set_fake_textbox(15)
else
local x, y = get_screen_starting_position(0)
if y < 320 then
set_fake_textbox(15, 1, 15)
else
fake_textbox = nil
end
end
elseif check_window_present(WINDOW_BAG) or check_window_present(WINDOW_PC_BAG) or check_window_present(WINDOW_PC_BAG_WITHDRAW) then
set_fake_textbox(13)
elseif check_window_present(WINDOW_MOVE_LIST, 3) then
set_fake_textbox(11, 0, 15)
elseif check_window_present(WINDOW_TM_CASE) then
if not window_is_empty(get_window(6)) then
set_fake_textbox(14)
else
set_fake_textbox(11, 12, 30)
end
elseif check_window_present(WINDOW_NEWGAME_HELP1, 2) then
set_fake_textbox(6)
elseif check_window_present(WINDOW_NEWGAME_HELP2, 2) or check_window_present(WINDOW_NEWGAME_HELP3, 2) then
set_fake_textbox(2)
elseif check_window_present(WINDOW_NEWGAME_INTRO, 2, 1) then
set_fake_textbox(3)
elseif check_window_present(WINDOW_TV) then
set_fake_textbox(14)
else
fake_textbox = nil
end
end

function render_text()
local func_address = memory.getregister("r15")
local current_char = memory.getregister("r3")
if current_char < 0xFA then
baseOffset = memory.getregister("r6")
local window = get_window_header(memory.readbyte(baseOffset+4))
if not text_window[window.id] then
text_window[window.id] = clear_window(get_window(window.id))
end
local char_x = memory.readbyte(baseOffset+8)
local char_y = memory.readbyte(baseOffset+9) +8
if func_address == ROM_RENDER_BRAILLE_TEXT + 2 then
text_window[window.id][char_y*window.width+char_x] = bit.bor(current_char, 0xFA00)
else
text_window[window.id][char_y*window.width+char_x] = current_char
end
if current_char > 0xF7 then
text_window[window.id][char_y*window.width+char_x] = current_char *0x100 +memory.readbyte(memory.getregister("r0") + 1)
end
unread_text = true
elseif current_char == 0xFA
or current_char == 0xFB
or (current_char == 0xFC and memory.readbyte(memory.getregister("r0") + 1) == 9)
or current_char == 0xFF then
if unread_text then
want_read = true
unread_text = false
end
end
end

function clear_textbox()
last_line = ""
last_textbox_text = nil
end

function set_fake_textbox(line, left, right)
fake_textbox = {
line = line,
left = left,
right = right
}
end

function format_names(name)
if name:match("[player]") then
name = string.gsub(name, "%[player]", get_custom_name(memory.readdword(RAM_SAVEBLOCK2_POINTER) + RAM_PLAYER_NAME))
end
if name:match("[rival]") then
name = string.gsub(name, "%[rival]", get_custom_name(memory.readdword(RAM_SAVEBLOCK1_POINTER) + RAM_RIVAL_NAME))
end
return name
end

function is_warp_tile(tile)
if (tile >= 0x60 and tile <= 0x65)
or tile == 0x67
or (tile >= 0x69 and tile <= 0x6F)
or tile == 0x71 then
return true
end
return false
end

function is_hole(tile)
if tile == 0x29
or tile == 0x66
or tile == 0x68 then
return true
end
return false
end

function get_warps()
local current_mapid = get_map_id()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local warps = memory.readbyte(eventstart+1)
local types = get_blocks_type()
local results = {}
local ptr = memory.readdword(eventstart+8)
for i = 1, warps do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
if is_warp_tile(types[y][x]) then
local mapid = memory.readbyte(ptr + 7)*256+memory.readbyte(ptr + 6)
local name = "Warp " .. i
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=x, y=y, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
elseif is_hole(types[y][x]) then
table.insert(results, {name=message.translate("hole"), x=x, y=y, id="hole_" .. y .. x, type="object"})
end
end
ptr = ptr + 8
end
return results
end

function get_signposts()
local mapid = get_map_id()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local signposts = memory.readbyte(eventstart+3)
-- read out the signposts
local results = {}
local ptr = memory.readdword(eventstart+16)
for i = 1, signposts do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
local name = "signpost " .. i
local post = {x=x, y=y, name=name, type="signpost", id="signpost_" .. i}
post.name = get_name(mapid, post)
table.insert(results, post)
end
ptr = ptr + 12
end
return results
end

function get_objects()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local objects = memory.readbyte(eventstart)
local mapid = get_map_id()
local ptr = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_MAP_OBJECTS
local results = {}
for i = 1, objects do
local vissible = true
local flag = memory.readword(ptr+20), 0x3FFF
if flag ~= 0 then
vissible = not get_flag(flag)
end
if vissible then
local id = memory.readbyte(ptr)
local sprite = memory.readbyte(ptr+1)
local x = memory.readword(ptr+4)
local y = memory.readword(ptr+6)
if check_coordinates_on_screen(x, y) then
if sprite > 0xef then
sprite = get_var(sprite + 0x3f20)
end
local name = message.translate("object") .. i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
local object = {x=x, y=y, id_map=id, sprite=sprite, name=name, type="object", id="object_" .. i}
object.name = get_name(mapid, object)
table.insert(results, object)
end
end
ptr = ptr + 24
end
objects = #results
ptr = RAM_LIVE_OBJECTS + 36
for i = 1, 15 do
local active = bit.band(memory.readbyte(ptr), 1)
local id = memory.readbyte(ptr +8)
if active ~= 0 and id ~= 0xFF then
local sprite = memory.readbyte(ptr +5)
local map = memory.readbyte(ptr + 10) * 256 + memory.readbyte(ptr + 9)
local x = memory.readword(ptr + 16) - 7
local y = memory.readword(ptr + 18) - 7
local facing = bit.band(memory.readbyte(ptr + 24), 0xf)
local already_present = false
for j = 1, objects do
local obj = results[j]
if id == obj.id_map and sprite == obj.sprite and map == mapid then
obj.x = x
obj.y = y
obj.facing = facing
already_present = true
break
end
end
if not already_present and map == mapid then
local name = message.translate("object") .. objects +i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
local object = {x=x, y=y, facing=facing, sprite=sprite, name=name, type="object", id="object_" .. objects +i}
object.name = get_name(mapid, object)
table.insert(results, object)
end
end
ptr = ptr + 36
end
local types = get_blocks_type()
for y = 0, #types - 7 do
for x = 0, #types[0] - 8 do
if types[y][x] == 0x83 then
table.insert(results, {name=message.translate("pc"), x=x, y=y, id="pc_" .. y .. x, type="object"})
elseif types[y][x] == 0x26 then
table.insert(results, {name=message.translate("thin_ice"), x=x, y=y, id="ice_" .. y .. x, type="object", ignorable=true})
elseif types[y][x] == 0x27 then
table.insert(results, {name=message.translate("cracked_ice"), x=x, y=y, id="ice_" .. y .. x, type="object"})
elseif types[y][x] == 0x20 then
table.insert(results, {name=message.translate("switch"), x=x, y=y, id="switch_" .. y .. x, type="object", ignorable=true})
end
end
end
return results
end

function get_connections()
local results = {}
local current_mapid = get_map_id()
local header = memory.readdword(RAM_MAP_CONNECTION_HEADER_POINTER)
if header == 0 then
return results
end
local connections = memory.readword(header)
local ptr = memory.readdword(header+4)
for i = 1, connections do
local dir = memory.readbyte(ptr)
local offset = memory.readdwordsigned(ptr + 4)
local mapid = memory.readbyte(ptr + 8)*256+memory.readbyte(ptr + 9)
local name = message.translate("connection_to", message.translate(connection_point[dir]))
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = name .. ", " .. mapname
end
table.insert(results, {type="connection", direction=connection_point[dir], offset = offset, map = mapid, name=name, x=x, y=y, id="connection_" .. dir})
ptr = ptr + 12
end
return results
end

function get_connection_limits(connection)
local width, height = get_map_dimensions()
local connected_width, connected_height = get_map_dimensions(get_connected_map_header_pointer(connection))
local start = connection.offset
if start < 0 then
start = 0
end

local map_size, connected_size
if connection.direction == "north" or connection.direction == "south" then
map_size = width
connected_size = connected_width
elseif connection.direction == "east" or connection.direction == "west" then
map_size = height
connected_size = connected_height
end
connected_size = connected_size + connection.offset

local size = get_lesser(map_size, connected_size)
while (size + start) > map_size or size > connected_size do
size = size -1
end
size = size + start

local start_x, start_y, end_x, end_y
if connection.direction == "north" then
start_x = start
start_y = 0
end_x = size -1
end_y = 0
elseif connection.direction == "south" then
start_x = start
start_y = height -1
end_x = size -1
end_y = height -1
elseif connection.direction == "east" then
start_x = width -1
start_y = start
end_x = width - 1
end_y = size -1
elseif connection.direction == "west" then
start_x = 0
start_y = start
end_x = 0
end_y = size -1
end

return {
start_x = start_x,
start_y = start_y,
end_x = end_x,
end_y = end_y}
end

function get_map_id()
local group = memory.readbyte(memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_MAP_GROUP)
local number = memory.readbyte(memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_MAP_NUMBER)
return group*256+number
end

function on_map()
if in_battle() or memory.readdword(RAM_CALLBACK1) ~= ROM_CB_OVERWORLD or memory.readdword(RAM_CALLBACK2) ~= ROM_CB_OVERWORLD_BASIC then
return false
else
return true
end
end

function get_player_xy()
return memory.readword(memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_PLAYER_X), memory.readword(memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_PLAYER_Y)
end

function get_map_dimensions(address)
if not address then
address = RAM_MAP_HEADER_POINTER
end

return memory.readdword(memory.readdword(address) + RAM_MAP_WIDTH), memory.readdword(memory.readdword(address) + 	RAM_MAP_HEIGHT)
end

function get_connected_map_header_pointer(connection)
local block = bit.rshift(connection.map, 8)
local number = bit.band(connection.map, 0xFF)

return memory.readdword(memory.readdword(ROM_MAP_GROUPS + block * 4) + number * 4)
end

function play_tile_sound(type, pan, vol, is_camera)
if is_grass(type) then
audio.play(scriptpath .. "sounds\\gba\\s_grass.wav", 0, pan, vol)
elseif is_waterfall(type) then
audio.play(scriptpath .. "sounds\\common\\s_waterfall.wav", 0, pan, vol)
elseif is_water(type, false) then
audio.play(scriptpath .. "sounds\\common\\s_water.wav", 0, pan, vol)
elseif is_camera and type == 0x20 then
audio.play(scriptpath .. "sounds\\common\\s_switch.wav", 0, -100, vol)
elseif type == 0x23 then
audio.play(scriptpath .. "sounds\\common\\s_ice.wav", 0, pan, vol)
elseif type == 0x26 then
audio.play(scriptpath .. "sounds\\gba\\s_thin_ice.wav", 0, pan, vol)
elseif type == 0x27 then
if is_camera then
audio.play(scriptpath .. "sounds\\gba\\s_cracked_ice.wav", 0, pan, vol)
else
audio.play(scriptpath .. "sounds\\gba\\s_thin_ice.wav", 0, pan, vol)
end
elseif type == 0x54 then
audio.play(scriptpath .. "sounds\\common\\s_move.wav", 0, 100, vol)
elseif type == 0x55 then
audio.play(scriptpath .. "sounds\\common\\s_move.wav", 0, -100, vol)
elseif type == 0x56 then
audio.play(scriptpath .. "sounds\\common\\s_move_up.wav", 0, pan, vol)
elseif type == 0x57 then
audio.play(scriptpath .. "sounds\\common\\s_move_down.wav", 0, pan, vol)
elseif is_camera and type == 0x58 then
audio.play(scriptpath .. "sounds\\common\\no_pass.wav", 0, pan, vol)
elseif is_camera and type == 0x62 then
audio.play(scriptpath .. "sounds\\common\\s_stair.wav", 0, 100, vol)
elseif is_camera and type == 0x63 then
audio.play(scriptpath .. "sounds\\common\\s_stair.wav", 0, -100, vol)
elseif is_camera and type == 0x64 then
audio.play(scriptpath .. "sounds\\gba\\s_stairnorth.wav", 0, pan, vol)
elseif is_camera and type == 0x65 then
audio.play(scriptpath .. "sounds\\gba\\s_stairsouth.wav", 0, pan, vol)
elseif is_camera and type == 0x66 then
audio.play(scriptpath .. "sounds\\common\\s_hole.wav", 0, pan, vol)
elseif type == 0x6A then
audio.play(scriptpath .. "sounds\\common\\s_stairup.wav", 0, pan, vol)
elseif type == 0x6B then
audio.play(scriptpath .. "sounds\\common\\s_stairdown.wav", 0, pan, vol)
elseif type == 0x6C then
audio.play(scriptpath .. "sounds\\common\\s_stairup.wav", 0, 100, vol)
elseif type == 0x6D then
audio.play(scriptpath .. "sounds\\common\\s_stairup.wav", 0, -100, vol)
elseif type == 0x6E then
audio.play(scriptpath .. "sounds\\common\\s_stairdown.wav", 0, 100, vol)
elseif type == 0x6F then
audio.play(scriptpath .. "sounds\\common\\s_stairdown.wav", 0, -100, vol)
else
audio.play(scriptpath .. "sounds\\gba\\s_default.wav", 0, pan, vol)
end
local x, y = nil
if is_camera then
x, y = get_camera_xy()
else
x, y = get_player_xy()
end

if check_preledge(get_blocks_type(), y, x) then
audio.play(scriptpath .. "sounds\\common\\s_mad.wav", 0, pan, vol)
end
end

function is_elevation_mismatch(current, next)
if current == 0 or next == 0 or next == 0xF then
return false
end

return current ~= next
end

function can_surf(type, elevation)
if is_water(type) and elevation == 3 then
return true;
end
return false
end

function is_grass(type)
if type == 0x02 or type == 0xD1 then
return true
end
return false
end

function is_water(type, surfing_water)
if surfing_water == nil then
surfing_water = true
end

if surfing_water and type == 0x11 then
return false
end

if (type >= 0x10 and type <= 0x15)
or (type == 0x1A or type == 0x1B)
or (type >= 0x50 and type <= 0x53) then
return true
end
return false
end

function is_waterfall(type)
if type == 0x13 then
return true
end
return false
end

function is_hm(type)
return is_water(type) or is_waterfall(type)
end

function is_allowed_hm(type)
if pathfind_hm_available then
if is_water(type) then
return has_badge(BADGE_SURF)
elseif is_waterfall(type) then
return has_badge(BADGE_WATERFALL)
end
end

return pathfind_hm_all
end

function get_hm_command(node, last)
local command = ""
local count = true
if is_waterfall(node.type) then
if is_waterfall(last.type) then
command = "$ignore"
else
command = message.translate("waterfall")
end
elseif is_water(node.type) and is_waterfall(last.type) then
command = "$ignore"
elseif is_elevation_mismatch(node.elevation, last.elevation) and can_surf(node.type, last.elevation) then
command = message.translate("enter_water")
count = false
elseif is_elevation_mismatch(node.elevation, last.elevation) and can_surf(last.type, node.elevation) then
command = message.translate("exit_water")
count = false
end
return command, count
end

function get_flag(index)
local flags_addres
if index < SPECIAL_FLAGS_START then
flags_address = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_FLAGS
else
flags_address = RAM_SPECIAL_FLAGS
index = index - SPECIAL_FLAGS_START
end
local flag = index % 8
local flag_byte = memory.readbyte(flags_address + bit.rshift(index, 3))
return hasbit(flag_byte, flag)
end

function get_var(index)
local var_address
if index < VARS_START then
return 0
elseif index < SPECIAL_VARS_START then
var_address = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_VARS + (index -VARS_START) * 2
else
var_address = memory.readdword(ROM_SPECIAL_VARS + (index - SPECIAL_VARS_START) * 4)
end
return memory.readword(var_address)
end

function in_options_menu()
if check_window_present(WINDOW_OPTIONS) then
return true
end
return false
end

function handle_options_menu()
if last_selected_option then
local lines = get_window_screen().lines
local selected_option = trim(lines[option_menu_pos])
if selected_option ~= last_selected_option and selected_option ~= "" then
tolk.output(selected_option)
last_selected_option = selected_option
end
end
end

function keyboard_showing()
if check_window_present(WINDOW_KEYBOARD, 1) then
return true
end
return false
end

function handle_keyboard()
local cursor_sprite = memory.readbyte(memory.readdword(RAM_NAMING_DATA_POINTER) + 0x1E23)
local data = RAM_SPRITES + 0x44 * cursor_sprite
local col = memory.readbyte(data + 0x2E)
local row = memory.readbyte(data + 0x30)
if col ~= old_kbd_col or row ~= old_kbd_row then
read_keyboard(col, row)
old_kbd_col = col
old_kbd_row = row
end
end

function read_keyboard(x, y)
local current_page = memory.readbyte(memory.readdword(RAM_NAMING_DATA_POINTER) + 0x1E22)
local page_order = memory.readbyte(ROM_LETTER_PAGES + current_page)
local num_columns = memory.readbyte(ROM_PAGE_COLUMNS + page_order)
if x < num_columns then
local letter = memory.readbyte(ROM_LETTER_LIST + page_order * 32 + y * 8 + x)
tolk.output(translate(letter))
else
tolk.output(message.translate(KEYBOARD_KEYS[y]))
end
end

function handle_special_cases()
if keyboard_showing() then
handle_keyboard()
else
old_kbd_col = nil
old_kbd_row = nil
end
if in_options_menu() then
handle_options_menu()
else
option_menu_pos = nil
last_selected_option = nil
end
handle_fake_textbox()
end

function register_callbacks(functions)
for address, func in pairs(functions) do
memory.registerexec(address, func)
table.insert(callback_functions, address)
end
end

function read_mapname_if_needed()
local heading = get_bg_screen()[3]
if heading:find(MAPNAME_PATTERN:sub(1,6))
or heading:find(MAPNAME_PATTERN:sub(#MAPNAME_PATTERN-5,#MAPNAME_PATTERN)) then
local line = translate_tileline(get_window_screen().tile_lines[11])
if line ~= "" then
tolk.output(line)
end
else
if check_window_present(WINDOW_MAP) then
local line = translate_tileline(get_window_screen().tile_lines[27])
if line ~= "" then
tolk.output(line)
end
end
end
end

function read_text(auto)
if auto then
local textbox = get_textbox()
if textbox ~= nil then
if #textbox > 1 then
if textbox[1] == last_line then
textbox[1] = ""
end
end
last_line = textbox[#textbox]
textbox_text = table.concat(textbox, "")
if textbox_text ~= last_textbox_text then
output_textbox(textbox)
end
last_textbox_text = textbox_text
end -- textbox
else
output_lines()
end
end

function output_lines()
local lines = get_window_screen().lines
for _, line in pairs(lines) do
line = trim(line)
if line ~= "" then
tolk.output(line)
end
end
end

function read_tiles()
local player_x, player_y = get_player_xy()
local types = get_blocks_type()
local elevations = get_blocks_elevation()
local s = message.translate("now_on") .. string.format("%d (%d); ", types[player_y][player_x], elevations[player_y][player_x])

-- Check up tile
if player_y >= 0 then
s = s .. message.translate("up") .. string.format("%d, ", types[player_y - 1][player_x])
end -- Check up tile

-- Check down tile
if player_y <= #types then
s = s .. message.translate("down") .. string.format("%d, ", types[player_y + 1][player_x])
end -- Check down tile

-- Check left tile
if player_x >= 0 then
s = s .. message.translate("left") .. string.format("%d, ", types[player_y][player_x - 1])
end -- Check left tile

-- Check right tile
if player_x <= #types[0] then
s = s .. message.translate("right") .. string.format("%d", types[player_y][player_x + 1])
end -- Check right tile

tolk.output(s)
end

function check_coordinates_on_screen(x, y)
local width, height = get_map_dimensions()
if x >= 0 and y >= 0
and x <= width -1 and y <= height -1 then
return true
end
return false
end

function camera_move(y, x, ignore_wall)
local player_x, player_y = get_player_xy()
reset_camera_focus(player_x, player_y)
camera_y = camera_y + y
camera_x = camera_x + x

local blocks = get_map_blocks()
local pan = (camera_x - player_x) * 5
local vol = 40 - math.abs(player_y - camera_y)

-- clipping pan and volume
if pan > 100 then
vol = vol - ((pan / 5) - 20)
pan = 100
end
if pan < -100 then
vol = vol - math.abs((pan / 5) - 20)
pan = -100
end
if vol < 5 then
vol = 5
end

if camera_y >= -7 and camera_x >= -7 and camera_y <= #blocks and camera_x <= #blocks[1] then
local objects = get_objects()
for i, obj in pairs(objects) do
if obj.x == camera_x and obj.y == camera_y then
if obj.sprite == BOULDER_SPRITE then
audio.play(scriptpath .. "sounds\\gba\\s_boulder.wav", 0, pan, vol)
end -- sprite_id
end -- obj.xy
end

if is_collision(true, blocks[camera_y -y][camera_x -x], blocks[camera_y][camera_x]) then
if ignore_wall then
camera_x = camera_x - x
camera_y = camera_y - y
end
audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
else
audio.play(scriptpath .. "sounds\\common\\pass.wav", 0, pan, vol)
play_tile_sound(get_block_type(blocks[camera_y][camera_x]), pan, vol, true)
end
else
camera_x = camera_x - x
camera_y = camera_y - y
audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
end
end

function is_collision(is_block, current, next)
if is_block then
current_impassable = get_block_impassable(current)
current_type = get_block_type(current)
current_elevation = get_block_elevation(current)
if next ~= nil then
next_impassable = get_block_impassable(next)
next_type = get_block_type(next)
next_elevation = get_block_elevation(next)
end
else
current_impassable = current.impassable
current_type = current.type
current_elevation = current.elevation
if next ~= nil then
next_impassable = next.impassable
next_type = next.type
next_elevation = next.elevation
end
end

if next == nil then
return current_impassable
end

return next_impassable
or is_elevation_mismatch(current_elevation, next_elevation)
-- and not can_surf(current_type, next_elevation)
-- and not can_surf(next_type, current_elevation))
end

function has_badge(badge)
if badge == 0 then
return true
end

local badge_flag = BADGES_START + (badge -1)
return get_flag(badge_flag)
end

function get_map_blocks()
local width, height = get_map_dimensions()
local row_width = width + 15
ptr = memory.readdword(RAM_SAVEBLOCK1_POINTER +RAM_MAP_BLOCKS) -- start of overworld
local blocks = {}
for y = -7, height + 6 do
for x = -7, width + 7 do
local block = memory.readword(ptr+((y+7)*(row_width*2))+((x+7)*2))
blocks[y] = blocks[y] or {}
blocks[y][x] = block
end
end
return blocks
end

function get_block_attribute(block, attribute, bit_shift)
block = bit.band(block, 0x3FF)

local map_header = memory.readdword(RAM_MAP_HEADER_POINTER)
local tileset = 0
if block < PRIMARY_METATILES then
tileset = memory.readdword(map_header + RAM_MAP_PRIMARY_TILESET)
else
tileset = memory.readdword(map_header + RAM_MAP_SECONDARY_TILESET)
block = block - PRIMARY_METATILES
end

local attributes = memory.readdword(tileset + 20)
return bit.rshift(bit.band(memory.readdword(attributes + block * 4), attribute), bit_shift)
end

function get_block_type(block)
return get_block_attribute(block, 0x1FF, 0)
end

function get_block_impassable(block)
if block == 0x3FF then
return true
end

local impassable = bit.rshift(bit.band(block, 0xC00), 10) ~= 0
if not impassable then
local type = get_block_type(block)
if is_hm(type) then
impassable = not is_allowed_hm(type)
end
end

return impassable
end

function get_block_elevation(block)
return bit.rshift(block, 12)
end

function get_blocks_data(func, blocks)
if blocks == nil then
blocks = get_map_blocks()
end
local results = {}
for y = -7, #blocks do
for x = -7, #blocks[y] do
local data = func(blocks[y][x])
results[y] = results[y] or {}
results[y][x] = data
end
end
return results
end

function get_blocks_type(blocks)
return get_blocks_data(get_block_type, blocks)
end

function get_blocks_impassable(blocks)
return get_blocks_data(get_block_impassable, blocks)
end

function get_blocks_elevation(blocks)
return get_blocks_data(get_block_elevation, blocks)
end

function is_posible_connection(blocks, x, y, dir)
local dir_x, dir_y = decode_direction(dir)
if not is_collision(true, blocks[y + dir_y][x + dir_x]) then
return true
end
return false
end

function find_path_to(obj)
local path
local width, height = get_map_dimensions()

if obj.type == "connection" then
local blocks = get_map_blocks()
local results = get_connection_limits(obj)
if obj.direction == "north" then
dir = UP
elseif obj.direction == "south" then
dir = DOWN
elseif obj.direction == "east" then
dir = RIGHT
elseif obj.direction == "west" then
dir = LEFT
end
local found = false
for dest_y = results.start_y, results.end_y do
for dest_x = results.start_x, results.end_x do
if not is_collision(true, blocks[dest_y][dest_x]) and is_posible_connection(blocks, dest_x, dest_y, dir) then
if not found then
path = find_path_to_xy(dest_x, dest_y)
end
found = true
else
found = false
end
if path ~= nil then
break
end
end
if path ~= nil then
break
end
end
else
path = find_path_to_xy(obj.x, obj.y)
end
if path == nil then
tolk.output(message.translate("no_path"))
return
end
speak_path(clean_path(path))
end

function has_talking_over_around(value, dir)
if hasbit(value, (dir -1)) then
return true
end
return false
end

function find_path_to_xy(dest_x, dest_y)
local player_x, player_y = get_player_xy()
local blocks = get_map_blocks()
local allnodes = {}
local height = #blocks - 7
local width = #blocks[0] - 8
local start = nil
local dest = nil
-- set all objects to impassable tiles
-- 0x3ff is the undefined tile, so it won't ever be a passable tile
for i, object in ipairs(get_objects()) do
if not object.ignorable then
blocks[object.y][object.x] = 0x3FF
end
end
for i, warp in ipairs(get_warps()) do
if (warp.x ~= player_x or warp.y ~= player_y)
and (warp.x ~= dest_x or warp.y ~= dest_y) then
blocks[warp.y][warp.x] = 0x3FF
end
end
local types = get_blocks_type(blocks)
local elevations = get_blocks_elevation(blocks)
local impassables = get_blocks_impassable(blocks)

-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = 0, height do
for x = 0, width do
local n = {x=x, y=y, type=types[y][x], elevation=elevations[y][x], impassable=impassables[y][x], special_tiles=get_special_tiles_around(types, y, x)}
if x == player_x and y == player_y then
start = n
end
if x == dest_x and y == dest_y then
n.is_dest = true
dest = n
end
table.insert(allnodes, n)
end -- x
end -- y
path = astar.path(start, dest, allnodes, true, valid_path)
return path
end

function get_opposite_direction(x, y)
return x * (-1), y * (-1)
end

function is_wall(tile, dir)
if tile < 0x30 or tile > 0x37 then
return false
end
if dir == RIGHT
and (tile == 0x30 or tile == 0x34 or tile == 0x36) then
return true
elseif dir == LEFT
and (tile == 0x31 or tile == 0x35 or tile == 0x37) then
return true
elseif dir == UP
and (tile == 0x32 or tile == 0x34 or tile == 0x35) then
return true
elseif dir == DOWN
and (tile == 0x33 or tile == 0x36 or tile == 0x37) then
return true
end
return false
end

function check_wall(current, next, x, y)
if is_wall(current, encode_direction(x, y)) or is_wall(next, encode_direction(get_opposite_direction(x, y))) then
return true
end
return false
end

function jump_ledge(tile, x, y)
if tile < 0x38 or tile > 0x3F then
return false
end
if y == 0 then
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

function check_preledge(types, y, x)
if bit.rshift(get_special_tiles_around(types, y, x), 4) ~= 0 then
return true
end
return false
end

function get_special_tiles_around(types, y, x)
local result = 0
for dir = DOWN, RIGHT do
local dir_x, dir_y = decode_direction(dir)
dir_x = x + dir_x
dir_y = y + dir_y
if check_coordinates_on_screen(dir_x, dir_y) then
if check_talking_over(types[dir_y][dir_x]) then
result = result + bit.lshift(1, (dir -1))
end
if jump_ledge(types[dir_y][dir_x], decode_direction(dir)) then
result = result + bit.lshift(1, (dir -1) + 4)
end
end
end
return result
end

function check_talking_over(tile)
if tile == 0x80 then
return true
end
return false
end

function valid_path(node, neighbor)
for dir = DOWN, RIGHT do
local dir_x, dir_y = decode_direction(dir)
dir_x = dir_x + dir_x
dir_y = dir_y + dir_y
if (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y)
and ((has_talking_over_around(node.special_tiles, dir) and neighbor.is_dest)) then
return true
end
end
if check_wall(node.type, neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return false
elseif jump_ledge(node.type, neighbor.x - node.x, neighbor.y - node.y)
or jump_ledge(neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return true
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif neighbor.is_dest then
return true
elseif is_collision(false, node, neighbor) then
return false
end
return true
end

function get_enemy_health()
local lines = get_window_screen().lines
if lines[26]:match(translate(0xF905)) then
local current = memory.readword(RAM_CURRENT_ENEMY_HEALTH)
local total = memory.readword(RAM_MAX_ENEMY_HEALTH)
return string.format("%0.2f%%", current/total*100)
else
local output_hp = ""
-- check double battles
local name = get_in_doubles(1)
if name ~= nil then
output_hp = output_hp .. name
local current = memory.readword(RAM_CURRENT_ENEMY_HEALTH)
local total = memory.readword(RAM_MAX_ENEMY_HEALTH)
output_hp = output_hp .. string.format(" %0.2f%%; ", current/total*100)
end
name = get_in_doubles(3)
if name ~= nil then
output_hp = output_hp .. name
local current = memory.readword(RAM_CURRENT_ENEMY_HEALTH +0xB0)
local total = memory.readword(RAM_MAX_ENEMY_HEALTH +0xB0)
output_hp = output_hp .. string.format(" %0.2f%%; ", current/total*100)
end
return output_hp
end
end

function get_player_health()
local lines = get_window_screen().lines
if lines[102]:match("/") then
return trim(lines[102])
elseif lines[103]:match("/") then
return trim(lines[103])
else
local output_hp = ""
-- check double battles
local name = get_in_doubles(0)
if name ~= nil then
output_hp = output_hp .. name
local current = memory.readword(RAM_CURRENT_HEALTH)
local total = memory.readword(RAM_MAX_HEALTH)
output_hp = output_hp .. string.format(" %d/%d; ", current, total)
end
name = get_in_doubles(2)
if name ~= nil then
output_hp = output_hp .. name
local current = memory.readword(RAM_CURRENT_HEALTH +0xB0)
local total = memory.readword(RAM_MAX_HEALTH +0xB0)
output_hp = output_hp .. string.format(" %d/%d; ", current, total)
end
return output_hp
end
end

function in_battle()
return hasbit(memory.readbyte(RAM_IN_BATTLE), 1)
end

function get_textbox_line()
local bg = get_bg_screen()
for index = 13, 17 do
local heading = bg[index]
for _, border in pairs(TEXTBOX_BORDER) do
if heading:find(border:sub(1,6))
or heading:find(border:sub(#border-5,#border)) then
local startpos = heading:find(border:sub(2, 2)) - 1
local endpos = heading:find(border:sub(#border, #border))
if startpos and endpos then
if is_textbox(index + 1, border, startpos, endpos) then
if not get_menu_over_text(index + 1, startpos, endpos, border) then
return (index- 1) * 8, startpos * 4 + 5, endpos * 4 - 8
end
end
end
end
end
end
if fake_textbox then
if not get_menu_over_text(fake_textbox.line + 1) then
if fake_textbox.left == nil or fake_textbox.right == nil then
return fake_textbox.line *8
else
return fake_textbox.line *8, fake_textbox.left *8, fake_textbox.right *8
end
end
end
return nil
end

function get_menu_over_text(initpos, startpos, endpos, head)
if not startpos then
startpos = 1
end
if not endpos then
endpos = 60
end
local bg = get_bg_screen()
for index = initpos, 20 do
local heading = bg[index]:sub(startpos, endpos)
for _, border in pairs(TEXTBOX_BORDER) do
if heading == border
or heading:sub(1,6) == border:sub(1,6)
or heading:sub(#heading-5,#heading) == border:sub(#border-5,#border) then
if head then
if footer_of(head) ~= border then
return true
end
else
return true
end
end
end
end
return nil
end

function is_textbox(initpos, head, startpos, endpos)
local footer = footer_of(head)
local bg = get_bg_screen()
local last_line = 20
for index = initpos, 20 do
local heading = bg[index]:sub(startpos, endpos)
if heading == footer
or heading:sub(1,6) == footer:sub(1,6)
or heading:sub(#heading-5,#heading) == footer:sub(#footer-5,#footer) then
last_line = index
end
end
if last_line - initpos < 5 then
return true
end
return nil
end

function footer_of(header)
for i, border in ipairs(TEXTBOX_BORDER) do
if border == header then
return TEXTBOX_BORDER[i+1]
end
end
return ""
end

function get_textbox()
local tile_lines = get_window_screen().tile_lines
local lines = {}
local index, startpos, endpos = get_textbox_line()
if index ~= nil then
if not startpos then
startpos = 1
end
if not endpos then
endpos = 240
end
for i = index + 8, 160 do
line = translate_tileline(tile_lines[i]:sub(startpos, endpos))
if line ~= "" then
table.insert(lines, line)
end
end
return lines
end
return nil
end

function facing_to_string(d)
if d == DOWN then
return message.translate("down")
end
if d == UP then
return message.translate("up")
end
if d == LEFT then
return message.translate("left")
end
if d == RIGHT then
return message.translate("right")
end
return message.translate("unknown")
end

function get_game_checksum()
local crc32 = require "crc32"
local rom = memory.readbyterange(0x8000000, 0x2000000)
return crc32.crc32(rom, 0)
end

function play_footsteps()
local player_x, player_y = get_player_xy()
local blocks = get_map_blocks()
camera_x = DEFAULT_CAMERA_X
camera_y = DEFAULT_CAMERA_Y
play_tile_sound(get_block_type(blocks[player_y][player_x]), 0, 30, false)
end

function register_common_callbacks()
local functions = {
[ROM_FILL_BG_TILEMAP_BUFFER_RECT] = fill_bg_tilemap_buffer_rect,
[ROM_FREE_WINDOW_BUFFERS] = clear_windows_and_screen_areas,
[ROM_FREE] = free_memory,
[ROM_RENDER_TEXT] = render_text,
[ROM_RENDER_BRAILLE_TEXT] = render_text,
[ROM_COPY_WINDOW_TO_VRAM] = copy_window_to_vram,
[ROM_FILL_WINDOW_PIXEL_BUFFER] = fill_window_pixel_buffer,
[ROM_FILL_WINDOW_PIXEL_RECT] = fill_window_pixel_rect,
[ROM_SCROLL_WINDOW] = scroll_window,
[ROM_CLEAN_WINDOWS_AND_TILEMAPS] = clear_windows_and_screen_areas,
[ROM_PUT_WINDOW_TILEMAP] = put_window_tilemap,
[ROM_SELECT_HOW_MANY] = read_how_many,
[ROM_LOAD_SPRITE_SHEET] = load_sprite_sheet,
[ROM_CLEAR_TEXT] = fill_window_pixel_buffer,
[ROM_BLIT_BITMAP_RECT_TO_WINDOW] = blit_bitmap_rect_to_window,
[ROM_BLIT_MOVE_INFO_ICON] = blit_move_info_icon,
[ROM_ADD_WINDOW] = fill_window_pixel_buffer,
[ROM_REMOVE_WINDOW] = remove_window,
[ROM_DRAW_MENU_CURSOR] = draw_menu_cursor,
[ROM_DRAW_GRID_CURSOR] = draw_grid_menu_cursor,
[ROM_DRAW_LIST_CURSOR] = draw_list_menu_cursor,
[ROM_TM_CASE_SELECTION] = read_tm_case_info,
[ROM_MOVE_SELECTION] = read_move_menu_item,
[ROM_PRINT_BOX_AND_TOTAL_POKEMON] = print_box_data_to_sprite,
[ROM_DRAW_TEXT_AND_BUFFER_TILES] = draw_text_to_tile_buffer,
[ROM_SHOW_DEPOSIT_BOXES] = read_deposit_box,
[ROM_CHOOSE_DEPOSIT_BOX_RIGHT] = read_deposit_box,
[ROM_CHOOSE_DEPOSIT_BOX_LEFT] = read_deposit_box,
[ROM_PC_SHOW_POKEMON_DATA] = read_pc_pokemon,
[ROM_MAINMENU_SELECT] = read_mainmenu_item,
[ROM_OPTION_MENU_ITEM] = read_option_menu_item,
[ROM_QUESTLOG_CLEAN] = questlog_clean,
[ROM_HANDLE_BATTLE_WINDOW] = handle_battle_window,
[ROM_ACTION_SELECTION] = read_battle_menu_item,
[ROM_BATTLE_MOVE_SELECTION] = read_battle_move_menu_item,
[ROM_TARGET_SELECTION1] = read_target_menu_item,
[ROM_TARGET_SELECTION2] = read_target_menu_item,
[ROM_BATTLE_YESNO] = read_battle_yesno,
[ROM_COPY_TEXT_INTO_HEALTHBOX] = add_healthbox_text,
[ROM_SAFARI_COPY_TEXT_INTO_HEALTHBOX] = safari_add_healthbox_text,
[ROM_STATUS_IN_HEALTHBOX] = show_status_in_healthbox,
[ROM_STATUS_IN_SUMMARY] = show_status_in_summary,
[ROM_PKMN_SELECTION] = read_pkmn_menu_item,
[ROM_INIT_BGS] = clear_vram,
[ROM_FOOTSTEP_FUNCTION] = play_footsteps
}
register_callbacks(functions)
end

fake_textbox = nil
tmp_sheet = nil
option_menu_pos = nil
last_selected_option = nil
old_kbd_col = nil
old_kbd_row = nil
unread_text = false
want_read = false
ignore_bitmap = false

clear_all_graphics()

function main_loop()
handle_user_actions()
if language ~= nil then
handle_special_cases()
if  not is_scrolling() and want_read then
read_mapname_if_needed()
read_text(true)
want_read = false
end
end
end
