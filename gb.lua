ROM_TITLE_ADDRESS = 0x134
ROM_GAMECODE_START = 11
REQUIRED_FILES = {"chars.lua", "fonts.lua", "memory.lua"}
codemap = {
["APS"] = "yellow",
["AAU"] = "gold",
["AAX"] = "silver",
["BYT"] = "crystal",
}
game_checksum = {
["red_blue"] = {
-- red
[0x91e6] = "en",
[0x384a] = "es",
[0x7afc] = "fr",
[0x89d2] = "it",
[0x5cdc] = "de",
-- blue
[0x9d0a] = "en",
[0x14d7] = "es",
[0x56a4] = "fr",
[0x5e9c] = "it",
[0x2ebc] = "de",
},
["yellow"] = {
[0x047c] = "en",
},
}
CHAR_NAME_END = 0x50
LINE = 1
COLUMN = 2
DOWN = 0
UP = 4
LEFT = 8
RIGHT = 12
EAST = 0
WEST = 1
SOUTH = 2
NORTH = 3
MAPNAME_PATTERN = "\x65\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6d\x6b"
DEFAULT_CAMERA_X = -7
DEFAULT_CAMERA_Y = -7
last_camera_tile = 0xff
impassable_tiles = {}

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

function output_lines()
local lines = get_screen().lines
for _, line in pairs(lines) do
line = trim(line)
if line ~= "" then
tolk.output(line)
end
end
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
local width, height = get_map_dimensions()
if x >= -6 and y >= -6
and x <= width *2 + 5 and y <= height *2 + 5 then
return true
end
return false
end

function get_rom_table(ptr, dimension)
local results = {}
while memory.gbromreadbyte(ptr) ~= 0xff do
if dimension > 1 then
local row = {}
for i = 0, dimension - 1 do
table.insert(row, memory.gbromreadbyte(ptr +i))
end
table.insert(results, row)
else
table.insert(results, memory.gbromreadbyte(ptr))
end
ptr = ptr +dimension
end
return results
end

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
					audio.play(scriptpath .. "sounds\\gb\\s_boulder.wav", 0, pan, vol)
				end -- sprite_id
			end -- obj.xy
		end -- for --]]

		if is_collision(collisions, camera_y, camera_x) then
			if ignore_wall then
				camera_x = camera_x - x
				camera_y = camera_y - y
			end
			audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
		else
			audio.play(scriptpath .. "sounds\\common\\pass.wav", 0, pan, vol)
			play_tile_sound(collisions[camera_y][camera_x], pan, vol, true)
		end
		last_camera_tile = collisions[camera_y][camera_x]
	else
		camera_x = camera_x - x
		camera_y = camera_y - y
		audio.play(scriptpath .. "sounds\\common\\s_wall.wav", 0, pan, vol)
	end
end

function has_badge(badge)
local badges = memory.readbyte(RAM_BADGES)
return bit.band(badges, bit.lshift(1, (badge-1))) ~= 0
end

function get_map_blocks()
-- map width, height in blocks
local width, height = get_map_dimensions()
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
local width, height = get_map_dimensions()
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
if not impassable_tiles[collisions[y + dir_y][x + dir_x]] then
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
if not impassable_tiles[collisions[dest_y][dest_x]] and is_posible_connection(collisions, dest_x, dest_y, dir) then
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
if hasbit(value, bit.rshift(dir, 2)) then
return true
end
return false
end

function find_path_to_xy(dest_x, dest_y)
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local allnodes = {}
local height = #collisions - 6
local width = #collisions[0] - 6
local start = nil
local dest = nil
-- set all objects to impassable tiles
-- 0xff is the tile list delimiter, so it won't ever be a passable tile
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
audio.play(scriptpath .. "sounds\\gb\\menusel.wav", 0, (200 * (screen.menu_position[LINE] - 1) / #screen.tile_lines) - 100, 30)
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

function get_player_health()
if trim(screen.lines[11]) ~= "" then
return trim(screen.lines[11])
else
return nil
end
end

function in_battle()
return memory.readbyte(RAM_IN_BATTLE) ~= 0
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
local width, height = get_map_dimensions()
local x = memory.readbyte(RAM_PLAYER_X)
local y = memory.readbyte(RAM_PLAYER_Y)
if x > width *2 then
x = -1
end
if y > height *2 then
y = -1
end
return x, y
end

function get_map_dimensions()
return memory.readbyteunsigned(RAM_MAP_WIDTH), memory.readbyteunsigned(RAM_MAP_HEIGHT)
end

function on_map_limit(x, y)
local width, height = get_map_dimensions()
if x == 0 or x == width *2 -1
or y == 0 or y == height *2 -1 then
return true
end
return false
end

function get_game_checksum()
return memory.gbromreadbyte(0x14e)*256 + memory.gbromreadbyte(0x14f)
end

function parse_old_title(title)
oldgame = ""
local i = 9
while title[i] ~= 0 do
oldgame = oldgame .. string.char(title[i])
i = i + 1
end
oldgame = oldgame:lower()
local checksum = get_game_checksum()
for v in pairs(game_checksum) do
if oldgame ~= "" and v:find(oldgame) ~= nil then
game = v
if game_checksum[game][checksum] ~= nil then
language = game_checksum[game][checksum]
data = language
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

counter = 0
oldtext = "" -- last text seen
in_keyboard = false

function main_loop()
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
