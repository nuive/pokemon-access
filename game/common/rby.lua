SCROLL_INDICATOR_POSITION = 239
HEALTH_BAR = "\x71\x62"
HEALTH_BAR_LIMIT = 0x6c
ENEMY_MAX_HEALTH = 14
kbd_pos = nil

ledge_tiles = {}
land_collision_pairs = {}
water_collision_pairs = {}
water_tilesets = {}
mansion_cliffs= {}
warp_tiles = {}
cut_tiles = {
[0] = 0x3d,
[7] = 0x50,
}
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
BADGE_CUT = 2
BADGE_SURF = 5

function format_names(name)
if name:match("[player]") then
name = string.gsub(name, "%[player]", get_custom_name(RAM_PLAYER_NAME))
end
if name:match("[rival]") then
name = string.gsub(name, "%[rival]", get_custom_name(RAM_RIVAL_NAME))
end
return name
end

function update_impassable_tiles()
for i=0x00, 0xff do
if is_cut_tile(i) then
if pathfind_hm_available then
impassable_tiles[i] = not has_badge(BADGE_CUT)
else
impassable_tiles[i] = not pathfind_hm_all
end
elseif is_water_tile(i) then
if pathfind_hm_available then
impassable_tiles[i] = not has_badge(BADGE_SURF)
else
impassable_tiles[i] = not pathfind_hm_all
end
else
impassable_tiles[i] = true
end
end
	local ptr = memory.readword(RAM_PASSABLE_TILES)
while memory.gbromreadbyte(ptr) ~= 0xff do
impassable_tiles[memory.gbromreadbyte(ptr)] = false
ptr = ptr + 1
end
end

function check_talking_over(tile)
ptr = RAM_PASSABLE_TILES+2
while ptr < RAM_GRASS_TILE and memory.readbyte(ptr) ~= 0xff do
if tile == memory.readbyte(ptr) then
return true
end
ptr = ptr + 1
end
return false
end

function get_map_id()
return memory.readbyte(RAM_MAP_NUMBER)
end

-- Returns true or false indicating whether we're on a map or not.
function on_map()
local mapnumber = get_map_id()
local textbox_top, textbox_bottom = get_textbox_border(5)
if mapnumber == 0xff or in_battle() then
return false
elseif screen.tile_lines[6]:find(textbox_top) and screen.tile_lines[12]:find(textbox_bottom) then
return false
else
return true
end
end

function get_warp_tiles()
local ptr = ROM_GENERAL_WARP_TILES
for dir = DOWN, RIGHT, 4 do
warp_tiles[0x20 +dir] = {}
while memory.gbromreadbyte(ptr) ~= 0xFF do
table.insert(warp_tiles[0x20 +dir], memory.gbromreadbyte(ptr))
ptr = ptr +1
end
ptr = ptr +1
end
local special_tiles = {}
local ptr = ROM_DOOR_TILES
while memory.gbromreadbyte(ptr) ~= 0xFF do
local index = memory.gbromreadbyte(ptr)
special_tiles[index] = {}
local doors = bit.bor(bit.band(memory.gbromreadword(ptr +1), 0x3FFF), bit.band(ROM_DOOR_TILES, 0xFFC000))
while memory.gbromreadbyte(doors) ~= 0 do
table.insert(special_tiles[index], memory.gbromreadbyte(doors))
doors = doors +1
end
ptr = ptr +3
end
ptr = ROM_SPECIAL_WARP_TILES
while memory.gbromreadbyte(ptr) ~= 0xFF do
local index = memory.gbromreadbyte(ptr)
if not special_tiles[index] then
special_tiles[index] = {}
end
table.insert(special_tiles[index], memory.gbromreadbyte(ptr +1))
ptr = ptr +3
end
ptr = ROM_WARP_TILES
for i = 0, MAX_TILESETS -1 do
warp_tiles[i] = get_rom_table(bit.bor(bit.band(memory.gbromreadword(ptr), 0x3FFF), bit.band(ROM_WARP_TILES, 0xFFC000)), 1)
if special_tiles[i] then
for _, v in pairs(special_tiles[i]) do
table.insert(warp_tiles[i], v)
end
end
ptr = ptr +2
end
end

function is_warp_tile(x, y)
local collisions = get_map_collisions()
local tileset = memory.readbyte(RAM_MAP_HEADER)
local mapid = get_map_id()
if mapid == 0x63 and collisions[y][x] == 0x15 then
return true
end

for dir = DOWN, RIGHT, 4 do
for _, v in pairs(warp_tiles[dir +0x20]) do
local dir_x, dir_y = decode_direction(dir)
if v == collisions[y +dir_y][x +dir_x] then
return true
end
end
end

for _, v in pairs(warp_tiles[tileset]) do
if v == collisions[y][x] then
return true
end
end

return false
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
if on_map_limit(warpx, warpy) or is_warp_tile(warpx, warpy) then
local name = message.translate("warp") .. i
local mapid = memory.gbromreadbyte(start+3)
if mapid == 0xff then
mapid = memory.readbyte(RAM_LAST_MAP_OUTDOORS)
end
local mapname = get_map_name(mapid)
if mapname ~= "" then
name = mapname
end
local warp = {x=warpx, y=warpy, name=name, type="warp", id="warp_" .. i}
warp.name = get_name(current_mapid, warp)
table.insert(results, warp)
end
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
local width, height = get_map_dimensions()
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
local collisions = get_map_collisions()
local tileset_number = memory.readbyte(RAM_MAP_HEADER)
for y = 0, #collisions - 6 do
for x = 0, #collisions[0] - 6 do
if (tileset_number == 0x04 and collisions[y][x] == 0x32)
or (tileset_number == 0x06 and collisions[y][x] == 0x52)
or (tileset_number == 0x10 and collisions[y][x] == 0x1b) then
table.insert(results, {name=message.translate("pc"), x=x, y=y, id="pc_" .. y .. x, type="object", ignorable=true})
elseif (tileset_number == 0x0d and collisions[y][x] == 0x58)
or (tileset_number == 0x07 and collisions[y][x] == 0x1b) then
table.insert(results, {name=message.translate("trashcan"), x=x, y=y, id="trashcan_" .. y .. x, type="object", ignorable=true})
elseif (tileset_number == 0x16 and (collisions[y][x] == 0x24 or collisions[y][x] == 0x18))
or (tileset_number == 0x10 and collisions[y][x] == 0x5e) then
table.insert(results, {name=message.translate("closed_door"), x=x, y=y, id="closeddoor_" .. y .. x, type="object", ignorable=true})
elseif (tileset_number == 0x16 and collisions[y][x] == 0x3d) then
table.insert(results, {name=message.translate("statue"), x=x, y=y, id="statue_" .. y .. x, type="object", ignorable=true})
-- special cinnabar gym
elseif (mapid == 0xa6 and tileset_number == 0x16 and (collisions[y][x] == 0x4c and collisions[y][x-1] ~= 0x4c and collisions[y][x+2] ~= 0x4c)) then
table.insert(results, {name=message.translate("quiz"), x=x, y=y, id="quiz_" .. y .. x, type="object", ignorable=true})
elseif (tileset_number == 0x11 and collisions[y][x] == 0x22)
or (tileset_number == 0x16 and collisions[y][x] == 0x11) then
table.insert(results, {name=message.translate("hole"), x=x, y=y, id="hole_" .. y .. x, type="object"})
elseif tileset_number == 0x11 and collisions[y][x] == 0x2d then
table.insert(results, {name=message.translate("switch"), x=x, y=y, id="switch_" .. y .. x, type="object", ignorable=true})
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
local block_index = blocks[y][x]
local ptr = collision_addr + (block_index * 0x10)
add_collision(x*2, y*2, memory.gbromreadbyte(ptr+4))
add_collision(x*2+1, y*2, memory.gbromreadbyte(ptr+6))
add_collision(x*2, y*2+1, memory.gbromreadbyte(ptr+(4*3)))
add_collision(x*2+1, y*2+1, memory.gbromreadbyte(ptr+(4*3)+2))
end -- x
end -- y

update_impassable_tiles()
return collisions
end

function get_block(mapx, mapy)
local width = memory.readbyte(RAM_MAP_WIDTH)
local row_width = width+6
local ptr = RAM_OVERWORLD_MAP+row_width*3
local skip_rows = bit.rshift(mapy, 1)
local skip_cols = bit.rshift(mapx, 1) + 3
local block = memory.readbyte(ptr+(skip_rows*row_width)+skip_cols)
return block
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

function is_collision(collisions, y, x)
return impassable_tiles[collisions[y][x]]
or check_collision_pair(memory.readbyte(RAM_MAP_HEADER), last_camera_tile, collisions[y][x])
end

function is_block_arrow(tileset, dir)
if block_move[tileset] ~= nil then
return compare(get_additional_collision_data(), block_move[tileset][dir])
end
return false
end

function check_preledge(collisions, y, x)
if bit.rshift(get_special_tiles_around(collisions, y, x), 4) ~= 0 then
return true
end
return false
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

function is_cut_tile(tile)
local tileset = memory.readbyte(RAM_MAP_HEADER)
if cut_tiles[tileset] ~= nil and cut_tiles[tileset] == tile then
return true
end
return false
end

function get_hm_command(node, last)
local command = ""
local count = true
if is_cut_tile(node.type) then
command = message.translate("bush")
elseif is_water_tile(node.type) and not is_water_tile(last.type) and last.type ~= 0xff then
command = message.translate("enter_water")
count = false
elseif not is_water_tile(node.type) and is_water_tile(last.type) and node.type ~= 0xff then
command = message.translate("exit_water")
count = false
end
return command, count
end

 function valid_path(node, neighbor)
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
elseif impassable_tiles[neighbor.type] then
return false
end
return true
end -- valid

function play_tile_sound(type, pan, vol, is_camera)
local tileset = memory.readbyte(RAM_MAP_HEADER)
	if type == memory.readbyte(RAM_GRASS_TILE) then
		audio.play(scriptpath .. "sounds\\gb\\s_grass.wav", 0, pan, vol)
	elseif is_cut_tile(type) then
		audio.play(scriptpath .. "sounds\\gb\\s_cut.wav", 0, pan, vol)
	elseif is_water_tile(type) then
		audio.play(scriptpath .. "sounds\\common\\s_water.wav", 0, pan, vol)
	elseif is_block_arrow(tileset, DOWN) then
		audio.play(scriptpath .. "sounds\\common\\s_move_down.wav", 0, pan, vol)
elseif is_block_arrow(tileset, UP) then
		audio.play(scriptpath .. "sounds\\common\\s_move_up.wav", 0, pan, vol)
elseif is_block_arrow(tileset, LEFT) then
		audio.play(scriptpath .. "sounds\\common\\s_move.wav", 0, -100, vol)
elseif is_block_arrow(tileset, RIGHT) then
		audio.play(scriptpath .. "sounds\\common\\s_move.wav", 0, 100, vol)
elseif is_camera and ((tileset == 0x16 and type == 0x5e)
or (tileset == 0x07 and type == 0x3f)) then
		audio.play(scriptpath .. "sounds\\common\\no_pass.wav", 0, pan, vol)
	elseif is_camera and (type == 0x13 or type == 0x43) then
		audio.play(scriptpath .. "sounds\\common\\s_stairup.wav", 0, pan, vol)
	elseif is_camera and (type == 0x1b) then
		audio.play(scriptpath .. "sounds\\common\\s_stairdown.wav", 0, pan, vol)
	elseif is_camera and tileset == 0x11 and type == 0x22 then
		audio.play(scriptpath .. "sounds\\common\\s_hole.wav", 0, pan, vol)
	elseif is_camera and tileset == 0x11 and type == 0x2d then
		audio.play(scriptpath .. "sounds\\common\\s_switch.wav", 0, pan, vol)
	else
		audio.play(scriptpath .. "sounds\\gb\\s_default.wav", 0, pan, vol)
	end -- switch tile type
local x, y = nil
if is_camera then
x, y = get_camera_xy()
else
x, y = get_player_xy()
end

if check_preledge(get_map_collisions(), y, x) then
audio.play(scriptpath .. "sounds\\common\\s_mad.wav", 0, pan, vol)
end
end

function keyboard_showing(screen)
if screen.lines[16]:match(KEYBOARD_LOWER_STRING) ~= nil
or screen.lines[16]:match(KEYBOARD_UPPER_STRING) ~= nil then
return true
end
return false
end

function handle_keyboard()
local pos = memory.readbyte(RAM_KEYBOARD_POSITION)
if pos ~= kbd_pos then
read_keyboard()
kbd_pos = pos
end
end -- handle_keyboard

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

function read_special_variable_text()
-- town map fix
if screen.tile_lines[2]:find("\x66\x67\x67\x67\x68\x64") then
tolk.output(translate_tileline(screen.tile_lines[1]))
end
end

function in_pokedex()
if screen.tile_lines[1]:find("\x7f\x71\x7f") ~= nil
and screen.tile_lines[7]:find("\x7f\x70\x7a") then
return true
end
return false
end

pokedex_info = nil
function handle_special_cases()
if screen:keyboard_showing() then
handle_keyboard()
else
kbd_pos = nil
end -- handling keyboard
-- pokedex fixes
if in_pokedex() then
local startpos = screen.tile_lines[1]:find("\x7f\x71\x7f")
local seen = trim(translate_tileline(get_menu_item(screen.tile_lines[2], startpos+1)))
local num_seen = trim(translate_tileline(get_menu_item(screen.tile_lines[3], startpos+1)))
local have = trim(translate_tileline(get_menu_item(screen.tile_lines[5], startpos+1)))
local num_have = trim(translate_tileline(get_menu_item(screen.tile_lines[6], startpos+1)))
if seen ~= "" then
local tospeak = seen .. ": " .. num_seen .. "; " .. have .. ": " .. num_have
if tospeak ~= pokedex_info then
tolk.output(tospeak)
pokedex_info = tospeak
end
end
else
pokedex_info = nil
end
end

memory.registerexec(ROM_FOOTSTEP_FUNCTION, function()
if on_map() then
local player_x, player_y = get_player_xy()
local collisions = get_map_collisions()
local type = collisions[player_y][player_x]
camera_x = -7
camera_y = -7
play_tile_sound(type, 0, 30, false)
end
end)
table.insert(callback_functions, ROM_FOOTSTEP_FUNCTION)

-- initialize tables based in rom values
ledge_tiles = get_rom_table(ROM_LEDGE_TILES, 4)
land_collision_pairs = get_rom_table(ROM_LAND_COLLISION_PAIRS, 3)
water_collision_pairs = get_rom_table(ROM_LAND_COLLISION_PAIRS+34, 3)
water_tilesets = get_rom_table(ROM_WATER_TILESETS, 1)
mansion_cliffs = get_rom_table(ROM_MANSION_CLIFFS, 2)

