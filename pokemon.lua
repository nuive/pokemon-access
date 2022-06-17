require "a-star"
serpent = require "serpent"
message = require "message"
local inputbox = require "Inputbox"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
callback_functions = {}
codemap = {
["APS"] = "yellow",
["AAU"] = "gold",
["AAX"] = "silver",
["BYT"] = "crystal",
}
langmap = {
["D"] = "de",
["E"] = "en",
["F"] = "fr",
["I"] = "it",
["S"] = "es",
}
game_checksum = {
["red_blue"] = {
-- red
[0x91e6] = "en",
[0x384a] = "es",
[0x7afc] = "fr",
[0x89d2] = "it",
-- blue
[0x9d0a] = "en",
[0x14d7] = "es",
[0x56a4] = "fr",
[0x5e9c] = "it",
},
["yellow"] = {
[0x047c] = "en",
},
}
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
MAPNAME_PATTERN = "\x65\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6b"
camera_x = -7
camera_y = -7
last_camera_tile = 0xff
pathfind_hm = false
inpassible_tiles = {}

function path_exists(path)
   local ok, err, code = os.rename(path, path)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

function load_game()
if data == nil then
tolk.output("Game data not found.")
return false
end
local f = nil
-- load memory and text values
local path = scriptpath .. "game\\" .. game .. "\\" .. data .. "\\"
local t = {"chars.lua", "fonts.lua", "memory.lua"}
for i, v in ipairs(t) do
f = loadfile(path .. v)
if f ~= nil then
f()
else
tolk.output("Game data not found.")
return false
end
end
-- load the core scripts
if CORE_FILES ~= nil then
for _, v in ipairs(CORE_FILES) do
f = loadfile(scriptpath .. "game\\common\\" .. v .. ".lua")
if f ~= nil then
f()
else
tolk.output("Problem loading core script.")
return false
end
end
else
tolk.output("Core script is missing.")
return false
end
-- load specific game script
f = loadfile(scriptpath .. "game\\" .. game .. "\\main.lua")
if f ~= nil then
f()
else
tolk.output("Warning: No specific game script is provided. Accessibility could be limited.")
end
return load_data()
end

function load_data()
if data == nil then
tolk.output("Game data not found.")
return false
end
local path = scriptpath .. "game\\" .. game .. "\\" .. data .. "\\"
local t = {"maps.lua", "sprites.lua"}
local partial = false
for i, v in ipairs(t) do
local f = loadfile(path .. v)
if f ~= nil then
f()
else
partial = true
tolk.output(v)
end
end
message.set_strings(data)
if partial then
tolk.output("Warning: Game not fully supported.")
end
return true
end

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
if char == 0xed or char == 0xeb then
menu_position = {((i-1)/20)+1, j+1}
elseif char == 0xec then
text_over_menu = true
end
if i+j == SCROLL_INDICATOR_POSITION and char == 0xee then
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
get_textbox=get_textbox}
end

function read_mapname_if_needed()
if screen.tile_lines[2] == MAPNAME_PATTERN then
tolk.output(translate_tileline(screen.tile_lines[3]))
end
end

function get_textbox_border(chars)
if chars == nil then
chars = 18
end
local top = "\x79"
local bottom = "\x7d"
for i = 1, chars do
top = top .. "\x7a"
bottom = bottom .. "\x7a"
end
top = top .. "\x7b"
bottom = bottom .. "\x7e"
return top, bottom
end

function read_text(auto)
if auto then
local textbox = get_textbox()
if textbox ~= nil then
if #textbox == 4 then
if trim(textbox[2]) == trim(last_line) then
textbox[2] = ""
end
last_line = textbox[4]
end
textbox_text = table.concat(get_textbox(), "")
if textbox_text ~= last_textbox_text then
output_textbox(textbox)
end
last_textbox_text = textbox_text
else
last_textbox_text = nil
end -- textbox
else
output_lines()
end
end

function output_textbox(textbox)
local result = ""
for i, line in pairs(textbox) do
line = trim(line)
if line ~= "" then
result = result .. line .. " "
end
end
if result ~= "" then
tolk.output(result)
end
end

function output_lines()
local lines = get_screen().lines
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

function read_coords()
local x, y = get_player_xy()
tolk.output("x " .. x .. ", y " .. y)
end

function read_camera()
local x, y = get_camera_xy()
tolk.output("x " .. x .. ", y " .. y)
end

function get_name(mapid, obj)
return (names[mapid] or {})[obj.id] or obj.name
end

function hasbit(x, p)
return bit.rshift(x, p) % 2 ~= 0
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
local mapid = get_map_id()
local results = {mapid=mapid, objects={}}
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

function check_coordinates_on_screen(x, y)
if x >= -6 and y >= -6
and x <= memory.readbyte(RAM_MAP_WIDTH)*2 + 5 and y <= memory.readbyte(RAM_MAP_HEIGHT)*2 + 5 then
return true
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

-- reset camera focus when camera_xy outside map
function reset_camera_focus(player_x, player_y)
	if camera_x == -7 and camera_y == -7 then
		camera_x = player_x
		camera_y = player_y
last_camera_tile = 0xff
	end
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
				if obj.sprite_id == BOULDER_SPRITE then
					audio.play(scriptpath .. "sounds\\s_boulder.wav", 0, pan, vol)
				end -- sprite_id
			end -- obj.xy
		end -- for --]]

		if is_collision(collisions, camera_y, camera_x) then
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
local fn, needs_script, needs_map = unpack(command)
if data ~= nil then
if needs_map and not on_map() then
tolk.output(message.translate("not_map"))
else
fn(args)
end -- not on map
elseif not needs_script then
fn(args)
else
tolk.output("Script not loaded.")
end -- data check
end

function read_current_item()
local info = get_map_info()
reset_current_item_if_needed(info)
read_item(info.objects[current_item])
end

function reset_current_item_if_needed(info)
if info.mapid ~= current_map then
current_item = 1
current_map = info.mapid
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
update_inpassible_tiles()
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
ptr = RAM_OVERWORLD_MAP -- start of overworld
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

function get_connection_limits(address, size, dir)
local height = memory.readbyte(RAM_MAP_HEIGHT)
local width = memory.readbyte(RAM_MAP_WIDTH)
local row_width = width + 6
address = address - RAM_OVERWORLD_MAP
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

if obj.type == "connection" then
local collisions = get_map_collisions()
local results = {}
if obj.direction == "north" then
results = get_connection_limits(memory.readword(RAM_MAP_NORTH_CONNECTION_START_POINTER), memory.readword(RAM_MAP_NORTH_CONNECTION_SIZE), NORTH)
dir = UP
elseif obj.direction == "south" then
results = get_connection_limits(memory.readword(RAM_MAP_SOUTH_CONNECTION_START_POINTER), memory.readword(RAM_MAP_SOUTH_CONNECTION_SIZE), SOUTH)
dir = DOWN
elseif obj.direction == "east" then
results = get_connection_limits(memory.readword(RAM_MAP_EAST_CONNECTION_START_POINTER), memory.readword(RAM_MAP_EAST_CONNECTION_SIZE), EAST)
dir = RIGHT
elseif obj.direction == "west" then
results = get_connection_limits(memory.readword(RAM_MAP_WEST_CONNECTION_START_POINTER), memory.readword(RAM_MAP_WEST_CONNECTION_SIZE), WEST)
dir = LEFT
end
local found = false
for dest_y = results.start_y, results.end_y do
for dest_x = results.start_x, results.end_x do
if not inpassible_tiles[collisions[dest_y][dest_x]] and is_posible_connection(collisions, dest_x, dest_y, dir) then
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
path = find_path_to_xy(obj.x, obj.y, true)
end
if path == nil then
tolk.output(message.translate("no_path"))
return
end
speak_path(clean_path(path))
end

function has_talking_over_around(value, dir)
if hasbit(value, bit.rshift(dir, 2)) then
return true
end
return false
end

function find_path_to_xy(dest_x, dest_y, search)
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local allnodes = {}
local height = #collisions - 6
local width = #collisions[0] - 6
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
if warp.x ~= dest_x or warp.y ~= dest_y then
collisions[warp.y][warp.x] = 0xff
end
end
-- generate the all nodes list for pathfinding, and track the start and end nodes
for y = 0, height do
for x = 0, width do
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
path = astar.path(start, dest, allnodes, true, valid_path)
return path
end

function clean_path(path)
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
local command = ""
local count = 1
if pathfind_hm then
command, count = get_hm_command(node.type, last.type)
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
local file = io.open(names_file, "wb")
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
if startpos == nil then
startpos = 1
end
if endpos == nil then
endpos = 20
end
return line:sub(startpos, endpos)
end

function translate_tileline(tileline)
local l = ""
if is_printable_screen() then
for i = 1, #tileline do
l = l .. translate(tileline:sub(i, i):byte())
end
end
return l
end

function is_full_screen_menu()
if screen.menu_position ~= nil then
local results = generate_menu_header()
if results.start_y == 1 and results.start_x == 1
and results.end_y == 18 and results.end_x == 20 then
return true
end
end
return false
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
results.has_left_border = true
while y > 0 and byte ~= 0x79 and byte ~= 0x7a do
y = y - 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x79 or byte == 0x7a then
results.start_y = y
results.start_x = x
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
results.has_right_border = true
while y <= 18 and byte ~= 0x7e and byte ~= 0x7a do
y = y + 1
byte = tile_lines[y]:sub(x,x):byte()
end
if byte == 0x7e or byte == 0x7a then
results.end_y = y
results.end_x = x
end
end
return results
end

function read_menu_item()
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
if screen.tile_lines[3]:match(HEALTH_BAR) then
local correctpos = nil
if screen.tile_lines[15]:match("\xe1\xe2\x7f") then
correctpos = screen.tile_lines[15]:find("\xe1\xe2\x7f") - 1
elseif screen.tile_lines[15]:match("\xf1") then
correctpos = 14
end
if correctpos ~= nil then
if screen.menu_position[COLUMN] < correctpos then
endpos = correctpos
else
startpos = correctpos
end
end
end
audio.play(scriptpath .. "sounds\\menusel.wav", 0, (200 * (screen.menu_position[LINE] - 1) / #screen.tile_lines) - 100, 30)
local tile_line = get_menu_item(screen.tile_lines[screen.menu_position[LINE]], startpos, endpos)
-- Choose Pokémon menu fix
if screen.menu_position[LINE] > results.start_y then
local add_tileline = get_menu_item(screen.tile_lines[screen.menu_position[LINE]-1], startpos, endpos)
if add_tileline:match("\x6e") and get_menu_item(screen.tile_lines[results.start_y], startpos, endpos):match("\x6e") then
tolk.output(translate_tileline(add_tileline))
end
end
tolk.output(translate_tileline(tile_line))
-- Items and PC menu fix
if screen.menu_position[LINE] < results.end_y then
local add_tileline = get_menu_item(screen.tile_lines[screen.menu_position[LINE]+1], startpos, endpos)
if (add_tileline:match("\xf1"))
or (add_tileline:match("\xf0"))
or (add_tileline:match("\x6e") and not get_menu_item(screen.tile_lines[results.start_y], startpos, endpos):match("\x6e"))
or (add_tileline:match("\x9c"))
or (add_tileline:match("\x9e") and add_tileline:match("\x9f")) then
tolk.output(translate_tileline(add_tileline))
end
end
end

function get_enemy_health()
if memory.readbyte(RAM_TEXT+(2*20)+10) == HEALTH_BAR_LIMIT then
local current = memory.readbyte(RAM_CURRENT_ENEMY_HEALTH) * 0x100 + memory.readbyte(RAM_CURRENT_ENEMY_HEALTH+1)
local total = memory.readbyte(RAM_CURRENT_ENEMY_HEALTH+ENEMY_MAX_HEALTH) * 256 + memory.readbyte(RAM_CURRENT_ENEMY_HEALTH+ENEMY_MAX_HEALTH+1)
return string.format("%0.2f%%", current/total*100)
else
return nil
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
if not last.command:match("$ignore") then
table.insert(nt, {last.command, last_count})
end
last = t[i]
if last.count then
last_count = 1
else
last_count = 0
end
end
end
if not last.command:match("$ignore") then
table.insert(nt, {last.command, last_count})
end
return nt
end

function get_textbox_line()
local textbox_border = get_textbox_border()
local results = nil
if screen.menu_position ~= nil then
results = generate_menu_header()
end
for index = 13, 16 do
local heading = screen.tile_lines[index]
if heading == textbox_border
or heading:find(textbox_border:sub(1, textbox_border:len()-10))
or heading:find(textbox_border:sub(11, textbox_border:len())) then
if screen.menu_position ~= nil
and (screen.menu_position[LINE] > index or results.end_y > index+1)
and not is_full_screen_menu() then
return nil
end
return index
end
end
return nil
end

function get_textbox()
local lines = {}
local index = get_textbox_line()
if index ~= nil then
for i = index+1, 17 do
table.insert(lines, screen.lines[i])
end
return lines
end
return nil
end

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
d = bit.lshift(bit.rshift(d, 2), 2)
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
local x = memory.readbyte(RAM_PLAYER_X)
local y = memory.readbyte(RAM_PLAYER_Y)
if x > memory.readbyte(RAM_MAP_WIDTH) * 2 then
x = -1
end
if y > memory.readbyte(RAM_MAP_HEIGHT) * 2 then
y = -1
end
return x, y
end

function get_camera_xy()
if camera_x == -7 and camera_y == -7 then
return get_player_xy()
else
return camera_x, camera_y
end
end

function init_script()
for _,cb_function  in pairs(callback_functions) do
memory.registerexec(cb_function, nil)
end
callback_functions = {}
commands = {
[{"Y"}] = {read_coords, true, true};
[{"Y", "shift"}] = {read_camera, true, true};
[{"J"}] = {read_previous_item, true, true};
[{"K"}] = {read_current_item, true, true};
[{"L"}] = {read_next_item, true, true};
[{"P"}] = {pathfind, true, true};
[{"P", "shift"}] = {set_pathfind_hm, true, true};
[{"T"}] = {read_text, true, false};
[{"R"}] = {read_tiles, true, true};
[{"M"}] = {read_mapname, true, true};
[{"K", "shift"}] = {rename_current, true, true};
[{"M", "shift"}] = {rename_map, true, true};
[{"S"}] = {camera_move_left, true, true},
[{"F"}] = {camera_move_right, true, true},
[{"E"}] = {camera_move_up, true, true},
[{"C"}] = {camera_move_down, true, true},
[{"D"}] = {set_camera_default, true, true},
[{"S", "shift"}] = {camera_move_left_ignore_wall, true, true},
[{"F", "shift"}] = {camera_move_right_ignore_wall, true, true},
[{"E", "shift"}] = {camera_move_up_ignore_wall, true, true},
[{"C", "shift"}] = {camera_move_down_ignore_wall, true, true},
[{"H"}] = {read_enemy_health, true, false},
[{"H", "shift"}] = {add_hackrom_values, false, false},
}

game = nil
data = nil
base_game = nil
chars = {}
fonts = {}
maps = {}
sprites = {}
-- get current game and data
get_game()

if data ~= nil then
names_file = "names_" .. game .. "_" .. data .. ".lua"
res, names = load_table(names_file)
if res == nil then
names = {}
end

old_pressed_keys = {}
last_line = ""
last_textbox_text = nil
counter = 0
oldtext = "" -- last text seen
current_item = nil
in_keyboard = false
tolk.output(message.translate("ready"))
end
end

function get_game()
local valid = false
local game_title = memory.gbromreadbyterange(0x134, 16)
local code = ""
for i = 0, 2 do
code = code .. string.char(game_title[12+i])
end
local lang = string.char(game_title[15])
local checksum = memory.gbromreadbyte(0x14e)*256 + memory.gbromreadbyte(0x14f)
if codemap[code] then
game = codemap[code]
if langmap[lang] then
data = langmap[lang]
valid = true
-- check if it's hack
set_hackrom_values(checksum)
elseif set_hackrom_values(checksum, code .. lang) then
valid = true
else
tolk.output("Game data not found.")
return false
end
elseif set_hackrom_values(checksum, code .. lang) then
valid = true
else
if parse_old_title(game_title) then
valid = true
else
return false
end
end
if valid then
return load_game()
end
tolk.output("Game not supported.")
return false
end

function parse_old_title(title)
oldgame = ""
local i = 9
while title[i] ~= 0 do
oldgame = oldgame .. string.char(title[i])
i = i + 1
end
oldgame = oldgame:lower()
local checksum = memory.gbromreadbyte(0x14e)*256 + memory.gbromreadbyte(0x14f)
for v in pairs(game_checksum) do
if oldgame ~= "" and v:find(oldgame) ~= nil then
game = v
if game_checksum[game][checksum] ~= nil then
data = game_checksum[game][checksum]
return true
-- check if it's hack
elseif set_hackrom_values(checksum) then
return true
else
tolk.output("Game data not found.")
return false
end
end
end
tolk.output("Game not supported.")
return false
end

function set_hackrom_values(checksum, game_code)
loaded, hacks = load_table("hacks.lua")
if loaded ~= nil and checksum ~= nil then
local curgame = ""
if game_code ~= nil then
curgame = game_code
else
curgame = game
end
if hacks[curgame] ~= nil and hacks[curgame][checksum] ~= nil then
base_game = game
game = hacks[curgame][checksum].game
data = hacks[curgame][checksum].data
return true
end
end
return false
end

function add_hackrom_values()
loaded, hacks = load_table("hacks.lua")
if loaded == nil then
hacks = {}
end
local id = nil
if game == nil then
id = ""
for i = 0, 3 do
id = id .. string.char(memory.gbromreadbyte(0x13f+i))
end
elseif base_game ~= nil then
id = base_game
else
id = game
end
if hacks[id] == nil then
hacks[id] = {}
end
local checksum = memory.gbromreadbyte(0x14e)*256 + memory.gbromreadbyte(0x14f)
if hacks[id][checksum] == nil then
hacks[id][checksum] = {}
end
local path = scriptpath .. "game\\"
local hack_game = nil
repeat
hack_game = inputbox.inputbox("Base game folder", "Input the script base folder for this game", hack_game or hacks[id][checksum].game or "")
if hack_game == nil then
return
end
until hack_game ~= "" and path_exists(path .. hack_game .. "\\")
local hack_data = nil
repeat
hack_data = inputbox.inputbox("Data folder", "Input the game's Data folder", hack_data or hacks[id][checksum].data or "")
if hack_data == nil then
return
end
until hack_data ~= "" and path_exists(path .. hack_game .. "\\" .. hack_data .. "\\")
hacks[id][checksum].game = hack_game
hacks[id][checksum].data = hack_data
local file = io.open("hacks.lua", "wb")
file:write(serpent.block(hacks, {comment=false}))
io.close(file)
init_script()
end

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()

memory.registerexec(0x100, init_script)

init_script()

while true do
emu.frameadvance()
handle_user_actions()
if data ~= nil then
counter = counter + 1
screen = get_screen()
handle_special_cases()
local text = table.concat(screen.lines, "")
if text ~= oldtext then
want_read = true
text_updated_counter = counter
oldtext = text
end
if want_read and (counter - text_updated_counter) >= 20 then
-- if current mapname is showing
read_mapname_if_needed()
read_text(true)
-- if we're in a menu
if screen.menu_position ~= nil then
if not screen:keyboard_showing() then
read_health_if_needed()
read_menu_item()
end
last_menu_pos = screen.menu_position
else
last_menu_pos = nil
-- check if there are other changeable texts without menu position
read_special_variable_text()
end
want_read = false
end
end
end
