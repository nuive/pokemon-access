require "a-star"
serpent = require "serpent"
message = require "message"
local inputbox = require "Inputbox"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("^.*\\")
LINE = 1
COLUMN = 2
EAST = 0
WEST = 1
SOUTH = 2
NORTH = 3
DOWN = 0
UP = 4
LEFT = 8
RIGHT = 12
TEXTBOX_PATTERN = "\x79\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7a\x7b"
camera_x = -7
camera_y = -7
last_camera_tile = 0xff
pathfind_hm = false
inpassible_tiles, ledge_tiles, land_collision_pairs, water_collision_pairs, water_tilesets, water_tiles, mansion_cliffs= {}
cut_tiles = {
[0] = 0x3d,
[7] = 0x50,
}
preledge_tile = false
block_move = {
[0x07] = {
[0] = {0x4c, 0x4d, 0x4c, 0x4d},
[4] = {0x3c, 0x3d, 0x3c, 0x3d},
[8] = {0x3c, 0x3c, 0x4c, 0x4c},
[12] = {0x3d, 0x3d, 0x4d, 0x4d}
},
[0x16] = {
[0] = {0x20, 0x30, 0x20, 0x30},
[4] = {0x21, 0x31, 0x21, 0x31},
[8] = {0x21, 0x21, 0x20, 0x20},
[12] = {0x31, 0x31, 0x30, 0x30}
}
}


function load_language(code)
local path = scriptpath .. "\\lang\\" .. code .. "\\"
local t = {"chars.lua", "fonts.lua", "maps.lua", "ram.lua", "sprites.lua", "strings.lua"}
for i, v in ipairs(t) do
local f = loadfile(path .. v)
if f ~= nil then
f()
end
end
message.set_strings(strings)
end
load_language("en")

function is_printable_screen()
local s = ""
for i = 0, 15 do
s = s .. string.char(memory.readbyte(RAM_SCREEN+i))
end
if fonts[s] then
return true
else
return false
end
end

function load_table(file)
local res, t
fp = io.open(file, "rb")
if fp ~= nil then
local data = fp:read("*all")
res, t = serpent.load(data)
io.close(fp)
end
return res, t
end

function translate(char)
if chars[char] then
return chars[char]
else
return " "
end
end

function get_screen()
local raw_text = memory.readbyterange(RAM_TEXT, 360)
local lines = {}
local tile_lines = {}
local line = ""
local tile_line = ""
local menu_position = nil
local text_over_menu = false
local line_number = 0
local printable = is_printable_screen()
for i = 1, 360, 20 do
line_number = line_number + 1
for j = 0, 19 do
local char = raw_text[i+j]
tile_line = tile_line .. string.char(char)
if char == 0xed then
menu_position = {((i-1)/20)+1, j+1}
elseif char == 0xec then
text_over_menu = true
end
if i+j == 239 and char == 0xee then
char = 0x7f
elseif i+j == 339 and char == 0xee then
char = 0x7f
end
if printable then
char = translate(char)
else
char = " "
end
line = line .. char
end
table.insert(lines, line)
table.insert(tile_lines, tile_line)
line = ""
tile_line = ""
end -- i
-- mart fix
if menu_position == nil then
if tile_lines[11]:match("\x7c\xf1") then
menu_position = {11, tile_lines[11]:find("\x7c\xf1")+1}
end
end
return {lines=lines, menu_position=menu_position, text_over_menu=text_over_menu, tile_lines=tile_lines, keyboard_showing=keyboard_showing,
get_outer_menu_text=get_outer_menu_text, get_textbox=get_textbox}
end

last17 = ""
last_textbox_text = nil
function read_text(auto)
local lines = get_screen().lines
if auto then
if trim(lines[15]) == trim(last17) then
lines[15] = ""
end
last17 = lines[17]
local textbox = get_textbox()
if textbox and should_read_textbox() then
textbox_text = table.concat(textbox, "")
if textbox_text ~= last_textbox_text then
output_lines(textbox)
end
last_textbox_text = textbox_text
return
else -- no textbox here
last_textbox_text = nil
end -- textbox
end -- auto
output_lines(lines)
end

function should_read_textbox()
if screen.text_over_menu
or screen.tile_lines[2]:match("\xf0")
or screen.tile_lines[3]:match("\x71\x62")
or screen.tile_lines[10]:match("\x71\x62") then
return true
end
return false
end

function output_lines(lines)
for i, line in pairs(lines) do
line = trim(line)
if line ~= "" then
tolk.output(line)
end
end
end -- output_lines

function trim(s)
return s:gsub("^%s*(.-)%s*$", "%1")
end

function generate_menu_header()
local screen = get_screen()
local results = {}
local tile_lines = screen.tile_lines
results.start_y = 1
results.start_x = 1
results.end_y = 18
results.end_x = 20
results.has_left_border = false
results.has_right_border = false
local y = screen.menu_position[LINE]
local x = screen.menu_position[COLUMN]
local byte = tile_lines[y]:sub(x,x):byte()
while x > 0 and byte ~= 0x7c do
x = x - 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x7c then
while y > 0 and byte ~= 0x79 and byte ~= 0x7a do
y = y - 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x79 or byte == 0x7a then
results.start_y = y
results.start_x = x
results.has_left_border = true
end
end
y = screen.menu_position[LINE]
x = screen.menu_position[COLUMN]
byte = tile_lines[y]:sub(x,x):byte()
while x <= 20 and byte ~= 0x7c do
x = x + 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x7c then
while y <= 18 and byte ~= 0x7e and byte ~= 0x7a do
y = y + 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x7e or byte == 0x7a then
results.end_y = y
results.end_x = x
results.has_right_border = true
end
end
return results
end

function get_outer_menu_text(screen)
local textbox = screen:get_textbox()
if textbox then
return trim(table.concat(textbox, " "))
end
local header = generate_menu_header()
local lines = screen.lines
local s = ""
for i = header.end_y+1, 18 do
local line = trim(lines[i])
if i == 15 and line == trim(last17) then
line = ""
end
if line ~= "" then
s = s .. line .. "\n"
end
end
return s
end

function read_coords()
local x, y = get_player_xy()
tolk.output("x " .. x .. ", y " .. y)
end

function read_camera()
local x, y = get_camera_xy()
tolk.output("x " .. x .. ", y " .. y)
end

function get_warps()
local current_mapid = get_map_id()
local eventstart = memory.readword(RAM_MAP_EVENT_POINTER)
local bank = memory.readbyte(RAM_SAVED_BANK)
eventstart = ((bank - 1) *16384) + eventstart
local warps = memory.gbromreadbyte(eventstart+1)
local results = {}
local warp_table_start = eventstart+2
for i = 1, warps do
local start = warp_table_start+(4*(i-1))
local warpy = memory.gbromreadbyte(start)
local warpx = memory.gbromreadbyte(start+1)
local mapid = memory.gbromreadbyte(start+3)
if mapid == 0xff then
mapid = memory.readbyte(RAM_LAST_MAP_OUTDOORS)
end
local name = message.translate("warp") .. i
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=warpx, y=warpy, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
end
-- special Pokemon Mansion situation
if memory.readbyte(RAM_MAP_NUMBER) == 0xd7 then
for _, v in ipairs(mansion_cliffs) do
table.insert(results, {x=v[2], y=v[1], name=message.translate("cliff"), type="warp", id="cliff_" .. v[1] .. v[2]})
end
end
return results
end

function get_signposts()
local eventstart = memory.readword(RAM_MAP_EVENT_POINTER)
local bank = memory.readbyte(RAM_SAVED_BANK)
eventstart = ((bank - 1)*16384) + eventstart
local mapid = get_map_id()
local warps = memory.gbromreadbyte(eventstart+1)
local ptr = eventstart + 2 -- start of warp table
ptr = ptr + (warps * 4) -- skip them
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
ptr = ptr + 3 -- point at the next one
end
return results
end

function get_name(mapid, obj)
return (names[mapid] or {})[obj.id] or obj.name
end

function format_names(name)
name = string.gsub(name, "%[player]", get_custom_name(RAM_PLAYER_NAME))
name = string.gsub(name, "%[rival]", get_custom_name(RAM_RIVAL_NAME))
return name
end

function get_objects()
local function get_missable()
local results = {}
local ptr = RAM_MISSABLE_OBJECTS
while memory.readbyte(ptr) ~= 0xff do
local index = memory.readbyte(ptr)
results[index] = memory.readbyte(ptr+1)
ptr = ptr + 2
end
return results
end
local function is_missable(index)
local flag = index % 8
local flag_byte = memory.readbyte(RAM_MISSABLE_FLAGS + bit.rshift(index, 3))
return hasbit(flag_byte, flag)
end
local ptr = RAM_MAP_OBJECTS+16 -- skip the player
local missable = get_missable()
local results = {}
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
local mapid = get_map_id()
for i = 1, 15 do
local ignorable = false
local sprite = memory.readbyte(ptr)
local on_screen = memory.readbyte(ptr+0x02)
local y = memory.readbyte(ptr+0x104)
local x = memory.readbyte(ptr+0x105)
local facing = memory.readbyte(ptr+0x09)
-- missable objects
if missable[i] ~= nil and is_missable(missable[i]) then
sprite = 0
end
-- special Pikachu situation
if i == 15 then
if on_screen == 0xff then
sprite = 0
elseif sprite == 0x49 then
sprite = 0x3d
ignorable = true
end
end
if sprite ~= 0 then
local name = message.translate("object") .. i .. string.format(", %x", sprite)
if sprites[sprite] ~= nil then
name = format_names(sprites[sprite])
end
if y-4 <= height*2 and x-4 <= width*2 then
local obj = {x=x-4, y=y-4, name=name, type="object", id="object_" .. i, facing=facing, sprite_id = sprite, ignorable = ignorable}
obj.name = get_name(mapid, obj)
table.insert(results, obj)
end
end
ptr = ptr + 16
end
local map = memory.readbyte(RAM_MAP_NUMBER)
local collisions = get_map_collisions()
local tileset_number = memory.readbyte(RAM_MAP_HEADER)
for y = 0, #collisions do
for x = 0, #collisions[0] do
if (tileset_number == 0x04 and collisions[y][x] == 0x32)
or (tileset_number == 0x06 and collisions[y][x] == 0x52)
or (tileset_number == 0x10 and collisions[y][x] == 0x1b) then
table.insert(results, {name=message.translate("pc"), x=x, y=y, id="pc_" .. y .. x, type="object"})
elseif (tileset_number == 0x0d and collisions[y][x] == 0x58)
or (tileset_number == 0x07 and collisions[y][x] == 0x1b) then
table.insert(results, {name=message.translate("trashcan"), x=x, y=y, id="trashcan_" .. y .. x, type="object"})
elseif (tileset_number == 0x16 and (collisions[y][x] == 0x24 or collisions[y][x] == 0x18))
or (tileset_number == 0x10 and collisions[y][x] == 0x5e) then
table.insert(results, {name=message.translate("closed_door"), x=x, y=y, id="closeddoor_" .. y .. x, type="object"})
elseif (tileset_number == 0x16 and collisions[y][x] == 0x3d) then
table.insert(results, {name=message.translate("statue"), x=x, y=y, id="statue_" .. y .. x, type="object"})
-- special cinnabar gym
elseif (map == 0xa6 and tileset_number == 0x16 and (collisions[y][x] == 0x4c and collisions[y][x-1] ~= 0x4c and collisions[y][x+2] ~= 0x4c)) then
table.insert(results, {name=message.translate("quiz"), x=x, y=y, id="quiz_" .. y .. x, type="object"})
end
end
end
return results
end

function compareTables(table1, table2)
	for k, v in pairs(table1) do
		if table2[k] ~= v then
			return false
		end
	end

	for k, v in pairs(table2) do
		if table1[k] ~= v then
			return false
		end
	end

	return true
end

function hasbit(x, p)
return bit.rshift(x, p) % 2 ~= 0
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
add_connection("north", memory.readbyte(RAM_MAP_NORTH_CONNECTION))
end
if hasbit(connections, SOUTH) then
add_connection("south", memory.readbyte(RAM_MAP_SOUTH_CONNECTION))
end
if hasbit(connections, EAST) then
add_connection("east", memory.readbyte(RAM_MAP_EAST_CONNECTION))
end
if hasbit(connections, WEST) then
add_connection("west", memory.readbyte(RAM_MAP_WEST_CONNECTION))
end
return results
end

function get_map_name(mapid)
if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
return format_names(names[mapid]["map"])
elseif maps[mapid] ~= nil then
return format_names(maps[mapid])
else
return message.translate("map") .. mapid
end
end

function get_map_info()
local mapnumber = get_map_gn()
local results = {number=mapnumber, objects={}}
for i, warp in ipairs(get_warps()) do
table.insert(results.objects, warp)
end
for i, signpost in ipairs(get_signposts()) do
table.insert(results.objects, signpost)
end
for i, connection in ipairs(get_connections()) do
table.insert(results.objects, connection)
end
for i, object in ipairs(get_objects()) do
table.insert(results.objects, object)
end
return results
end

function get_map_gn()
return memory.readbyte(RAM_MAP_NUMBER)
end

function get_map_id()
return get_map_gn()
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
local mapnumber = get_map_gn()
if mapnumber == 0xff or memory.readbyte(RAM_IN_BATTLE) ~= 0 then
return false
else
return true
end
end

function direction(x, y, destx, desty)
local s = ""
if y > desty then
s = y-desty .. " " .. message.translate("up")
elseif y < desty then
s = desty-y .. " " .. message.translate("down")
end
if x > destx then
s = s .. " " .. x-destx .. " " .. message.translate("left")
elseif x < destx then
s = s .. " " .. destx-x .. " " .. message.translate("right")
end
return s
end

function only_direction(x, y, destx, desty)
local s = ""
if y > desty then
return message.translate("up")
elseif y < desty then
return message.translate("down")
elseif x > destx then
return message.translate("left")
elseif x < destx then
return message.translate("right")
end
return s
end

-- Read current and around tiles
function read_tiles()
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local s = message.translate("now_on") .. string.format("%d, ", collisions[player_y][player_x])

-- Check up tile
if player_y >= 0 then
	s = s .. message.translate("up") .. string.format("%d, ", collisions[player_y - 1][player_x])
end -- Check up tile

-- Check down tile
if player_y <= #collisions then
	s = s .. message.translate("down") .. string.format("%d, ", collisions[player_y + 1][player_x])
end -- Check down tile

-- Check left tile
if player_x >= 0 then
	s = s .. message.translate("left") .. string.format("%d, ", collisions[player_y][player_x - 1])
end -- Check left tile

-- Check right tile
if player_x <= #collisions[0] then
	s = s .. message.translate("right") .. string.format("%d", collisions[player_y][player_x + 1])
end -- Check right tile

tolk.output(s)
end

function is_block_arrow(tileset, dir)
if block_move[tileset] ~= nil then
return compareTables(get_additional_collision_data(), block_move[tileset][dir])
end
return false
end

-- Playback tile sounds
function play_tile_sound(type, pan, vol, is_camera)
local tileset = memory.readbyte(RAM_MAP_HEADER)
	if type == memory.readbyte(RAM_GRASS_TILE) then
		audio.play(scriptpath .. "sounds\\s_grass.wav", 0, pan, vol)
	elseif is_cut_tile(type) then
		audio.play(scriptpath .. "sounds\\s_cut.wav", 0, pan, vol)
	elseif is_water_tile(type) then
		audio.play(scriptpath .. "sounds\\s_water.wav", 0, pan, vol)
	elseif is_block_arrow(tileset, DOWN) then
		audio.play(scriptpath .. "sounds\\s_move_down.wav", 0, pan, vol)
elseif is_block_arrow(tileset, UP) then
		audio.play(scriptpath .. "sounds\\s_move_up.wav", 0, pan, vol)
elseif is_block_arrow(tileset, LEFT) then
		audio.play(scriptpath .. "sounds\\s_move.wav", 0, -100, vol)
elseif is_block_arrow(tileset, RIGHT) then
		audio.play(scriptpath .. "sounds\\s_move.wav", 0, 100, vol)
elseif is_camera and ((tileset == 0x16 and type == 0x5e)
or (tileset == 0x07 and type == 0x3f)) then
		audio.play(scriptpath .. "sounds\\no_pass.wav", 0, pan, vol)
-- 	elseif type == 0x23 then
-- 		audio.play(scriptpath .. "sounds\\s_ice.wav", 0, pan, vol)
-- 	elseif type == 0x24 then
-- 		audio.play(scriptpath .. "sounds\\s_whirl.wav", 0, pan, vol)
-- 	elseif type == 0x29 then
-- 		audio.play(scriptpath .. "sounds\\s_water.wav", 0, pan, vol)
-- 	elseif type == 0x33 then
-- 		audio.play(scriptpath .. "sounds\\s_waterfall.wav", 0, pan, vol)
	elseif is_camera and (type == 0x13) then
		audio.play(scriptpath .. "sounds\\s_stairup.wav", 0, pan, vol)
	elseif is_camera and (type == 0x1b) then
		audio.play(scriptpath .. "sounds\\s_stairdown.wav", 0, pan, vol)
	elseif is_camera and tileset == 0x11 and type == 0x22 then
		audio.play(scriptpath .. "sounds\\s_hole.wav", 0, pan, vol)
	elseif is_camera and tileset == 0x11 and type == 0x2d then
		audio.play(scriptpath .. "sounds\\s_switch.wav", 0, pan, vol)
	else
		audio.play(scriptpath .. "sounds\\s_default.wav", 0, pan, vol)
	end -- switch tile type
if preledge_tile then
audio.play(scriptpath .. "sounds\\s_mad.wav", 0, pan, vol)
preledge_tile = false
end
end

-- reset camera focus when camera_xy outside map
function reset_camera_focus(player_x, player_y)
	if camera_x == -7 and camera_y == -7 then
		camera_x = player_x
		camera_y = player_y
last_camera_tile = 0xff
	end
end

function check_coordinates_on_screen(x, y)
if x >= -6 and y >= -6
and x <= memory.readbyte(RAM_MAP_WIDTH)*2 + 5 and y <= memory.readbyte(RAM_MAP_HEIGHT)*2 + 5 then
return true
end
return false
end

function check_talking_over(tile)
ptr = RAM_PASSIBLE_TILES+2
while ptr < RAM_GRASS_TILE and memory.readbyte(ptr) ~= 0xff do
if tile == memory.readbyte(ptr) then
return true
end
ptr = ptr + 1
end
return false
end

function encode_direction(x, y)
if x == 0 then
if y == 1 then
return DOWN
elseif y == -1 then
return UP
end
end
if y == 0 then
if x == -1 then
return LEFT
elseif x == 1 then
return RIGHT
end
end
return -1
end

function decode_direction(dir)
local x = 0
local y = 0
if dir == DOWN then
y = 1
elseif dir == UP then
y = -1
elseif dir == LEFT then
x = -1
elseif dir == RIGHT then
x = 1
end
return x, y
end

function get_rom_table(ptr, dimension)
local results = {}
while memory.gbromreadbyte(ptr) ~= 0xff do
if dimension > 1 then
local row = {}
for i = 0, dimension - 1 do
table.insert(row, memory.gbromreadbyte(ptr+i))
end
table.insert(results, row)
else
table.insert(results, memory.gbromreadbyte(ptr))
end
ptr = ptr + dimension
end
return results
end

function check_collision_pair(tileset, tile, next_tile)
-- land collisions
for _, v in ipairs(land_collision_pairs) do
if tileset == v[1] then
local pair1 = v[2]
local pair2 = v[3]
if (tile == pair1 and next_tile == pair2)
or (tile == pair2 and next_tile == pair1) then
return true
end
end
end
-- water collisions
for _, v in ipairs(water_collision_pairs) do
if tileset == v[1] then
local pair1 = v[2]
local pair2 = v[3]
if (tile == pair1 and next_tile == pair2)
or (tile == pair2 and next_tile == pair1) then
return true
end
end
end
return false
end

function check_ledge(tile, next_tile, dir)
for _, v in ipairs(ledge_tiles) do
if dir == v[1] and tile == v[2] and next_tile == v[3] then
return true
end
end
return false
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
if check_ledge(tile, collisions[dir_y][dir_x], dir) then
result = result + bit.lshift(1, bit.rshift(dir, 2) + 4)
end
end
end
return result
end

function has_preledge_around(value, dir)
if hasbit(value, bit.rshift(dir, 2) + 4) then
return true
end
return false
end

function has_talking_over_around(value, dir)
if hasbit(value, bit.rshift(dir, 2)) then
return true
end
return false
end

function check_preledge(collisions, y, x)
if bit.rshift(get_special_tiles_around(collisions, y, x), 4) ~= 0 then
return true
end
return false
end

-- Moving camera focus
function camera_move(y, x, ignore_wall)
	local player_x, player_y = get_player_xy()
	reset_camera_focus(player_x, player_y)
	camera_y = camera_y + y
	camera_x = camera_x + x

	local collisions = get_map_collisions()
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

	if camera_y >= -6 and camera_x >= -6 and camera_y <= #collisions and camera_x <= #collisions[1] then
		local objects = get_objects()
		for i, obj in pairs(objects) do
			if obj.x == camera_x and obj.y == camera_y then
				if obj.sprite_id == 73 then
					audio.play(scriptpath .. "sounds\\s_boulder.wav", 0, pan, vol)
				end -- sprite_id
			end -- obj.xy
		end -- for --]]

preledge_tile = check_preledge(collisions, camera_y, camera_x)
		if inpassible_tiles[collisions[camera_y][camera_x]] or check_collision_pair(memory.readbyte(RAM_MAP_HEADER), last_camera_tile, collisions[camera_y][camera_x]) then
			if ignore_wall then
				camera_x = camera_x - x
				camera_y = camera_y - y
			end
			audio.play(scriptpath .. "sounds\\s_wall.wav", 0, pan, vol)
		else
			audio.play(scriptpath .. "sounds\\pass.wav", 0, pan, vol)
			play_tile_sound(collisions[camera_y][camera_x], pan, vol, true)
		end
		last_camera_tile = collisions[camera_y][camera_x]
	else
		camera_x = camera_x - x
		camera_y = camera_y - y
		audio.play(scriptpath .. "sounds\\s_wall.wav", 0, pan, vol)
	end
end

function set_camera_default()
	camera_x = -7
	camera_y = -7
	camera_move(0, 0, true)
end

function camera_move_left()
	camera_move(0, -1, true)
end

function camera_move_right()
	camera_move(0, 1, true)
end

function camera_move_up()
	camera_move(-1, 0, true)
end

function camera_move_down()
	camera_move(1, 0, true)
end

function camera_move_left_ignore_wall()
	camera_move(0, -1, false)
end

function camera_move_right_ignore_wall()
	camera_move(0, 1, false)
end

function camera_move_up_ignore_wall()
	camera_move(-1, 0, false)
end

function camera_move_down_ignore_wall()
	camera_move(1, 0, false)
end

function compare(t1, t2)
if #t1 ~= #t2 then
return false
end
for i, v in ipairs(t1) do
if t1[i] ~= t2[i] then
return false
end
end
return true
end

old_pressed_keys = {}
function handle_user_actions()
local kbd = input.read()
local pressed_keys = {}
kbd.xmouse = nil
kbd.ymouse = nil
for k, v in pairs(kbd) do
if v then
table.insert(pressed_keys, k)
end
end
table.sort(pressed_keys)

if #pressed_keys == 0 or compare(pressed_keys, old_pressed_keys) then
old_pressed_keys = pressed_keys
return
end
old_pressed_keys = pressed_keys
local command
for keys, cmd in pairs(commands) do
if compare(keys, pressed_keys) then
command = cmd
break
end
end
if command == nil then
return
end
tolk.silence()
local fn, needs_map = unpack(command)
if needs_map and not on_map() then
tolk.output(message.translate("not_map"))
else
fn(args)
end -- not on map
end

function read_current_item()
local info = get_map_info()
reset_current_item_if_needed(info)
read_item(info.objects[current_item])
end

function reset_current_item_if_needed(info)
if info.number ~= current_map then
current_item = 1
current_map = info.number
elseif info.objects[current_item] == nil then
current_item = 1
end
end

function read_next_item()
local info = get_map_info()
reset_current_item_if_needed(info)
current_item = current_item + 1
if current_item > #info.objects then
current_item = 1
end
read_current_item()
end

function read_previous_item()
local info = get_map_info()
reset_current_item_if_needed(info)
current_item = current_item - 1
if current_item == 0  or current_item > #info.objects then
current_item = #info.objects
end
read_current_item()
end

function set_pathfind_hm()
	pathfind_hm = not pathfind_hm
update_inpassible_hm()
	if pathfind_hm then
		tolk.output(message.translate("use_hm"))
	else
		tolk.output(message.translate("not_use_hm"))
	end
end

function pathfind()
local info = get_map_info()
reset_current_item_if_needed(info)
local obj = info.objects[current_item]
find_path_to(obj)
end

function read_item(item)
local x, y = get_player_xy()
local map_id = get_map_id()
local s = get_name(mapid, item)
if item.x then
s = s .. ": " .. direction(x, y, item.x, item.y) .. "; "
end
if item.facing then
s = s .. message.translate("facing") .. " " .. facing_to_string(item.facing)
end
tolk.output(s)
end

function get_map_blocks()
-- map width, height in blocks
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)
local row_width = width+6 -- including border
ptr = RAM_MAP -- start of overworld
-- there is a border of 3 blocks on each edge of the map.
local blocks = {}
for y = -3, height + 2 do
for x = -3, width + 2 do
local block = memory.readbyteunsigned(ptr+((y+3)*row_width)+(x+3))
blocks[y] = blocks[y] or {}
blocks[y][x] = block
end
end
return blocks
end

function is_cut_tile(tile)
local tileset = memory.readbyte(RAM_MAP_HEADER)
if cut_tiles[tileset] ~= nil and cut_tiles[tileset] == tile then
return true
end
return false
end

function is_water_tile(tile)
local tileset = memory.readbyte(RAM_MAP_HEADER)
for _, v in ipairs(water_tilesets) do
if tileset == v then
local tile_start = 1
if tileset == 0x05 or tileset == 0x07 or tileset == 0x0e then
tile_start = tile_start + 2
end
for i = tile_start, #water_tiles do
if tile == water_tiles[i] then
return true
end
end
end
end
return false
end

function update_inpassible_hm()
local tileset = memory.readbyte(RAM_MAP_HEADER)
-- cut tiles
if cut_tiles[tileset] ~= nil then
inpassible_tiles[cut_tiles[tileset]] = not pathfind_hm
end
-- water tiles
for _, v in ipairs(water_tilesets) do
if tileset == v then
local tile_start = 1
if tileset == 0x05 or tileset == 0x07 or tileset == 0x0e then
tile_start = tile_start + 2
end
for i = tile_start, #water_tiles do
inpassible_tiles[water_tiles[i]] = not pathfind_hm
end
end
end
end

function update_inpassible_tiles()
for i=0x00, 0xff do
inpassible_tiles[i] = true
end
	local ptr = memory.readword(RAM_PASSIBLE_TILES)
while memory.gbromreadbyte(ptr) ~= 0xff do
inpassible_tiles[memory.gbromreadbyte(ptr)] = false
ptr = ptr + 1
end
update_inpassible_hm()
end

function get_map_collisions()
local blocks = get_map_blocks()
local width = #blocks[0]
local collisions = {}
function add_collision(x, y, type)
collisions[y] = collisions[y] or {}
collisions[y][x] = type
end
local collision_bank = memory.readbyteunsigned(RAM_TILESET_HEADER)
local collision_addr = memory.readword(RAM_TILESET_BLOCKS)
collision_addr = ((collision_bank - 1)* 16384) + collision_addr

for y = -3, #blocks do
for x = -3, width do
-- Each block is a 2x2 walkable tile. The collision data is
-- (top left, top right, bottom left, bottom right).
-- We have block data for the first half of the xy pair here.
local block_index = blocks[y][x]
local ptr = collision_addr + (block_index * 0x10)
add_collision(x*2, y*2, memory.gbromreadbyte(ptr+4))
add_collision(x*2+1, y*2, memory.gbromreadbyte(ptr+6))
add_collision(x*2, y*2+1, memory.gbromreadbyte(ptr+(4*3)))
add_collision(x*2+1, y*2+1, memory.gbromreadbyte(ptr+(4*3)+2))
end -- x
end -- y

update_inpassible_tiles()
return collisions
end

function get_additional_collision_data()
local x = 0
local y = 0
x, y = get_camera_xy()
local tile_x = x % 2
local tile_y = y % 2
local collision_bank = memory.readbyteunsigned(RAM_TILESET_HEADER)
local collision_addr = memory.readword(RAM_TILESET_BLOCKS)
collision_addr = ((collision_bank - 1) * 16384) + collision_addr

local block_index = get_block(x, y)
local ptr = collision_addr + (block_index * 0x10)
return {
memory.gbromreadbyte(ptr+(tile_y*8)+(tile_x*2)),
memory.gbromreadbyte(ptr+(tile_y*8)+(tile_x*2)+1),
memory.gbromreadbyte(ptr+(tile_y*8)+(tile_x*2)+4),
memory.gbromreadbyte(ptr+(tile_y*8)+(tile_x*2)+5)
}
end

function get_connection_limits(address, size, dir)
local height = memory.readbyte(RAM_MAP_HEIGHT)
local width = memory.readbyte(RAM_MAP_WIDTH)
local row_width = width + 6
address = address - RAM_MAP
local start_y = (math.floor(address / row_width) - 3) * 2
local start_x = ((address % row_width) - 3) * 2
local end_y, end_x = nil
if dir == NORTH or dir == SOUTH then
end_y = start_y
end_x = start_x + (size * 2)
elseif dir == EAST or dir == WEST then
end_y = start_y + (size * 2)
end_x = start_x
end
-- fix coords so the connection doesn't go out of walking range
return {
start_y = fix_map_bounds(start_y, height),
start_x = fix_map_bounds(start_x, width),
end_y = fix_map_bounds(end_y, height),
end_x = fix_map_bounds(end_x, width)}
end

function fix_map_bounds(coord, size)
if coord < 0 then
coord = 0
elseif coord >= size * 2 then
coord = (size * 2) -1
end
return coord
end

function is_posible_connection(collisions, x, y, dir)
local dir_x, dir_y = decode_direction(dir)
if not inpassible_tiles[collisions[y + dir_y][x + dir_x]] then
return true
end
return false
end

function find_path_to(obj)
local path
local width = memory.readbyteunsigned(RAM_MAP_WIDTH)
local height = memory.readbyteunsigned(RAM_MAP_HEIGHT)

if obj.type == "connection" then
local collisions = get_map_collisions()
local results = {}
if obj.direction == "north" then
results = get_connection_limits(memory.readword(RAM_MAP_NORTH_CONNECTION + 3), memory.readword(RAM_MAP_NORTH_CONNECTION + 5), NORTH)
dir = UP
elseif obj.direction == "south" then
results = get_connection_limits(memory.readword(RAM_MAP_SOUTH_CONNECTION + 3), memory.readword(RAM_MAP_SOUTH_CONNECTION + 5), SOUTH)
dir = DOWN
elseif obj.direction == "east" then
results = get_connection_limits(memory.readword(RAM_MAP_EAST_CONNECTION + 3), memory.readword(RAM_MAP_EAST_CONNECTION + 5), EAST)
dir = RIGHT
elseif obj.direction == "west" then
results = get_connection_limits(memory.readword(RAM_MAP_WEST_CONNECTION + 3), memory.readword(RAM_MAP_WEST_CONNECTION + 5), WEST)
dir = LEFT
end
local found = false
for dest_y = results.start_y, results.end_y do
for dest_x = results.start_x, results.end_x do
if not inpassible_tiles[collisions[dest_y][dest_x]] and is_posible_connection(collisions, dest_x, dest_y, dir) then
if not found then
local dir_x, dir_y = decode_direction(dir)
path = find_path_to_xy(dest_x + dir_x, dest_y + dir_y)
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
path = find_path_to_xy(obj.x, obj.y, true)
end
if path == nil then
tolk.output(message.translate("no_path"))
return
end
speak_path(clean_path(path))
end

function find_path_to_xy(dest_x, dest_y, search)
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local allnodes = {}
local height = #collisions - 4
local width = #collisions[0] - 4
local start = nil
local dest = nil
-- set all objects to inpassible tiles
-- 0xff is the tile list delimiter, so it won't ever be a passible tile
for i, object in ipairs(get_objects()) do
if not object.ignorable then
collisions[object.y][object.x] = 0xff
end
end
for i, warp in ipairs(get_warps()) do
if warp.x ~= dest_x and warp.y ~= dest_y then
collisions[warp.y][warp.x] = 0xff
end
end
-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = -2, height do
for x = -2, width do
local n = {x=x, y=y, type=collisions[y][x], special_tiles=get_special_tiles_around(collisions, y, x), is_dest = false}
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
local valid = function (node, neighbor)
for dir = DOWN, RIGHT, 4 do
local dir_x, dir_y = decode_direction(dir)
dir_x = dir_x + dir_x
dir_y = dir_y + dir_y
if (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y)
and ((has_preledge_around(node.special_tiles, dir) and memory.readbyte(RAM_MAP_HEADER) == 0x00)
or (has_talking_over_around(node.special_tiles, dir) and neighbor.is_dest)) then
return true
end
end
if astar.dist_between(node, neighbor) == 1 and check_collision_pair(memory.readbyte(RAM_MAP_HEADER), node.type, neighbor.type) then
return false
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif astar.dist_between(node, neighbor) == 1 and neighbor.is_dest then
return true
elseif inpassible_tiles[neighbor.type] then
return false
end
return true
end -- valid
path = astar.path(start, dest, allnodes, true, valid)
return path
end

function clean_path(path)
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
local command = ""
local count = true
if is_cut_tile(node.type) then
command = message.translate("tree")
elseif is_water_tile(node.type) and not is_water_tile(last.type) and last.type ~= 0xff then
command = message.translate("enter_water")
count = false
elseif not is_water_tile(node.type) and is_water_tile(last.type) and node.type ~= 0xff then
command = message.translate("exit_water")
count = false
end
if command ~= "" then
command = command .. " " .. message.translate("on_way") .. " "
end
command = command .. only_direction(last.x, last.y, node.x, node.y)
table.insert(new_path, {command=command, count=count})
end -- i > 1
end -- for
return group_unique_items(new_path)
end

function speak_path(path)
for _, v in ipairs(path) do
local command = ""
if v[2] > 0 then
command = v[2] .. " "
end
command = command .. v[1]
tolk.output(command)
end
end -- function

function rename_current()
local info = get_map_info()
reset_current_item_if_needed(info)
local id = get_map_id()
local obj_id = info.objects[current_item].id
name = inputbox.inputbox(message.translate("new_name"), message.translate("enter_newname") .. " " .. info.objects[current_item].name, info.objects[current_item].name)
if name == nil then
return
end
names[id] = names[id] or {}
if trim(name) ~= "" then
names[id][obj_id] = trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function write_names()
local file = io.open("names.lua", "wb")
file:write(serpent.block(names, {comment=false}))
io.close(file)
tolk.output(message.translate("names_saved"))
end

function rename_map()
local id = get_map_id()
local mapname = get_map_name(id)
local obj_id = "map"
name = inputbox.inputbox(message.translate("new_name"), message.translate("enter_newname") .. " " .. mapname, mapname)
if name == nil then
return
end
names[id] = names[id] or {}
if trim(name) ~= "" then
names[id][obj_id] = trim(name)
else
names[id][obj_id] = nil
end
write_names()
end

function read_mapname()
local name = get_map_name(get_map_id())
tolk.output(name)
end

function get_menu_item(line, startpos, endpos)
return line:sub(startpos, endpos)
end

function translate_tileline(tileline)
local printable = is_printable_screen()
local l = ""
for i = 1, #tileline do
if printable then
l = l .. translate(tileline:sub(i, i):byte())
else
l = l .. " "
end
end
return l
end

function read_menu_item(lines, tile_lines, pos)
local results = generate_menu_header()
-- we use tile_lines and not lines because of character encoding variable length
-- however starting and ending  bytes should be removed if menu has lateral borders
local startpos = results.start_x
local endpos = results.end_x
if results.has_left_border then
startpos = startpos + 1
end
if results.has_right_border then
endpos = endpos - 1
end
-- Battle menu fix
if tile_lines[3]:match("\x71\x62") then
local correctpos = nil
if tile_lines[15]:match("\xe1\xe2\x7f") then
correctpos = 16
elseif tile_lines[15]:match("\xf1") then
correctpos = 14
end
if correctpos ~= nil then
if pos[COLUMN] < correctpos then
endpos = correctpos
else
startpos = correctpos
end
end
end
audio.play(scriptpath .. "sounds\\menusel.wav", 0, (200 * (pos[LINE] - 1) / #lines) - 100, 30)
local tile_line = get_menu_item(tile_lines[pos[LINE]], startpos, endpos)
-- Choose Pokémon menu fix
if pos[LINE] > results.start_y then
local add_tileline = get_menu_item(tile_lines[pos[LINE]-1], startpos, endpos)
if add_tileline:match("\x6e") and tile_line:match("\x71\x62") then
tolk.output(translate_tileline(add_tileline))
end
end
tolk.output(translate_tileline(tile_line))
-- Items and PC menu fix
if pos[LINE] < results.end_y then
local add_tileline = get_menu_item(tile_lines[pos[LINE]+1], startpos, endpos)
if (add_tileline:match("\xf1"))
or (add_tileline:match("\xf0"))
or (add_tileline:match("\x6e") and not tile_line:match("\x71\x62")) then
tolk.output(translate_tileline(add_tileline))
end
end
end

BAR_LENGTH = 6
function get_enemy_health()
local function read_bar(addr)
local count
-- no bar here
if memory.readbyte(addr+BAR_LENGTH) ~= 0x6c then
return nil
end
local total = 0
for i = 0, BAR_LENGTH - 1 do
if memory.readbyte(addr+i) == 0x6a then
total = total +1
end
end
return total
end
local enemy = read_bar(RAM_TEXT+(2*20)+4)
if enemy == nil then
return nil
else
local current = memory.readword(RAM_CURRENT_ENEMY_HEALTH)
local total = memory.readword(RAM_CURRENT_ENEMY_HEALTH+14)
return string.format("%0.2f%%", current/total*100)
end
end

function read_enemy_health()
local health = get_enemy_health()
if health == nil then
tolk.output(message.translate("no_bar"))
else
tolk.output(health)
end
end

function get_custom_name(name_offset)
local name = ""
local i = 0
local char = memory.readbyte(name_offset+i)
while char ~= 0x50 do
name = name .. translate(char)
i = i + 1
char = memory.readbyte(name_offset+i)
end
return name
end

function group_unique_items(t)
if #t == 0 then
return t
end
if #t == 1 then
if t[1].count then
return {{t[1].command, 1}}
else
return {{t[1].command, 0}}
end
end
local nt = {}
local last = t[1]
local last_count = nil
if last.count then
last_count = 1
else
last_count = 0
end
for i = 2, #t do
if t[i].command == last.command and last.count then
last_count = last_count + 1
else
table.insert(nt, {last.command, last_count})
last = t[i]
if last.count then
last_count = 1
else
last_count = 0
end
end
end
table.insert(nt, {last.command, last_count})
return nt
end

function read_keyboard()
local position = memory.readword(RAM_KEYBOARD_POSITION)+1
local word = chars[memory.readbyte(position)] or message.translate("unknown")
if position == RAM_KEYBOARD_END then
word = message.translate("end")
elseif position == RAM_KEYBOARD_CASE then
if screen.lines[16]:match(KEYBOARD_UPPER_STRING) ~= nil then
word = KEYBOARD_UPPER_STRING
else
word = KEYBOARD_LOWER_STRING
end
end
tolk.output(word)
end

function get_block(mapx, mapy)
local width = memory.readbyte(RAM_MAP_WIDTH)
local row_width = width+6
local ptr = RAM_MAP+row_width*3
local skip_rows = bit.rshift(mapy, 1)
local skip_cols = bit.rshift(mapx, 1) + 3
local block = memory.readbyte(ptr+(skip_rows*row_width)+skip_cols)
return block
end
function get_collision_data(block)
local collision_bank = memory.readbyteunsigned(RAM_TILESET_HEADER)
local collision_addr = memory.readword(RAM_TILESET_BLOCKS)
collision_addr = ((collision_bank - 1) * 16384) + collision_addr
return {
memory.gbromreadbyte(collision_addr+(block*0x10)+4),
memory.gbromreadbyte(collision_addr+(block*0x10)+(4+2)),
memory.gbromreadbyte(collision_addr+(block*0x10)+12),
memory.gbromreadbyte(collision_addr+(block*0x10)+(12+2))}
end

function keyboard_showing(screen)
if screen.lines[16]:match(KEYBOARD_LOWER_STRING) ~= nil
or screen.lines[16]:match(KEYBOARD_UPPER_STRING) ~= nil then
return true
end
return false
end

function get_textbox()
local lines = {}
if screen.menu_position ~= nil and screen.menu_position[LINE] > 13 then
return nil
end
if screen.tile_lines[13] == TEXTBOX_PATTERN then
for i = 14, 17 do
table.insert(lines, screen.lines[i])
end
return lines
end
return nil
end

function handle_keyboard()
local pos = memory.readbyte(RAM_KEYBOARD_POSITION)
if pos ~= kbd_pos then
read_keyboard()
kbd_pos = pos
end
end -- handle_keyboard

function read_health_if_needed()
if not (last_menu_pos == nil and screen.menu_position ~= nil) then
return
end
enemy_health = get_enemy_health()
if enemy_health == nil then
return
end
if trim(screen.lines[11]) ~= "" then
tolk.output(screen.lines[11])
end
tolk.output(message.translate("enemy_health") .. ": " .. enemy_health)
end

function facing_to_string(d)
-- d = bit.rshift(d, 2)
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

function get_player_xy()
return memory.readbyte(RAM_PLAYER_X), memory.readbyte(RAM_PLAYER_Y)
end

function get_camera_xy()
if camera_x == -7 and camera_y == -7 then
return get_player_xy()
else
return camera_x, camera_y
end
end

function get_language_code()
local code = ""
for i = 0, 3 do
code = code .. string.char(memory.gbromreadbyte(0x13f+i))
end
return code
end

commands = {
[{"Y"}] = {read_coords, true};
[{"Y", "shift"}] = {read_camera, true};
[{"J"}] = {read_previous_item, true};
[{"K"}] = {read_current_item, true};
[{"L"}] = {read_next_item, true};
[{"P"}] = {pathfind, true};
[{"P", "shift"}] = {set_pathfind_hm, true};
[{"T"}] = {read_text, false};
[{"R"}] = {read_tiles, true};
[{"M"}] = {read_mapname, true};
[{"K", "shift"}] = {rename_current, true};
[{"M", "shift"}] = {rename_map, true};
[{"S"}] = {camera_move_left, true},
[{"F"}] = {camera_move_right, true},
[{"E"}] = {camera_move_up, true},
[{"C"}] = {camera_move_down, true},
[{"D"}] = {set_camera_default, true},
[{"S", "shift"}] = {camera_move_left_ignore_wall, true},
[{"F", "shift"}] = {camera_move_right_ignore_wall, true},
[{"E", "shift"}] = {camera_move_up_ignore_wall, true},
[{"C", "shift"}] = {camera_move_down_ignore_wall, true},
[{"H"}] = {read_enemy_health, false},
}

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()
res, names = load_table("names.lua")
if res == nil then
names = {}
end
-- res, maps = load_table(scriptpath .. "\\lang\\en\\" .. "maps.lua")
-- if res == nil then
-- tolk.output("Unable to load map names file.")
-- default_names = {}
-- end
-- get current language
local code = get_language_code()
-- including everything but english in here, since english is the default
local codemap = {
["APSD"] = "de",
["APSS"] = "es",
["APSI"] = "it",
["APSF"] = "fr",
}
if codemap[code] then
load_language(codemap[code])
language = codemap[code]
-- res, language_names = load_table(scriptpath .. "\\lang\\" .. codemap[code] .. "\\default_names.lua")
-- if res == nil then
-- language_names = {}
-- end
end

memory.registerexec(RAM_FOOTSTEP_FUNCTION, function()
local player_x, player_y = get_player_xy()
if player_x == 0xff then
player_x = -1
end
if player_y == 0xff then
player_y = -1
end
local collisions = get_map_collisions()
local type = collisions[player_y][player_x]
camera_x = -7
camera_y = -7
preledge_tile = check_preledge(collisions, player_y, player_x)
play_tile_sound(type, 0, 30, false)
end)

--[[ in_options = false
memory.registerexec(RAM_BANK_SWITCH, function()
if memory.getregister("a") == 57 and memory.getregister("h") == 0x41 and memory.getregister("l") == 0xd0 then
in_options = true
end
end) --]]

-- initialize tables based in rom values
ledge_tiles = get_rom_table(ROM_LEDGE_TILES, 4)
land_collision_pairs = get_rom_table(ROM_LAND_COLLISION_PAIRS, 3)
water_collision_pairs = get_rom_table(ROM_LAND_COLLISION_PAIRS+34, 3)
water_tilesets = get_rom_table(ROM_WATER_TILESETS, 1)
water_tiles = get_rom_table(ROM_WATER_TILESETS + 10, 1)
mansion_cliffs = get_rom_table(ROM_MANSION_CLIFFS, 2)

counter = 0
oldtext = "" -- last text seen
current_item = nil
in_keyboard = false
kbd_pos = nil
tolk.output(message.translate("ready"))

while true do
emu.frameadvance()
counter = counter + 1
handle_user_actions()
screen = get_screen()
local text = table.concat(screen.lines, "")
if screen:keyboard_showing() then
handle_keyboard()
end -- handling keyboard
if text ~= oldtext then
want_read = true
text_updated_counter = counter
oldtext = text
end
if want_read and (counter - text_updated_counter) >= 20 then
-- if we're in a menu
if screen.menu_position ~= nil then
-- if the menu outer text changed
outer_text = screen:get_outer_menu_text()
if last_outer_text ~= outer_text then
if outer_text ~= "" then
tolk.output(outer_text)
end
last_outer_text = outer_text
end
if not screen:keyboard_showing() then
read_health_if_needed()
read_menu_item(screen.lines, screen.tile_lines, screen.menu_position)
end
last_menu_pos = screen.menu_position
else
last_menu_pos = nil
last_outer_text = ""
if in_options then
in_options = false
end
read_text(true)
end
want_read = false
end

end
