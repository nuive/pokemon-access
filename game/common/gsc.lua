FRAMES_PRESS_WALK = 4
FRAMES_WALK_FINISH = 12
FRAMES_BIKE_FINISH = 4
SCROLL_INDICATOR_POSITION = 359
HEALTH_BAR = "\x60\x61"
HEALTH_BAR_LIMIT = 0x6b
ENEMY_MAX_HEALTH = 2
BOULDER_SPRITE = 0x5a
old_kbd_col = nil
old_kbd_row = nil
old_puzzle_cursor = nil

function format_names(name)
if name:match("[player]") then
name = string.gsub(name, "%[player]", get_custom_name(RAM_PLAYER_NAME))
end
if name:match("[rival]") then
name = string.gsub(name, "%[rival]", get_custom_name(RAM_RIVAL_NAME))
end
if name:match("[mom]") then
name = string.gsub(name, "%[mom]", get_custom_name(RAM_MOM_NAME))
end
if name:match("[red]") then
name = string.gsub(name, "%[red]", get_custom_name(RAM_RED_NAME))
end
if name:match("[green]") then
name = string.gsub(name, "%[green]", get_custom_name(RAM_GREEN_NAME))
end
return name
end

function get_impassable_tiles()
local ptr = ROM_TILE_FLAGS
for i=0x00, 0xff do
if memory.gbromreadbyte(ptr + i ) % 0x10 ~= 0 then
impassable_tiles[i] = true
else
impassable_tiles[i] = false
end
end
end

function is_cut_tile(tile)
if tile == 0x12 or tile == 0x1a then
return true
end
return false
end

function is_whirlpool_tile(tile)
if tile == 0x24 or tile == 0x2c then
return true
end
return false
end

function is_waterfall_tile(tile)
if (tile >= 0x30 and tile <= 0x33)
or (tile >= 0x38 and tile <= 0x3b) then
return true
end
return false
end

function is_water_tile(tile)
local ptr = ROM_TILE_FLAGS
if memory.gbromreadbyte(ptr + tile ) % 0x10 == 0x01 then
return true
else
return false
end
end

function get_hm_command(tile, last)
local command = ""
local count = true
if is_cut_tile(tile) then
command = message.translate("bush")
elseif is_whirlpool_tile(tile) then
command = message.translate("whirlpool")
elseif is_waterfall_tile(tile) then
if is_waterfall_tile(last) then
command = "$ignore"
else
command = message.translate("waterfall")
end
elseif is_water_tile(tile) and is_waterfall_tile(last) then
command = "$ignore"
elseif is_water_tile(tile) and not is_water_tile(last) and last ~= 0xff then
command = message.translate("enter_water")
count = false
elseif not is_water_tile(tile) and is_water_tile(last) and tile ~= 0xff then
command = message.translate("exit_water")
count = false
end
return command, count
end

function update_impassable_tiles()
local ptr = ROM_TILE_FLAGS
for i=0x00, 0xff do
if is_cut_tile(i) or is_water_tile(i) then
impassable_tiles[i] = not pathfind_hm
end
end
end

function check_talking_over(tile)
if tile == 0x90
or tile == 0x98 then
return true
end
return false
end

function get_map_id()
return memory.readbyte(RAM_MAP_GROUP)*256+memory.readbyte(RAM_MAP_NUMBER)
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
if get_map_id() == 0 
or memory.readbyte(RAM_IN_BATTLE) ~= 0 
or is_unown_puzzle()
or get_textbox_line() ~= nil 
or screen.menu_position ~= nil 
-- RAM_TEXT returns upper left corner value
-- 127 appears to be a blank tile/square, which is displayed in some menus, screen transitions and title screen
-- here to determine screen transitions
or memory.readbyte(RAM_TEXT) == 127 then
return false
else
return true
end
end

function get_warps()
local current_mapid = get_map_id()
local eventstart = memory.readword(RAM_MAP_EVENT_HEADER_POINTER)
local bank = memory.readbyte(RAM_MAP_SCRIPT_HEADER_BANK)
eventstart = ((bank - 1)*16384) + eventstart
local warps = memory.gbromreadbyte(eventstart+2)
local results = {}
local warp_table_start = eventstart+3
for i = 1, warps do
local start = warp_table_start+(5*(i-1))
local warpy = memory.gbromreadbyte(start)
local warpx = memory.gbromreadbyte(start+1)
local mapid = memory.gbromreadbyte(start+3)*256+memory.gbromreadbyte(start+4)
local name = message.translate("warp") .. i
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=warpx, y=warpy, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
end
return results
end

function get_signposts()
local eventstart = memory.readword(RAM_MAP_EVENT_HEADER_POINTER)
local bank = memory.readbyte(RAM_MAP_SCRIPT_HEADER_BANK)
local mapid = get_map_id()
eventstart = ((bank - 1)*16384) + eventstart
local warps = memory.gbromreadbyte(eventstart+2)
local ptr = eventstart + 3 -- start of warp table
ptr = ptr + (warps * 5) -- skip them
-- skip the xy triggers too
local xt = memory.gbromreadbyte(ptr)
ptr = ptr + (xt * 8)+1
local signposts = memory.gbromreadbyte(ptr)
ptr = ptr + 1
-- read out the signposts
local results = {}
for i = 1, signposts do
local posty = memory.gbromreadbyte(ptr)
local postx = memory.gbromreadbyte(ptr+1)
local name = message.translate("signpost") .. i
local post = {x=postx, y=posty, name=name, type="signpost", id="signpost_" .. i}
post.name = get_name(mapid, post)
table.insert(results, post)
ptr = ptr + 5 -- point at the next one
end
return results
end

function get_objects()
local ptr = RAM_MAP_OBJECTS+16 -- skip the player
local liveptr = RAM_LIVE_OBJECTS -- live objects
local results = {}
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
local mapid = get_map_id()
for i = 1, 15 do
local sprite = memory.readbyte(ptr+0x01)
local y = memory.readbyte(ptr+0x02)
local x = memory.readbyte(ptr+0x03)
local facing = memory.readbyte(ptr+0x04)
local object_struct = memory.readbyte(ptr)
-- we have map object structs, and object structs. If the first byte of the
-- map object struct is not 0xff, use that to look up the object struct,
-- and get its coords.
-- if object is on screen and on the map
local l
if object_struct ~= 0xff and y ~= 255 then
l = RAM_OBJECT_STRUCTS+((object_struct-1)*40)
x = memory.readbyte(l+0x12)
y = memory.readbyte(l+0x13)
facing = memory.readbyte(l+0xd)
end
local name = message.translate("object") .. i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
if y ~= 255 and y-4 <= height*2 and x-4 <= width*2 then
if memory.readbyte(liveptr+i) == 0 then
local obj = {x=x-4, y=y-4, name=name, type="object", id="object_" .. i, facing=facing, sprite_id = sprite, ignorable = ignorable}
obj.name = get_name(mapid, obj)
table.insert(results, obj)
end
end
ptr = ptr + 16
end
local collisions = get_map_collisions()
for y = 0, #collisions - 6 do
for x = 0, #collisions[0] - 6 do
if collisions[y][x] == 0x15
or collisions[y][x] == 0x1d then
table.insert(results, {name=message.translate("tree"), x=x, y=y, id="tree_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x91 then
table.insert(results, {name=message.translate("bookshelf"), x=x, y=y, id="bookshelf_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x93 then
table.insert(results, {name=message.translate("pc"), x=x, y=y, id="pc_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x94 then
table.insert(results, {name=message.translate("radio"), x=x, y=y, id="radio_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x95 then
table.insert(results, {name=message.translate("map"), x=x, y=y, id="map_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x96 then
table.insert(results, {name=message.translate("martshelf"), x=x, y=y, id="martshelf_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x97 then
table.insert(results, {name=message.translate("tv"), x=x, y=y, id="tv_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x9d then
table.insert(results, {name=message.translate("window"), x=x, y=y, id="window_" .. y .. x, type="object", ignorable = true})
elseif collisions[y][x] == 0x9f then
table.insert(results, {name=message.translate("incense_burner"), x=x, y=y, id="burner_" .. y .. x, type="object", ignorable = true})
end
end
end
return results
end

function get_connections()
local connections = memory.readbyte(RAM_MAP_CONNECTIONS)
local results = {}
local function add_connection(dir, mapid)
local name = message.translate("connection_to", message.translate(dir))
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = name .. ", " .. mapname
end
table.insert(results, {type="connection", direction=dir, name=name, x=x, y=y, id="connection_" .. dir})
end

if hasbit(connections, NORTH) then
add_connection("north", memory.readbyte(RAM_MAP_NORTH_CONNECTION)*256+memory.readbyte(RAM_MAP_NORTH_CONNECTION+1))
end
if hasbit(connections, SOUTH) then
add_connection("south", memory.readbyte(RAM_MAP_SOUTH_CONNECTION)*256+memory.readbyte(RAM_MAP_SOUTH_CONNECTION+1))
end
if hasbit(connections, EAST) then
add_connection("east", memory.readbyte(RAM_MAP_EAST_CONNECTION)*256+memory.readbyte(RAM_MAP_EAST_CONNECTION+1))
end
if hasbit(connections, WEST) then
add_connection("west", memory.readbyte(RAM_MAP_WEST_CONNECTION)*256+memory.readbyte(RAM_MAP_WEST_CONNECTION+1))
end
return results
end

function get_map_collisions()
local blocks = get_map_blocks()
local width = #blocks[0]
local collisions = {}
function add_collision(x, y, type)
collisions[y] = collisions[y] or {}
collisions[y][x] = type
end
local collision_bank = memory.readbyteunsigned(RAM_COLLISION_BANK)
local collision_addr = memory.readword(RAM_COLLISION_ADDR)
collision_addr = ((collision_bank - 1) * 16384) + collision_addr

for y = -3, #blocks do
for x = -3, width do
-- Each block is a 2x2 walkable tile. The collision data is
-- (top left, top right, bottom left, bottom right).
-- We have block data for the first half of the xy pair here.
local block_index = blocks[y][x]
local ptr = collision_addr + (block_index * 0x04)
add_collision(x*2, y*2, memory.gbromreadbyte(ptr))
add_collision(x*2+1, y*2, memory.gbromreadbyte(ptr+1))
add_collision(x*2, y*2+1, memory.gbromreadbyte(ptr+2))
add_collision(x*2+1, y*2+1, memory.gbromreadbyte(ptr+3))
end -- x
end -- y
return collisions
end

function is_collision(collisions, y, x)
return impassable_tiles[collisions[y][x]]
end

function get_special_tiles_around(collisions, y, x)
local result = 0
local tile = collisions[y][x]
for dir = DOWN, RIGHT, 4 do
local dir_x, dir_y = decode_direction(dir)
dir_x = x + dir_x
dir_y = y + dir_y
if check_coordinates_on_screen(dir_x, dir_y) then
if check_talking_over(collisions[dir_y][dir_x]) then
result = result + bit.lshift(1, bit.rshift(dir, 2))
end
end
end
return result
end

function jump_ledge(tile, x, y)
if tile < 0xa0 or tile > 0xaf then
return false
end
if y == 0 then
if x == 2
and (tile == 0xa0
or tile == 0xa4
or tile == 0xa6) then
return true
elseif x == -2
and (tile == 0xa1
or tile == 0xa5
or tile == 0xa7) then
return true
end
elseif x == 0 then
if y == -2
and (tile == 0xa2
or tile == 0xa6
or tile == 0xa7) then
return true
elseif y == 2
and (tile == 0xa3
or tile == 0xa4
or tile == 0xa5) then
return true
end
end
return false
end

function is_wall_tile(tile, dir)
if tile < 0xb0 or tile > 0xcf then
return false
end
if dir == RIGHT
and (tile == 0xb0 or tile == 0xc0
or tile == 0xb4 or tile == 0xc4
or tile == 0xb6 or tile == 0xc6) then
return true
elseif dir == LEFT
and (tile == 0xb1 or tile == 0xc1
or tile == 0xb5 or tile == 0xc5
or tile == 0xb7 or tile == 0xc7) then
return true
elseif dir == UP
and (tile == 0xb2 or tile == 0xc2
or tile == 0xb6 or tile == 0xc6
or tile == 0xb7 or tile == 0xc7) then
return true
elseif dir == DOWN
and (tile == 0xb3 or tile == 0xc3
or tile == 0xb4 or tile == 0xc4
or tile == 0xb5 or tile == 0xc5) then
return true
end
return false
end

valid_path = function (node, neighbor)
for dir = DOWN, RIGHT, 4 do
local dir_x, dir_y = decode_direction(dir)
dir_x = dir_x + dir_x
dir_y = dir_y + dir_y
if (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y)
and ((has_talking_over_around(node.special_tiles, dir) and neighbor.is_dest)) then
return true
end
end
if jump_ledge(node.type, neighbor.x - node.x, neighbor.y - node.y) then
return true
elseif is_wall_tile(node.type, encode_direction(neighbor.x - node.x, neighbor.y - node.y)) or is_wall_tile(neighbor.type, encode_direction(node.x - neighbor.x, node.y - neighbor.y)) then
return false
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif astar.dist_between(node, neighbor) == 1 and neighbor.is_dest then
return true
elseif impassable_tiles[neighbor.type] then
return false
end
return true
end -- valid

function play_tile_sound(type, pan, vol, is_camera)
	if type == 0x10
	or type == 0x14
	or type == 0x18
	or type == 0x1c
	or (type >= 0x48 and type <= 0x4c) then
		audio.play(scriptpath .. "sounds\\s_grass.wav", 0, pan, vol)
	elseif is_cut_tile(type) then
		audio.play(scriptpath .. "sounds\\s_cut.wav", 0, pan, vol)
	elseif type == 0x23
	or type == 0x2b then
		audio.play(scriptpath .. "sounds\\s_ice.wav", 0, pan, vol)
	elseif is_whirlpool_tile(type) then
		audio.play(scriptpath .. "sounds\\s_whirl.wav", 0, pan, vol)
	elseif is_waterfall_tile(type) then
		audio.play(scriptpath .. "sounds\\s_waterfall.wav", 0, pan, vol)
	elseif is_water_tile(type) then
		audio.play(scriptpath .. "sounds\\s_water.wav", 0, pan, vol)
	elseif (type >= 0xa0 and type < 0xb0) then
		audio.play(scriptpath .. "sounds\\s_mad.wav", 0, pan, vol)
	elseif is_camera and (type >= 0x70 and type < 0x80) then
		audio.play(scriptpath .. "sounds\\s_stair.wav", 0, pan, vol)
	elseif is_camera and (type == 0x60
	or type == 0x68) then
		audio.play(scriptpath .. "sounds\\s_hole.wav", 0, pan, vol)
	else
		audio.play(scriptpath .. "sounds\\s_default.wav", 0, pan, vol)
	end -- switch tile type
end

function keyboard_showing(screen)
if screen.lines[17]:match(KEYBOARD_STRING) ~= nil then
return true
end
return false
end

function handle_keyboard()
col = memory.readbyte(RAM_KEYBOARD_X)
row = memory.readbyte(RAM_KEYBOARD_Y)
if row ~= old_kbd_row or col ~= old_kbd_col then
read_keyboard()
old_kbd_row = row
old_kbd_col = col
end -- if the row/col changed
end -- handle_keyboard

function read_keyboard()
local x = memory.readbyte(RAM_KEYBOARD_X)
local y = memory.readbyte(RAM_KEYBOARD_Y)
local t = KEYBOARD_UPPER
if screen.lines[17]:match(KEYBOARD_UPPER_STRING) ~= nil then
t = KEYBOARD_LOWER
end
local word = t[y+1][x+1] or message.translate("unknown")
tolk.output(word)
end

function read_special_variable_text()
-- hour set fix
if screen.tile_lines[8]:find("\x7a\x01\x7a") then
tolk.output(translate_tileline(screen.tile_lines[10]))
end
-- day set fix
if screen.tile_lines[4]:find("\x7a\xef\x7a") then
tolk.output(translate_tileline(screen.tile_lines[6]))
end
-- Fly destination fix
if screen.tile_lines[1]:find("\xe6\x7f") then
tolk.output(translate_tileline(screen.tile_lines[2]))
end
-- pc boxes fix
local textbox_top, textbox_bottom = get_textbox_border(10)
if screen.menu_position == nil
and screen.tile_lines[1]:find(textbox_top)
and screen.tile_lines[14]:find(textbox_bottom) then
local result = trim(translate_tileline(screen.tile_lines[15]) .. translate_tileline(get_menu_item(screen.tile_lines[13], 1, 9)))
local i = 13
while result == "" do
result = trim(translate_tileline(get_menu_item(screen.tile_lines[i], 10, 19)))
i = i - 1
end
tolk.output(result)
end
end

function is_unown_puzzle()
for i = 1, 18 do
if screen.tile_lines[i]:sub(1, 1) ~= "\xee" or screen.tile_lines[i]:sub(20, 20) ~= "\xee" then
return false
end
end
return true
end

function handle_puzzle()
puzzle_cursor = memory.readbyte(RAM_PUZZLE_CURSOR)
if old_puzzle_cursor == nil and puzzle_cursor ~= 0 then
return
end
if puzzle_cursor ~= old_puzzle_cursor then
local piece = string.format("%d", memory.readbyte(RAM_UNOWN_PUZZLE+puzzle_cursor))
tolk.output(piece)
old_puzzle_cursor = puzzle_cursor
end
end

function read_holding_piece()
if is_unown_puzzle() then
if memory.readbyte(RAM_PUZZLE_CURSOR-1) ~= 0 then
tolk.output(string.format("%d", memory.readbyte(RAM_PUZZLE_CURSOR+1)))
else
tolk.output(message.translate("unown_puzzle_pick_piece"))
end
end
end

function get_frames_press_walk()
return FRAMES_PRESS_WALK
end

function get_frames_walk_finish()
local ptr = RAM_MAP_OBJECTS 
local sprite = memory.readbyte(ptr+0x01)
-- 0x02 and 0x61 are player bike sprites
if sprite == 0x02 or sprite == 0x61 then
return FRAMES_BIKE_FINISH
end
return FRAMES_WALK_FINISH
end

function handle_special_cases()
if screen:keyboard_showing() then
handle_keyboard()
else
old_kbd_col = nil
old_kbd_row = nil
end
if is_unown_puzzle() then
local tip = message.translate("unown_puzzle_tip")
if last_textbox_text ~= tip then
tolk.output(tip)
last_textbox_text = tip
end
handle_puzzle()
else
old_puzzle_cursor = nil
end
end

memory.registerexec((ROM_FOOTSTEP_FUNCTION%0x4000)+0x4000, function()
if memory.readbyte(HRAM_ROM_BANK) == math.floor(ROM_FOOTSTEP_FUNCTION / 0x4000) then
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local type = collisions[player_y][player_x]
camera_x = -7
camera_y = -7
play_tile_sound(type, 0, 30, false)
end
end)

-- additional commands
commands[{"D", "shift"}] = {read_holding_piece, false}

-- initialize tables based in rom values
get_impassable_tiles()

