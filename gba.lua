ROM_TITLE_ADDRESS = 0x80000A0
ROM_GAMECODE_START = 12
REQUIRED_FILES = {"chars.lua", "memory.lua"}
codemap = {
["BPR"] = "firered",
["BPG"] = "leafgreen",
["BPE"] = "emerald",
}
CHAR_NAME_END = 0xFF
DOWN = 1
UP = 2
LEFT = 3
RIGHT = 4
DEFAULT_CAMERA_X = -8
DEFAULT_CAMERA_Y = -8
camera_elevation = 0xF
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
TOTAL_METATILES = 0x400
MAX_TEXTBOX_HEIGHT = 5

KEYBOARD_KEYS = {
[0] = "keyboard_change",
[1] = "keyboard_backspace",
[2] = "keyboard_ok"
}

IO_BG_CONTROL = 0x4000000
VRAM_START = 0x6000000
VRAM_OBJ_START = 0x6010000
VRAM_SIZE = 0x18000
VRAM_BG_SIZE = 0x10000
VRAM_OBJ_SIZE = 0x8000
TILE_PIXELS = 64
SCREEN_PIXELS = 38400
SCREEN_WIDTH = 240
SCREEN_HEIGHT = 160
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
BG_TILES = 2048
SPRITE_TILES = 1024
last_scroll_x = {}
last_scroll_y = {}
text_window = {}
bg_tile = {}
sprite_tile = {}

function cpu_fast_set()
cpu_set_vram(bit.band(memory.getregister("r2"), 0x1FFFFF) *4)
end

function cpu_set()
cpu_set_vram(bit.band(memory.getregister("r2"), 0x1FFFFF) *2 *(1 +bit.rshift(memory.getregister("r2"), 26)))
end

function cpu_set_vram(size)
local dest = memory.getregister("r1")
if dest <VRAM_START or dest >= VRAM_START +VRAM_SIZE then
return
end

if size == VRAM_SIZE then
clear_vram()
return
end

size = size *2
local src = memory.getregister("r0")
local dest_tile
if dest >= VRAM_START and dest < VRAM_START +VRAM_BG_SIZE then
dest_tile = bg_tile
elseif dest >= VRAM_OBJ_START and dest < VRAM_OBJ_START +VRAM_OBJ_SIZE then
dest_tile = sprite_tile
if tmp_sheet then
copy_window_to_vram_tiles(dest_tile, tmp_sheet, 0, dest, size)
tmp_sheet = nil
return
end
end
for i = 0, get_last_window() do
local window = get_window(i, false)
if src >= window.data_address and src < window.data_address +window.tile_bytes then
copy_window_to_vram_tiles(dest_tile, window, src, dest, size)
return
end
end
copy_window_to_vram_tiles(dest_tile, create_window(nil, nil, nil, size /8, 8), 0, dest, size)
end

function free_memory()
local pointer = memory.getregister("r0")
for i = 0, get_last_window() do
local window = get_window(i, false)
if pointer == window.data_address then
text_window[i] = nil
end
end
end

function get_window_tile_num(window, x, y)
return math.floor(y /8) *window.width +math.floor(x /8)
end

function get_window_pixel_address(window, x, y)
return get_window_tile_num(window, x, y) *TILE_PIXELS +(y %8) *8 +(x %8)
end

function move_pixels_up(window, rows)
local size = window.width *window.height *TILE_PIXELS
local start = 0
for tile = 0, size -1, TILE_PIXELS do
local distance = rows
for i = 0, TILE_PIXELS -1, 8 do
local dest = tile +i
local src = tile +(bit.bor((window.width *bit.band(distance, bit.bnot(7))), bit.band(distance, 7)) *8)
for j = 0, 7 do
if src < size then
window.data[start +dest +j] = window.data[start +src +j]
else
window.data[start +dest +j] = 0xFF
end
end
distance = distance +1
end
end
end

function move_pixels_down(window, rows)
local size = window.width *window.height *TILE_PIXELS
local start = size -8
for tile = 0, size -1, TILE_PIXELS do
local distance = rows
for i = 0, TILE_PIXELS -1, 8 do
local dest = tile +i
local src = tile +(bit.bor((window.width *bit.band(distance, bit.bnot(7))), bit.band(distance, 7)) *8)
for j = 0, 7 do
if src < size then
window.data[start -dest +j] = window.data[start -src +j]
else
window.data[start -dest +j] = 0xFF
end
end
distance = distance +1
end
end
end

function copy_window_to_vram()
if memory.getregister("r1") > 1 then
local window = get_window(memory.getregister("r0"))
if not is_bg_visible(window.bg) then
return
end

local dest = get_bg_base_tile(window.bg) +window.base_block
if get_bg_palette_mode(window.bg) == 0 then
dest = dest *0x20
else
dest = dest *0x40
end
dest = get_bg_char_base(window.bg) *0x4000 +dest
copy_window_to_bg_tiles(window, dest)
end
end

function copy_window_to_bg_tiles(window, dest_data)
if window.data == nil then
return
end

dest_data = bit.band(dest_data, 0xFFFF)

local left = dest_data /4
local width = BG_TILES * 8

for i = 0, (window.width *window.height) -1 do
bg_tile[dest_data *2 +i] = window.data[i]
end
end

function fill_window_pixel_rect()
local window = get_window(memory.getregister("r0"), false)
if not window.data then
return
end
local fill_value = memory.getregister("r1")
local left = memory.getregister("r2")
local top = memory.getregister("r3")
local width = memory.readword(memory.getregister("r13"))
local height = memory.readword(memory.getregister("r13")+4)
local value
if fill_value == 0x00 then
value = 0xFE
else
value = 0xFF
end
for y = top, top +(height -1) do
for x = left, (left + (width -1)) do
window.data[get_window_pixel_address(window, x, y)] = value
end
end
end

function blit_bitmap_rect_to_window()
if ignore_bitmap then
ignore_bitmap = false
return
end

local window = get_window(memory.getregister("r0"), false)
if not window.data then
return
end
local left = memory.readdword(memory.getregister("r13")+8)
local top = memory.readdword(memory.getregister("r13")+12)
local width = memory.readword(memory.getregister("r13")+16)
local height = memory.readdword(memory.getregister("r13")+20)
for y = top, top + (height -1) do
for x = left, (left + (width -1)) do
window.data[get_window_pixel_address(window, x, y)] = 0xFF
end
end
end

function scroll_window()
local window = get_window(memory.getregister("r0"), false)
if not window.data then
return
end
local direction = memory.getregister("r1")
local rows = memory.getregister("r2")
if direction == 0 then
move_pixels_up(window, rows)
elseif direction == 1 then
move_pixels_down(window, rows)
end
end

function get_window_tilelines(window)
if not window.data then
return {}
end
local window_tile_width = window.width /8
local window_tile_height = window.height /8
local data = {}
for tile = 0, (window_tile_width *window_tile_height) -1 do
for i = 0, 7 do
for j = 0, 7 do
data[(math.floor(tile /window_tile_width) *8 +i) *window.width +(tile %window_tile_width) *8 +(j %8)] = window.data[tile *TILE_PIXELS +i *8 +j]
end
end
end

local tile_lines = {}
for i = 0, (window.width * window.height) -1, window.width do
local tile_line = ""
for j = 0, window.width -1 do
local char = data[i+j]
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

return -1
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
local fill_value = memory.getregister("r1")
local value
if fill_value == 0x00 then
value = 0xFE
else
value = 0xFF
end
text_window[id] = fill_window(get_window(id), value)
end

function copy_to_window_pixel_buffer()
local id = memory.getregister("r0")
text_window[id] = fill_window(get_window(id), 0xFF)
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
window.base_block = memory.readword(RAM_WINDOWS+id*12+6)
window.data_address = memory.readdword(RAM_WINDOWS+id*12+8)
window.tile_bytes = window.width *window.height *32
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

function fill_window(window, value)
if not value then
value = 0xFE
end
window.data = {}
for i = 0, (window.width * window.height) -1 do
window.data[i] = value
end
return window.data
end

function get_screen_starting_position(bg, pixels)
if pixels == nil then
pixels = true
end
local bg_width, bg_height = get_bg_screen_size(bg, true)
local left = memory.readword(IO_BG_CONTROL +0x10 +4 *bg) %(bg_width *8)
local top = memory.readword(IO_BG_CONTROL +0x12 +4 *bg) %(bg_height *8)
if not pixels then
left = math.floor(left /4)
top = math.floor(top /8)
end
return left, top
end

function is_scrolling()
local scrolling = false
for i = 0, 3 do
if is_valid_text_bg(i) then
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
end

return scrolling
end

function get_hidden_bg()
if keyboard_showing() then
return memory.readbyte(memory.readdword(RAM_NAMING_DATA_POINTER) + 0x1E21) + 1
end
return nil
end

function is_bg_active(id)
return bit.band(memory.readbyte(RAM_BGS +17), bit.lshift(1, id)) ~= 0
end

function is_bg_visible(id)
return bit.band(memory.readbyte(RAM_BGS +4 *id), 1) ~= 0
end

function get_bg_screen_size(id, get_dimensions)
if get_dimensions == nil then
get_dimensions = false
end
local size = bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id), 0xC), 2)
if get_dimensions then
local type = get_bg_type(id)
if type == 0 then
return 32 *(1 +bit.band(size, 1)), 32 *(1 +bit.rshift(size, 1))
elseif type == 1 then
return 2 ^ (4 +type), 2 ^ (4 +type)
else
return 0, 0
end
else
return size
end
end

function get_bg_priority(id)
return bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id), 0x30), 4)
end

function get_bg_char_base(id)
return bit.band(memory.readbyte(RAM_BGS +4 *id +1), 0x3)
end

function get_bg_map_base(id)
return bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id +1), 0x7c), 2)
end

function get_bg_palette_mode(id)
return bit.rshift(bit.band(memory.readbyte(RAM_BGS +4 *id +1), 0x80), 7)
end

function get_bg_mode()
return bit.band(memory.readbyte(RAM_BGS +16), 0x7)
end

function get_bg_base_tile(id)
return memory.readdword(RAM_BG_TILEMAPS +16 *id)
end

function get_bg_tilemap_address(id)
local address = memory.readdword(RAM_BG_TILEMAPS +16 *id +4)
if address == 0 then
address = VRAM_START +get_bg_map_base(id) *0x800
end
return address
end

function get_bg_type(id)
local mode = get_bg_mode()
if id == 0 or id == 1 then
if mode == 0 or mode == 1 then
return 0
end
elseif id == 2 then
if mode == 0 then
return 0
elseif mode == 1 or mode == 2 then
return 1
end
elseif id == 3 then
if mode == 0 then
return 0
elseif mode == 2 then
return 1
end
end

return -1
end

function get_bg_metric_text_mode(id)
local size = get_bg_screen_size(id)
if size == 3 then
return 4
elseif size == 1 or size == 2 then
return 2
else
return 1
end
return 0
end

function get_bg_metric_affine_mode(id)
local size = get_bg_screen_size(id)
if size == 3 then
return 64
elseif size == 2 then
return 16
elseif size == 1 then
return 4
else
return 1
end
return 0
end

function get_bg_tilemap_vram_address(id)
return VRAM_START +get_bg_map_base(id) *0x800
end

function get_bg_size(id)
local type = get_bg_type(id)
local size = 0

if type == 0 then
size = get_bg_metric_text_mode(id) *0x800
elseif type == 1 then
size = get_bg_metric_affine_mode(id) *0x100
end
return size
end

function is_valid_text_bg(id)
return is_bg_active(id)
and is_bg_visible(id)
and get_bg_type(id) ~= 1
end

function get_bg_tilemap(id)
local tilemap = memory.readbyterange(get_bg_tilemap_address(id), get_bg_size(id))
local size = get_bg_screen_size(id)
local final_tilemap

if size == 0 or size == 2 then
final_tilemap = tilemap
elseif size == 1 then
local width, height = get_bg_screen_size(id, true)
final_tilemap = {}
for i = 0, height -1 do
for j = 0, width -1 do
final_tilemap[i *(width *2) +j +1] = tilemap[i *width +j +1]
final_tilemap[i *(width *2) +width +j +1] = tilemap[0x800 +i *width +j +1]
end
end
elseif size == 3 then
local width, height = get_bg_screen_size(id, true)
final_tilemap = {}
for i = 0, (height /2) -1 do
for j = 0, width -1 do
final_tilemap[i *(width *2) +j +1] = tilemap[i *width +j +1]
final_tilemap[i *(width *2) +width +j +1] = tilemap[0x800 +i *width +j +1]
final_tilemap[(height /2 +i) *(width *2) +j +1] = tilemap[0x1000 +i *width +j +1]
final_tilemap[(height /2 +i) *(width *2) +width +j +1] = tilemap[0x1800 +i *width +j +1]
end
end
end

return final_tilemap
end

function get_bg_tiles(id)
local bg = get_bg_tilemap(id)
local bg_width, bg_height = get_bg_screen_size(id, true)
local tiles = {}
for i = 0, bg_height -1 do
for j = 1, bg_width *2, 2 do
local tile = bit.band(get_bg_char_base(id) *0x200 +bit.bor(bit.lshift(bit.band(bg[i *bg_width *2 +j +1], 0x03), 8), bg[i *bg_width *2 +j]), BG_TILES -1)
put_bg_tile(tiles, bg_width *8, (j -1) *4 +1, i *8, tile)
end
end
return tiles
end

memory.registerwrite(0x40000dc, function()
local dest = memory.readdword(0x40000d8)
if dest <VRAM_START or dest >= VRAM_START +VRAM_SIZE then
return
end

local src = memory.readdword(0x40000d4)
for i = 0, 3 do
if src == get_bg_tilemap_address(i) then
return
end
end

local dma_control = memory.getregister("r" .. bit.band(memory.readword(memory.getregister("r15") -4), 7))
local size = bit.band(dma_control, 0xFFFF) *2 *(1 +bit.band(bit.rshift(dma_control, 26), 1))
if size == VRAM_SIZE then
clear_vram()
return
end

size = size *2
local dest_tile
if dest >= VRAM_START and dest < VRAM_START +VRAM_BG_SIZE then
dest_tile = bg_tile
elseif dest >= VRAM_OBJ_START and dest < VRAM_OBJ_START +VRAM_OBJ_SIZE then
dest_tile = sprite_tile
if tmp_sheet then
copy_window_to_vram_tiles(dest_tile, tmp_sheet, 0, dest, size)
tmp_sheet = nil
return
end
end
for i = 0, get_last_window() do
local window = get_window(i, false)
if src >= window.data_address and src < window.data_address +window.tile_bytes then
copy_window_to_vram_tiles(dest_tile, window, src, dest, size)
return
end
end
copy_window_to_vram_tiles(dest_tile, create_window(nil, nil, nil, size /8, 8), 0, dest, size)
end)

function put_bg_tile(screen, width, x, y, tile)
local bg_tile_width = BG_TILES * 8
for i = 0, 7 do
for j = 0, 7 do
screen[(y +i) *width +x +j] = bg_tile[tile *TILE_PIXELS +i *8 +j]
end
end
end

function clear_bg_tiles()
bg_tiles = {}
for i = 0, (BG_TILES *TILE_PIXELS) -1 do
bg_tile[i] = 0xFE
end
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
local start = sprite_tile_num(id)
local size = sprite.width *sprite.height /TILE_PIXELS
for tile = 0, size -1 do
for i = 0, TILE_PIXELS -1 do
sprite.data[tile *TILE_PIXELS +i] = sprite_tile[(start +tile) *TILE_PIXELS +i]
end
end
end

function copy_sprite_to_screen(sprite, screen)
if not sprite.data then
return
end
local sprite_tile_width = sprite.width /8
local sprite_tile_height = sprite.height /8
for tile = 0, (sprite_tile_width *sprite_tile_height) -1 do
for i = 0, 7 do
for j = 0, 7 do
if sprite.data[tile *TILE_PIXELS +i *8 +j] ~= 0xfe then
screen[(sprite.top +math.floor(tile /sprite_tile_width) *8 +i) *SCREEN_WIDTH +sprite.left +(tile %sprite_tile_width) *8 +(j %8)] = sprite.data[tile *TILE_PIXELS +i *8 +j]
end
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
if window == -1 then
return
end

window = get_window(window, false)
if window.data == nil then
return
end

tmp_sheet = create_window(4, 0, 0, 384, 8)

local size = memory.getregister("r0")

local window_start = 0
local start = 0
for time = size, 1, -1 do
for i = 0, (TILE_PIXELS *8) -1 do
tmp_sheet.data[start +i] = window.data[window_start +bit.rshift(bit.band(i, 0x100), 8) *window.width *TILE_PIXELS +bit.band(i, 0xFF)]
end
window_start = window_start +0x100
start = start +0x200
end
read_window(get_window(window.id))
end

function load_sprite_sheet()
local dest_data = bit.band(memory.getregister("r1"), 0xFFFF)
local size = memory.getregister("r2") *2

local start = dest_data *2

local sheet
if tmp_sheet then
sheet = tmp_sheet
tmp_sheet = nil
else
sheet = create_window(nil, 0, 0, size /8, 8)
end

for i = 0, size -1 do
sprite_tile[start +i] = sheet.data[i]
end
end

function copy_window_to_vram_tiles(dest_tile, window, source_data, dest_data, size)
if window.data == nil then
return
end

source_data = source_data - window.data_address
dest_data = bit.band(dest_data, 0xFFFF)

local window_start = source_data *2
local start = dest_data *2

for i = 0, size -1 do
dest_tile[start +i] = window.data[window_start +i]
end
end

function add_healthbox_text()
local window = get_last_window()
if window == -1 then
return
end

copy_window_to_sprite_tiles(get_window(window), memory.getregister("r1"), memory.getregister("r0"), memory.getregister("r2") *TILE_PIXELS, 8)
end

function safari_add_healthbox_text()
local window = get_last_window()
if window == -1 then
return
end

copy_window_to_sprite_tiles(get_window(window), memory.getregister("r1"), memory.getregister("r0"), memory.getregister("r2") *TILE_PIXELS, 0)
end

function show_status_in_healthbox()
tmp_sheet = create_window(nil, 0, 0, 32, 8, 0xFF)

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

tmp_sheet.data[32] = fill
end

function show_status_in_summary()
tmp_sheet = create_window(nil, 0, 0, 256, 8, 0xFF)

for i = 1, 7 do
tmp_sheet.data[256 *(i -1) +36] = 0xFC00 +i
end
end

function clear_sprite_tiles()
sprite_tiles = {}
for i = 0, (SPRITE_TILES *64) -1 do
sprite_tile[i] = 0xFE
end
end

function clear_tile_table(start, size)
local tile, width
if start < VRAM_START +0x10000 then
tile = bg_tile
width = BG_TILES *8
else
tile = sprite_tile
width = SPRITE_TILES *8
end

start = bit.band(start, 0xFFFF) /4
size = size /4
if size > 0x4000 then size = 0x4000 end
for i = 0, 7 do
for j = start, start +size -1 do
tile[i *width +j] = 0xFE
end
end
end

function clear_vram()
clear_bg_tiles()
clear_sprite_tiles()
end

function clear_all_graphics()
text_window = {}
clear_bg_tiles()
clear_sprite_tiles()
end

function get_bg_screen()
local screen = {}
for i = 0, (SCREEN_PIXELS /32) -1 do
screen[i] = 0x00
end
local bgs = sort_bgs()
for i = 4, 1, -1 do
local current = bgs[i]
local hidden_bg = get_hidden_bg()
if is_valid_text_bg(current)
and (not hidden_bg or hidden_bg ~= current) then
local bg = get_bg_tilemap(current)
local bg_width, bg_height = get_bg_screen_size(current, true)
local left, top = get_screen_starting_position(current, false)
for y = 0, (SCREEN_HEIGHT /8) -1 do
for x = 0, (SCREEN_WIDTH /8) -1 do
local val2 = bg[((top +y) %bg_height) *bg_width *2 +(left +x) *2 %(bg_width *2) +1]
local val1 = bg[((top +y) %bg_height) *bg_width *2 +(left +x) *2 %(bg_width *2) +2]
if val1 ~= 0 or val2 ~= 0 then
screen[y *SCREEN_WIDTH /4 +x *2] = bit.band(val1, 0xF)
screen[y *SCREEN_WIDTH /4 +x *2 +1] = val2
end
end
end
end
end
local tile_lines = {}
for i = 0, (SCREEN_PIXELS /32) -1, SCREEN_WIDTH / 4 do
local tile_line = ""
for j = 0, (SCREEN_WIDTH/4) -1 do
tile_line = tile_line .. string.char(screen[i+j])
end
table.insert(tile_lines, tile_line)
end
return tile_lines
end

function get_window_screen()
local screen = {}
for i = 0, SCREEN_PIXELS -1 do
screen[i] = 0xFF
end

local bgs = sort_bgs()
local last_sprite = MAX_SPRITES -1
for i = 4, 1, -1 do
local current = bgs[i]
local hidden_bg = get_hidden_bg()
if is_valid_text_bg(current)
and (not hidden_bg or hidden_bg ~= current) then
local bg = get_bg_tiles(current)
local bg_width, bg_height = get_bg_screen_size(current, true)
local left, top = get_screen_starting_position(current)
for y = 0, SCREEN_HEIGHT -1 do
for x = 0, SCREEN_WIDTH -1 do
local value = bg[((top +y) %(bg_height *8)) *bg_width *8 +(left +x) %(bg_width *8) +1]
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
for i = 0, SCREEN_PIXELS -1, SCREEN_WIDTH do
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
return {lines=lines, tile_lines=tile_lines}
end

function translate_tileline(tileline)
local l = ""
if not tileline then
return l
end
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

function get_window_text(window, from_screen)
local tilelines
if from_screen then
tilelines = get_window_tilelines_from_screen(window)
else
tilelines = get_window_tilelines(window)
end
local lines = {}
for _, tileline in pairs(tilelines) do
local line = translate_tileline(tileline)
if line ~= "" then
table.insert(lines, line)
end
end
return lines
end

function read_window(window, mode)
local lines = get_window_text(window, mode)
for _, v in pairs(lines) do
tolk.output(v)
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
local position = BATTLE_MENU_LINE + option*8
if lines[position] then
tolk.output(translate_tileline(lines[position]:sub(startpos, endpos)))
end
end

function read_battle_yesno()
if not text_window[BATTLE_YESNO_WINDOW] then
return
end
local position = (memory.getregister("r3") -9) *8 +BATTLE_YESNO_LINE
local tiles = get_window_tilelines(get_window(BATTLE_YESNO_WINDOW))
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
if memory.getregister("r1") == 1 then
local window = memory.getregister("r0")
if get_last_window() > 8 and window > 5 then
window = window +1
end
window = get_window(window)
if window_is_empty(window) then
return
end
read_window(window, true)
end
end

function read_how_many()
tolk.output(tostring(memory.getregister("r1")))
end

function read_tm_case_info()
local headings = get_window_tilelines(get_window(4))
local lines = get_window_tilelines(get_window(5))
if lines[9] then
local type = trim(translate_tileline(headings[9]) .. " " .. translate_tileline(lines[9]))
if type ~= "" then
tolk.output(type)
end
end
if lines[21] then
local power = trim(translate_tileline(headings[21]) .. " " .. translate_tileline(lines[21]))
if power ~= "" then
tolk.output(power)
end
end
if lines[33] then
local accuracy = trim(translate_tileline(headings[33]) .. " " .. translate_tileline(lines[33]))
if accuracy ~= "" then
tolk.output(accuracy)
end
end
if lines[45] then
local pp = trim(translate_tileline(headings[45]) .. " " .. translate_tileline(lines[45]))
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
local description = {}
for i = 49, #lines do
local line = translate_tileline(lines[i])
if line ~="" then
table.insert(description, line)
end
end
if #description > 0 then
tolk.output(table.concat(description, " "))
end
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
if trim(lines[DEPOSIT_BOX_LINE]) ~= "" then
tolk.output(trim(lines[DEPOSIT_BOX_LINE]))
tolk.output(trim(lines[DEPOSIT_BOX_LINE +16]))
elseif trim(lines[DEPOSIT_BOX_LINE +64]) ~= "" then
tolk.output(trim(lines[DEPOSIT_BOX_LINE +64]))
tolk.output(trim(lines[DEPOSIT_BOX_LINE +80]))
end
end

function read_pc_pokemon()
read_window(get_window(0))
end

function get_in_doubles(id)
local lines = get_window_screen().lines
local line = ""
for _, v in pairs(DOUBLE_COORDS[id]) do
line = lines[v]
if trim(line) ~= "" then
break
end
end
if line:match(translate(0xF905)) then
return trim(line:sub(1, line:find(translate(0xF905)) -1))
end
return nil
end

function render_text()
local func_address = memory.getregister("r15")
local current_char = memory.getregister("r3")
baseOffset = memory.getregister("r6")
local window = get_window_header(memory.readbyte(baseOffset+4), false)
if not text_window[window.id] then
text_window[window.id] = fill_window(get_window(window.id))
end
local char_x = memory.readbyte(baseOffset+8)
local char_y = memory.readbyte(baseOffset+9) +8
local pos = get_window_pixel_address(get_window(window.id, false), char_x, char_y)
if current_char < 0xFA then
if current_char > 0xF7 then
text_window[window.id][pos] = current_char *0x100 +memory.readbyte(memory.getregister("r0") + 1)
if current_char == 0xF8 then
ignore_bitmap = true
end
else
if func_address == ROM_RENDER_BRAILLE_TEXT + 2 then
text_window[window.id][pos] = bit.bor(current_char, 0xFA00)
else
text_window[window.id][pos] = current_char
end
end
-- controls.inputbox("test", "", window.id .. " " .. window.bg .. " " .. string.format("%x", current_char) .. " " .. " " .. translate(current_char))
unread_text = true
elseif current_char == 0xFE and func_address == ROM_RENDER_BRAILLE_TEXT + 2 then
text_window[window.id][pos] = 0xFA00
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

function is_warp_tile(type)
for _, v in pairs(WARP_TILES) do
if type == v then
return true
end
end
return false
end

function is_hole(type)
for _, v in pairs(HOLE_TILES) do
if type == v then
return true
end
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
if mapid == 0x7F7F then
local dynamic_warp = memory.readdword(RAM_SAVEBLOCK1_POINTER) +RAM_DYNAMIC_WARP
mapid = memory.readbyte(dynamic_warp)*256+memory.readbyte(dynamic_warp +1)
end
local name = "Warp " .. i
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=x, y=y, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
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
local name = message.translate("signpost") .. i
local post = {x=x, y=y, name=name, type="signpost", id="signpost_" .. i}
post.name = get_name(mapid, post)
table.insert(results, post)
end
ptr = ptr + 12
end
return results
end

function get_objects()
local objects = get_num_objects()
local mapid = get_map_id()
local ptr = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_MAP_OBJECTS
local results = {}
for i = 1, objects do
local flag = bit.band(memory.readword(ptr+20), 0x3FFF)
local movement = memory.readbyte(ptr +9)
local visible = (movement ~= 0x4C)
if flag ~= 0 then
visible = visible and not get_flag(flag)
end
if visible then
local id = memory.readbyte(ptr)
local sprite = memory.readbyte(ptr+1)
local x = memory.readword(ptr+4)
local y = memory.readword(ptr+6)
local is_var_sprite = false
if check_coordinates_on_screen(x, y) then
if sprite > 0xEF then
sprite = get_var(sprite +0x3F20)
is_var_sprite = true
end
local name = message.translate("object") .. i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
local object = {x=x, y=y, id_map=id, sprite=sprite, name=name, type="object", id="object_" .. i, is_var_sprite=is_var_sprite}
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
if active ~= 0 then
local invisible = bit.rshift(bit.band(memory.readbyte(ptr +1), 0x20), 5)
local id = memory.readbyte(ptr +8)
local sprite = memory.readbyte(ptr +5)
local map = memory.readbyte(ptr + 10) * 256 + memory.readbyte(ptr + 9)
local x = memory.readword(ptr + 16) -7
local y = memory.readword(ptr + 18) -7
local facing = bit.band(memory.readbyte(ptr + 24), 0xf)
local already_present = false
local j = 1
while j <= objects do
local obj = results[j]
if id == obj.id_map and map == mapid
and (sprite == obj.sprite or obj.is_var_sprite) then
if invisible == 0 and check_coordinates_on_screen(x, y) then
obj.x = x
obj.y = y
obj.facing = facing
if sprite ~= obj.sprite then
obj.sprite = sprite
obj.name = message.translate("object") .. objects +i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
obj.name = format_names(sprites[sprite])
end
obj.name = get_name(mapid, obj)
end
else
table.remove(results, j)
objects = objects -1
end
already_present = true
break
end
j = j +1
end
if not already_present and map == mapid then
if invisible == 0 and id ~= 0xFF and check_coordinates_on_screen(x, y) then
local name = message.translate("object") .. objects +i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
local object = {x=x, y=y, facing=facing, sprite=sprite, name=name, type="object", id="object_" .. objects +i}
object.name = get_name(mapid, object)
table.insert(results, object)
end
end
end
ptr = ptr + 36
end
if map_object_triggers then
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
for i, v in pairs(map_object_triggers) do
if i == mapid then
local args, object = unpack(v)
if args ~= nil and args ~= true and args ~= false then
args(results)
else
local triggers = memory.readbyte(eventstart +2)
ptr = memory.readdword(eventstart+12)
for i = 1, triggers do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
local ignorable = args
local trigger = {x=x, y=y, name=message.translate(object), type="object", id=object .. "_" .. y .. x,  ignorable=ignorable}
trigger.name = get_name(mapid, trigger)
table.insert(results, trigger)
end
ptr = ptr +16
end
end
end
end
end
local types = get_blocks_type()
for y = 0, #types -7 do
for x = 0, #types[0] -8 do
if is_hole(types[y][x]) then
if check_coordinates_on_screen(x, y) then
local hole = {x=x, y=y, name=message.translate("hole"), type="object", id="hole_" .. y .. x}
hole.name = get_name(mapid, hole)
table.insert(results, hole)
end
elseif is_dark_water(types[y][x]) then
if check_coordinates_on_screen(x, y) then
if not surrounded_by_same_type(types, x, y) then
local dive = {x=x, y=y, name=message.translate("dark_water"), type="warp", id="dive" .. y .. x, ignorable=true}
dive.name = get_name(mapid, dive)
table.insert(results, dive)
end
end
elseif is_clear_water(types[y][x]) then
if check_coordinates_on_screen(x, y) then
if not surrounded_by_same_type(types, x, y) then
local emerge = {x=x, y=y, name=message.translate("clear_water"), type="warp", id="emerge" .. y .. x, ignorable=true}
emerge.name = get_name(mapid, emerge)
table.insert(results, emerge)
end
end
else
for i, v in pairs(tile_objects) do
if i == types[y][x] then
local object, ignorable = unpack(v)
if check_coordinates_on_screen(x, y) then
local tileobj = {x=x, y=y, name=message.translate(object), type="object", id=object .. "_" .. y .. x, ignorable=ignorable}
tileobj.name = get_name(mapid, tileobj)
table.insert(results, tileobj)
end
end
end
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
if dir < 5 then
local offset = memory.readdwordsigned(ptr + 4)
local mapid = memory.readbyte(ptr + 8)*256+memory.readbyte(ptr + 9)
local name = message.translate("connection_to", message.translate(connection_point[dir]))
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = name .. ", " .. mapname
end
table.insert(results, {type="connection", direction=connection_point[dir], offset = offset, map = mapid, name=name, x=x, y=y, id="connection_" .. dir})
end
ptr = ptr + 12
end
return results
end

function get_connection_limits(connection)
local width, height = get_map_dimensions(memory.readdword(RAM_MAP_HEADER_POINTER))
local connected_width, connected_height = get_map_dimensions(memory.readdword(get_connected_map_header_pointer(connection)))
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

function get_player_elevation()
return bit.band(memory.readbyte(RAM_LIVE_OBJECTS +11), 0xF)
end

function get_map_dimensions(address)
if not address then
address = RAM_MAP_LAYOUT
end

return memory.readdword(address + RAM_MAP_WIDTH), memory.readdword(address + 	RAM_MAP_HEIGHT)
end

function get_connected_map_header_pointer(connection)
local block = bit.rshift(connection.map, 8)
local number = bit.band(connection.map, 0xFF)

return memory.readdword(memory.readdword(ROM_MAP_GROUPS + block * 4) + number * 4)
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

function play_tile_sound(type, pan, vol, is_camera)
local sound = nil
local final_pan = pan
if is_grass(type) then
sound = scriptpath .. "sounds\\gba\\s_grass.wav"
elseif is_waterfall(type, false) then
sound = scriptpath .. "sounds\\common\\s_waterfall.wav"
elseif is_water(type, false) then
sound = scriptpath .. "sounds\\common\\s_water.wav"
elseif is_camera and is_hole(type) then
sound = scriptpath .. "sounds\\common\\s_hole.wav"
else
for i, sounds in pairs(tile_sounds) do
if i == type then
for _, v in pairs(sounds) do
local path, camera, new_pan = unpack(v)
if (camera and is_camera)
or not camera then
sound = scriptpath .. path
if new_pan then
final_pan = new_pan
end
break
end
end
if sound ~= nil then
break
end
end
end
end
audio.play(sound or scriptpath .. "sounds\\gba\\s_default.wav", 0, final_pan, vol)
if additional_tile_sounds[type] then
local path, camera, new_pan = unpack(additional_tile_sounds[type])
if (camera and is_camera)
or not camera then
sound = scriptpath .. path
if new_pan then
final_pan = new_pan
end
end
if sound then
audio.play(sound, 0, final_pan, vol)
end
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

function is_grass(type)
for _, v in pairs(GRASS_TILES) do
if type == v then
return true
end
end
return false
end

function is_waterfall(type)
if type == 0x13 then
return true
end
return false
end

function is_dark_water(type)
if type == 0x11
or type == 0x14 then
return true
end
return false
end

function is_clear_water(type)
if type == 0x12 then
return true
end
return false
end

function surrounded_by_same_type(types, x, y)
local type = types[y][x]
return types[y -1][x] == type
and types[y][x -1] == type
and types[y][x +1] == type
and types[y +1][x] == type
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

function get_var_pointer(index)
if index < VARS_START then
return nil
elseif index < SPECIAL_VARS_START then
return memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_VARS + (index -VARS_START) * 2
else
return memory.readdword(ROM_SPECIAL_VARS + (index - SPECIAL_VARS_START) * 4)
end
return nil
end

function get_var(index)
return memory.readword(get_var_pointer(index))
end

function in_options_menu()
if check_window_present(WINDOW_OPTIONS) then
return true
end
return false
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

function handle_options_menu()
if option_menu_pos and (read_option or read_suboption) then
local tilelines = get_window_tilelines(get_window(1))
if tilelines[option_menu_pos] then
local selected_option
if read_option then
selected_option = get_readable_option(tilelines[option_menu_pos])
elseif read_suboption then
selected_option = get_readable_option(tilelines[option_menu_pos], true)
end
if selected_option ~= "" then
tolk.output(selected_option)
end
end
end
read_option = false
read_suboption = false
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

function mapname_popup()
local line = translate_tileline(get_window_screen().tile_lines[MAP_POPUP_LINE])
if line ~= "" then
tolk.output(line)
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
for i, line in pairs(lines) do
line = trim(line)
if line ~= "" then
-- controls.inputbox("line", "", i .. ": " .. line)
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
s = s .. message.translate("up") .. string.format("%d (%d); ", types[player_y - 1][player_x], elevations[player_y-1][player_x])
end -- Check up tile

-- Check down tile
if player_y <= #types then
s = s .. message.translate("down") .. string.format("%d (%d); ", types[player_y + 1][player_x], elevations[player_y+1][player_x])
end -- Check down tile

-- Check left tile
if player_x >= 0 then
s = s .. message.translate("left") .. string.format("%d (%d); ", types[player_y][player_x - 1], elevations[player_y][player_x-1])
end -- Check left tile

-- Check right tile
if player_x <= #types[0] then
s = s .. message.translate("right") .. string.format("%d (%d)", types[player_y][player_x + 1], elevations[player_y][player_x+1])
end -- Check right tile

tolk.output(s)
end

function check_coordinates_on_screen(x, y)
local width, height = get_map_dimensions()
width = width -15
height = height -14
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

if camera_y > DEFAULT_CAMERA_Y and camera_x > DEFAULT_CAMERA_X and camera_y <= #blocks and camera_x <= #blocks[1] then
local objects = get_objects()
for i, obj in pairs(objects) do
if obj.x == camera_x and obj.y == camera_y then
if obj.sprite == BOULDER_SPRITE then
audio.play(scriptpath .. "sounds\\gba\\s_boulder.wav", 0, pan, vol)
end -- sprite_id
end -- obj.xy
end

local current_block = blocks[camera_y -y][camera_x -x]
local next_block = blocks[camera_y][camera_x]
local current = {
impassable = get_block_impassable(current_block),
type = get_block_type(current_block),
elevation = get_block_elevation(current_block)
}
if current.elevation == 0xF then
current.elevation = camera_elevation
end

local next = {
impassable = get_block_impassable(next_block),
type = get_block_type(next_block),
elevation = get_block_elevation(next_block)
}

if is_collision(false, current, next) then
if ignore_wall then
camera_x = camera_x - x
camera_y = camera_y - y
end
audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
else
if is_game("rse") and is_rotating_gate(camera_x, camera_y, encode_direction(x, y)) ~= -1 then
local gate = is_rotating_gate(camera_x, camera_y, encode_direction(x, y))
if gate == 0 then
audio.play(scriptpath .. "sounds\\common\\no_pass.wav", 0, pan, vol)
elseif gate == 1 then
audio.play(scriptpath .. "sounds\\gba\\s_door.wav", 0, pan, vol)
elseif gate == 2 then
audio.play(scriptpath .. "sounds\\gba\\s_rotating_door.wav", 0, pan, vol)
end
else
audio.play(scriptpath .. "sounds\\common\\pass.wav", 0, pan, vol)
play_tile_sound(get_block_type(blocks[camera_y][camera_x]), pan, vol, true, encode_direction(x, y))
end
end
else
camera_x = camera_x - x
camera_y = camera_y - y
audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
end

local elevation = get_block_elevation(blocks[camera_y][camera_x])
if elevation ~= 0xF then
camera_elevation = elevation
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
or (is_elevation_mismatch(current_elevation, next_elevation)
and not can_surf(current_type, next_elevation)
and not can_surf(next_type, current_elevation))
end

function has_badge(badge)
if badge == 0 then
return true
end

local badge_flag = BADGES_START + (badge -1)
return get_flag(badge_flag)
end

function get_map_block(x, y)
local width, height = get_map_dimensions()
ptr = memory.readdword(RAM_MAP_LAYOUT +RAM_MAP_BLOCKS) -- start of overworld
return memory.readword(ptr+((y+7)*(width*2))+((x+7)*2))
end

function get_map_blocks()
local width, height = get_map_dimensions()
ptr = memory.readdword(RAM_MAP_LAYOUT +RAM_MAP_BLOCKS) -- start of overworld
local blocks = {}
for y = -7, height -8 do
for x = -7, width -8 do
local block = memory.readword(ptr+((y+7)*(width*2))+((x+7)*2))
blocks[y] = blocks[y] or {}
blocks[y][x] = block
end
end
return blocks
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
path_counter = 0
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
if not warp.ignorable then
if (warp.x ~= player_x or warp.y ~= player_y)
and (warp.x ~= dest_x or warp.y ~= dest_y) then
blocks[warp.y][warp.x] = 0x3FF
end
end
end
local types = get_blocks_type(blocks)
local elevations = get_blocks_elevation(blocks)
local impassables = get_blocks_impassable(blocks)

-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = 0, height do
for x = 0, width do
local n = {x=x, y=y, type=types[y][x], elevation=elevations[y][x], impassable=impassables[y][x], special_tiles=get_special_tiles_around(types, y, x)}
if elevations[y][x] == 0xF then
n.real_elevation = get_player_elevation()
end
if x == player_x and y == player_y then
if elevations[y][x] == 0xF then
n.elevation = get_player_elevation()
end
start = n
end
if x == dest_x and y == dest_y then
n.is_dest = true
dest = n
end
if elevations[y][x] == 0xF then
for i = 1, 14 do
local sub_n = {x=x, y=y, type=types[y][x], elevation=i, impassable=impassables[y][x], special_tiles=get_special_tiles_around(types, y, x)}
table.insert(allnodes, sub_n)
end
else
table.insert(allnodes, n)
end
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

function check_talking_over(type)
if type == 0x80 then
return true
end
return false
end

function valid_path(node, neighbor)
advance_pathfinder_counter()
for dir = DOWN, RIGHT do
local dir_x, dir_y = decode_direction(dir)
dir_x = dir_x + dir_x
dir_y = dir_y + dir_y
if (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y)
and ((has_talking_over_around(node.special_tiles, dir) and neighbor.is_dest)) then
return true
end
end
if astar.dist_between(node, neighbor) == 1 and neighbor.is_dest then
return true
elseif check_wall(node.type, neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return false
elseif jump_ledge(node.type, neighbor.x - node.x, neighbor.y - node.y)
or jump_ledge(neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return true
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif is_collision(false, node, neighbor) then
return false
else
for dir = DOWN, RIGHT do
local dir_x, dir_y = decode_direction(dir)
if is_game("rse") and is_rotating_gate_collision(neighbor.x, neighbor.y, dir)
and (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y) then
return false
end
end
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
for index = 12, 17 do
local heading = bg[index]
for i = 1, #TEXTBOX_BORDER, 2 do
if heading:find(TEXTBOX_BORDER[i]:sub(1,6))
and heading:find(TEXTBOX_BORDER[i]:sub(#TEXTBOX_BORDER[i]-5,#TEXTBOX_BORDER[i])) then
local startpos = heading:find(TEXTBOX_BORDER[i]:sub(2, 2))
local endpos = heading:find(TEXTBOX_BORDER[i]:sub(#TEXTBOX_BORDER[i], #TEXTBOX_BORDER[i]))
if startpos and endpos then
startpos = startpos -1
if is_textbox(index +1, startpos, endpos, TEXTBOX_BORDER[i]) then
if not get_menu_over_text(index +1, startpos, endpos, TEXTBOX_BORDER[i]) then
return index -1, get_textbox_window_limits(heading, startpos, endpos)
end
end
end
end
end
end
return nil
end

function get_menu_over_text(initpos, startpos, endpos, head)
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

function is_textbox(initpos, startpos, endpos, head)
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
if last_line - initpos <MAX_TEXTBOX_HEIGHT then
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

function get_textbox_window_limits(line, startpos, endpos)
local left, right
for i = startpos +1, #line -2, 2 do
if line:sub(i, i) == line:sub(i +2, i +2) then
left = (i -2) /2
break
end
end
for i = endpos, startpos +3, -2 do
if line:sub(i, i) == line:sub(i -2, i -2) then
right = (i -2) /2
break
end
end
return left, right
end

function get_textbox()
local screen = get_window_screen()
local tile_lines = screen.tile_lines
local lines = {}
local index, startpos, endpos = get_textbox_line()
if index ~= nil then
for i = 0, get_last_window() do
local window = get_window_header(i, false)
if window.top == index +1
and window.left == startpos
and (window.left +(window.width -1) == endpos
-- R/S/E fix
or window.left +(window.width -2) == endpos)
and not window_is_empty(get_window(i)) then
return get_window_text(get_window(i))
end
end
elseif fake_textbox then
local textbox = {}
for _, i in pairs(fake_textbox) do
for _, v in pairs(get_window_text(get_window(i))) do
table.insert(textbox, v)
end
end
return textbox
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
play_tile_sound(get_block_type(blocks[player_y][player_x]), 0, 30, false)
if camera_follow_player then
set_camera_default()
end
end

function show_bg_tilelines()
local bg = get_bg_screen()
for line = 1, #bg do
local showline = ""
for pos = 1, #bg[line] do
showline = showline .. string.format("%02x", bg[line]:sub(pos, pos):byte())
end
controls.inputbox("Result", "", showline)
end
end

function register_common_callbacks()
commands[{"5"}] = {show_bg_tilelines, true, false}
local functions = {
[ROM_CPU_FAST_SET] = cpu_fast_set,
[ROM_CPU_SET] = cpu_set,
[ROM_FREE] = free_memory,
[ROM_RENDER_TEXT] = render_text,
[ROM_RENDER_BRAILLE_TEXT] = render_text,
[ROM_COPY_TO_WINDOW_PIXEL_BUFFER] = copy_to_window_pixel_buffer,
[ROM_FILL_WINDOW_PIXEL_BUFFER] = fill_window_pixel_buffer,
[ROM_FILL_WINDOW_PIXEL_RECT] = fill_window_pixel_rect,
[ROM_SCROLL_WINDOW] = scroll_window,
[ROM_BLIT_BITMAP_RECT_TO_WINDOW] = blit_bitmap_rect_to_window,
[ROM_DRAW_MENU_CURSOR] = draw_menu_cursor,
[ROM_DRAW_GRID_CURSOR] = draw_grid_menu_cursor,
[ROM_DRAW_LIST_CURSOR] = draw_list_menu_cursor,
[ROM_OPTION_MENU_ITEM] = read_option_menu_item,
[ROM_SUBOPTION_MENU_ITEM] = read_suboption_menu_item,
[ROM_MAPNAME_POPUP] = mapname_popup,
[ROM_MAINMENU_SELECT] = read_mainmenu_item,
[ROM_SELECT_HOW_MANY] = read_how_many,
[ROM_ACTION_SELECTION] = read_battle_menu_item,
[ROM_BATTLE_MOVE_SELECTION] = read_battle_move_menu_item,
[ROM_PKMN_SELECTION] = read_pkmn_menu_item,
[ROM_TARGET_SELECTION1] = read_target_menu_item,
[ROM_TARGET_SELECTION2] = read_target_menu_item,
[ROM_BATTLE_YESNO] = read_battle_yesno,
[ROM_STATUS_IN_SUMMARY] = show_status_in_summary,
[ROM_STATUS_INTO_HEALTHBOX] = show_status_in_healthbox,
[ROM_PC_SHOW_POKEMON_DATA] = read_pc_pokemon,
[ROM_DRAW_TEXT_AND_BUFFER_TILES] = draw_text_to_tile_buffer,
[ROM_SHOW_DEPOSIT_BOXES] = read_deposit_box,
[ROM_CHOOSE_DEPOSIT_BOX_RIGHT] = read_deposit_box,
[ROM_CHOOSE_DEPOSIT_BOX_LEFT] = read_deposit_box,
[ROM_FOOTSTEP_FUNCTION] = play_footsteps
}
register_callbacks(functions)
register_callbacks(specific_functions)
end

fake_textbox = nil
tmp_sheet = nil
option_menu_pos = nil
read_option = false
read_suboption = false
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
if  not is_scrolling() and want_read and not unread_text then
read_mapname_if_needed()
read_text(true)
want_read = false
end
end
end
