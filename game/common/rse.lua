PRIMARY_METATILES = 0x200
BADGES_START = 0x867
BADGE_CUT = 1
BADGE_SURF = 5
BADGE_DIVE = 7
BADGE_WATERFALL = 8
MAP_POPUP_LINE = 18
BATTLE_MENU_LINE = 10
DOUBLE_COORDS = {
[0] = {72, 73},
[1] = {15},
[2] = {97, 98},
[3] = {40}
}
BATTLE_YESNO_WINDOW = 12
BATTLE_YESNO_LINE = 10
DEPOSIT_BOX_LINE = 18
BOULDER_SPRITE = 0x57
ROTATING_GATE_MAPS = {3073, 7432}
ROTATING_PUZZLE_START = {
[3584] = 0x250,
[7433] = 0x298
}
BATTLE_PYRAMID_LAYOUTS = {0x169, 0x17A}
TRAINER_HILL_LAYOUT = 0x19F
GRASS_TILES = {0x02, 0x03}
WATER_TILES = {0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x1A, 0x1B, 0x50, 0x51, 0x52, 0x53}
WARP_TILES = {0x0D, 0x0E, 0x1B, 0x1C, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x70, 0x8D}
HOLE_TILES = {0x0F, 0x29, 0x66, 0x68}
tile_sounds = {
[0x20] = {{"sounds\\common\\s_ice.wav", false}},
[0x26] = {{"sounds\\gba\\s_thin_ice.wav", false}},
[0x27] = {{"sounds\\gba\\s_cracked_ice.wav", true},
{"sounds\\gba\\s_thin_ice.wav", false}},
[0x48] = {{"sounds\\common\\s_ice.wav", false}},
[0x62] = {{"sounds\\common\\s_stair.wav", true, 100}},
[0x63] = {{"sounds\\common\\s_stair.wav", true, -100}},
[0x64] = {{"sounds\\gba\\s_stairnorth.wav", true}},
[0x65] = {{"sounds\\gba\\s_stairsouth.wav", true}},
[0x6A] = {{"sounds\\common\\s_stairup.wav", false}},
[0x6B] = {{"sounds\\common\\s_stairdown.wav", false}}
}
additional_tile_sounds = {
[0x44] = {"sounds\\common\\s_move.wav", false, 100},
[0x45] = {"sounds\\common\\s_move.wav", false, -100},
[0x46] = {"sounds\\common\\s_move_up.wav", false},
[0x47] = {"sounds\\common\\s_move_down.wav", false},
[0x50] = {"sounds\\common\\s_move.wav", false, 100},
[0x51] = {"sounds\\common\\s_move.wav", false, -100},
[0x52] = {"sounds\\common\\s_move_up.wav", false},
[0x53] = {"sounds\\common\\s_move_down.wav", false},
}
tile_objects = {
[0x26] = {"thin_ice", true},
[0x27] = {"cracked_ice", false},
[0x83] = {"pc", false},
[0x8c] = {"closed_door", true},
[0xb0] = {"pc", false},
[0xe4] = {"trashcan", false}
}

TEXTBOX_BORDER = {
"\x00\x01\x00\x02\x00\x02\x00\x03",
"\x00\x06\x00\x07\x00\x07\x00\x08",
"\x00\x02\x00\x03\x00\x03\x00\x04",
"\x00\x08\x00\x09\x00\x09\x00\x0A",
"\x00\x4f\x00\x50\x00\x50\x00\x51",
"\x00\x55\x00\x56\x00\x56\x00\x57",
"\x00\x97\x00\x98\x00\x98\x00\x99",
"\x00\x9d\x00\x9e\x00\x9e\x00\x9f",
"\x02\x14\x02\x15\x02\x15\x02\x16",
"\x02\x1a\x02\x1b\x02\x1b\x02\x1c",
"\x00\x03\x00\x04\x00\x04\x00\x69",
"\x08\x03\x08\x04\x08\x04\x00\x79",
"\x00\x0b\x00\x0d\x00\x0e\x00\x0f\x00\x10",
"\x08\x0b\x08\x0d\x08\x0e\x08\x0f\x08\x10",
"\x00\x15\x00\x17\x00\x18\x00\x19\x00\x1a",
"\x08\x15\x08\x17\x08\x18\x08\x19\x08\x1a",
"\x00\xfd\x00\xff\x01\x00\x01\x01\x01\x02",
"\x08\xfd\x08\xff\x09\x00\x09\x01\x09\x02",
"\x02\x01\x02\x03\x02\x04\x02\x05\x02\x06",
"\x0a\x01\x0a\x03\x0a\x04\x0a\x05\x0a\x06",
"\x02\x70\x02\x71\x02\x71\x02\x72",
"\x02\x75\x02\x76\x02\x76\x02\x77",
}

function handle_fake_textbox()
if check_window_present(WINDOW_BATTLE) or check_window_present(WINDOW_BATTLE_ARENA) then
if not window_is_empty(get_window(0)) then
fake_textbox = {0}
else
local x, y = get_screen_starting_position(0)
if y == 160 then
fake_textbox = {1}
else
fake_textbox = nil
end
end
elseif check_window_present(WINDOW_BAG)
or check_window_present(WINDOW_BAG_PYRAMID) then
fake_textbox = {1}
elseif check_window_present(WINDOW_PC_BAG_WITHDRAW, 1, 4) then
MAX_TEXTBOX_HEIGHT = 7
else
fake_textbox = nil
end
end

function read_mainmenu_item()
local position = bit.rshift(memory.getregister("r1"), 8)
local lines = get_window_screen().lines
tolk.output(lines[position + 17])
end

function read_option_menu_item()
local option = memory.getregister("r0")
option_menu_pos = option  *16 +10
read_option = true
end

function read_suboption_menu_item()
local window = 1
local x = memory.getregister("r6") -1
local y = memory.readdword(memory.getregister("r13")) +8
local pos = get_window_pixel_address(get_window(window, false), x, y)
if memory.getregister("r3") ~= 0 then
text_window[window][pos] = 0xFAEF
else
text_window[window][pos] = 0xFF
end
read_suboption = true
end

function get_readable_option(tileline, only_option)
local position = tileline:find("\xfa\xef")
local selected_option_end
if option_menu_pos == 90 then
selected_option_end = position -1
else
selected_option_end = OPTION_WIDTH -1
end
local selected_option = translate_tileline(tileline:sub(1, selected_option_end))
if position ~= nil then
local selected_text = translate_tileline(tileline:sub(position))
position = selected_text:find(" ")
if position ~= nil then
selected_text = selected_text:sub(1, position)
end
if not only_option then
return selected_option .. " " .. selected_text
else
return selected_text
end
end
return selected_option
end

function berry_blender_arrow()
local player_id = memory.getregister("r6")
local berry_blender = memory.readdword(RAM_BERRY_BLENDER)
local pos = (memory.readword(berry_blender +0x4A) /0x100) +24
local arrow_id = memory.readword(berry_blender +0x96 +player_id *2)
local hit_range = memory.readbyte(ROM_BERRY_BLENDER_RANGE +arrow_id)
if loop_audio then
audio.pitch(pos *2, loop_audio.handle)
end
if pos >= hit_range and pos < hit_range +48 then
if not indicator then
indicator = audio.play(scriptpath .. "sounds\\gba\\indicator.wav", 0, 0, 30)
end
elseif indicator then
audio.stop(indicator)
indicator = nil
end
end

function fishing_got_bite()
audio.play(scriptpath .. "sounds\\gba\\s_rod.wav", 0, 0, 30)
end

function read_pokenav_description()
local window = memory.readword(memory.readdword(memory.readdword(RAM_POKENAV_RESOURCES) +RAM_SUBSTRUCT_PTRS +8) +4)
if not text_window[window] then
return
end

read_window(get_window(window))
end

function can_fly()
local map_type = memory.readbyte(memory.readdword(RAM_FLY_MAP_POINTER) +RAM_FLY_MAP_TYPE)
if map_type == 2 or map_type == 4 then
audio.play(scriptpath .. "sounds\\gba\\s_fly.wav", 0, 0, 30)
end
end

function set_wall_clock()
local base_address = memory.getregister("r1")
local hours = memory.readword(base_address +12)
local minutes = memory.readword(base_address +14)
tolk.output(string.format("%d:%02d", hours, minutes))
end

function read_berry_tag()
read_window(get_window(0))
read_window(get_window(1))
tolk.output(table.concat(get_window_text(get_window(2))))
end

function read_pokeblock()
if memory.getregister("r1") ~= 0x1005 then
return
end

local window = 1
if not text_window[window] then
return
end

local position = 10 +memory.getregister("r0") *16
local tiles = get_window_tilelines(get_window(window))
if tiles[position] then
local item = translate_tileline(tiles[position])
if item ~= "" then
tolk.output(item)
end
end
local bg_width = SCREEN_WIDTH /4
local bg = get_bg_screen()
for i = 0, 4 do
local x = ((math.floor(i /3) *6) +2) *2
local y = (i %3 *2) +14
if bg[y]:sub(x, x):byte() == 0x17 then
read_window(get_window(2 +i))
end
end

window = 7
if not text_window[window] then
return
end

local position = 10
local tiles = get_window_tilelines(get_window(window))
if tiles[position] then
local item = translate_tileline(tiles[position])
if item ~= "" then
tolk.output(message.translate("feel") .. " " .. item)
end
end
end

function read_pokeblock_pokemon()
read_window(get_window(0))
read_window(get_window(1))
end

function show_types_in_summary()
tmp_sheet = create_window(nil, 0, 0, 736, 16, 0xFF)

for i = 0, 22 do
tmp_sheet.data[512 *i +392] = 0xFB00 +i
end
end

function get_map_name(mapid)
if get_player_gender() ~= 0 and mapid >= 256 and mapid <= 259 then
if mapid == 256 or mapid == 257 then
mapid = mapid +2
else
mapid = mapid -2
end
end
if names[mapid] ~= nil and names[mapid]["map"] ~= nil then
return format_names(names[mapid]["map"])
elseif maps[mapid] ~= nil then
return format_names(maps[mapid])
else
return message.translate("map") .. mapid
end
end

function get_player_gender()
return memory.readbyte(memory.readdword(RAM_SAVEBLOCK2_POINTER) +8)
end

function read_mapname_if_needed()
if check_window_present(WINDOW_FLY_MAP)
or check_window_present(WINDOW_MAP) then
local window = get_window(0)
if window_is_empty(window) then
read_window(get_window(1))
else
read_window(window)
end
elseif memory.readdword(memory.readdword(RAM_POKENAV_RESOURCES)) == ROM_CB_POKENAV_REGION_MAP then
read_window(get_window(1))
end
end

function get_block_type(block)
block = bit.band(block, 0x3FF)

local map_header = memory.readdword(RAM_MAP_HEADER_POINTER)
local tileset = 0
if block < PRIMARY_METATILES then
tileset = memory.readdword(map_header + RAM_MAP_PRIMARY_TILESET)
else
tileset = memory.readdword(map_header + RAM_MAP_SECONDARY_TILESET)
block = block - PRIMARY_METATILES
end

local attributes = memory.readdword(tileset + 16)
return bit.band(memory.readword(attributes + block *2), 0xFF)
end

function format_names(name)
if name:match("[player]") then
name = string.gsub(name, "%[player]", get_custom_name(memory.readdword(RAM_SAVEBLOCK2_POINTER) + RAM_PLAYER_NAME))
end
if name:match("[pyramid_floor]") then
name = string.gsub(name, "%[pyramid_floor]", memory.readword(memory.readdword(RAM_SAVEBLOCK2_POINTER) +RAM_FRONTIER_CHALLENGE_NUM) +1)
end
return name
end

function is_water(type)
for _, v in pairs(WATER_TILES) do
if type == v then
return true
end
end
return false
end

function is_secret_base(type)
if bit.band(type, 0xF0) == 0x90
and type %2 == 1 then
return true
end
return false
end

function in_trainer_hill()
local layout = memory.readword(RAM_MAP_LAYOUT_TYPE)
if layout >= TRAINER_HILL_LAYOUT and layout < TRAINER_HILL_LAYOUT +4 then
return true
end
return false
end

function in_battle_pyramid()
local layout = memory.readword(RAM_MAP_LAYOUT_TYPE)
for _, v in pairs(BATTLE_PYRAMID_LAYOUTS) do
if v == layout then
return true
end
end
return false
end

function get_num_battle_pyramid_objects()
local ptr = memory.readdword(RAM_SAVEBLOCK1_POINTER)+RAM_MAP_OBJECTS
local i = 0
while i < 16 do
local id = memory.readbyte(ptr +24 *i)
if id == 0 then
break
end
i = i +1
end
return i
end

function get_num_objects()
if in_trainer_hill() then
return 2
elseif in_battle_pyramid() then
return get_num_battle_pyramid_objects()
else
return memory.readbyte(memory.readdword(RAM_MAP_EVENT_HEADER_POINTER))
end
end

function get_gate_rotation_info(x, y, dir)
local distance
if dir == UP then
distance = 0
elseif dir == DOWN then
distance = 16
elseif dir == LEFT then
distance = 32
elseif dir == RIGHT then
distance = 48
end
return memory.readbyte(ROM_ROTATING_GATES_ROTATION_INFO +distance +y *4 +x)
end

function gate_has_arm(arm_info, orientation, shape)
local arm_orientation = (math.floor(arm_info /2) -orientation +4) %4
return memory.readbyte(ROM_ROTATING_GATES_ARM_LAYOUT +shape *8 +arm_orientation *2 +arm_info %2)
end

function can_rotate_gate(x, y, shape, orientation, rotation_dir, impassables)
if rotation_dir == 0 then
return false
end

local arm_pos = ROM_ROTATING_GATES_ARM_POSITIONS +0x20 *bit.band(rotation_dir, 1)
for i = 0, 3 do
for j = 0, 1 do
local arm_index = 2 *((orientation +i) %4) +j
if memory.readbyte(ROM_ROTATING_GATES_ARM_LAYOUT +shape *8 +i *2 +j) ~= 0 then
if impassables[y +memory.readbytesigned(arm_pos +arm_index *4 +1)][x +memory.readbytesigned(arm_pos +arm_index *4)] then
return false
end
end
end
end
return true
end

function is_rotating_gate(x, y, dir)
local mapid = get_map_id()
if not contains(ROTATING_GATE_MAPS, mapid) then
return -1
end

local gates = memory.readbyte(RAM_ROTATING_GATE_PUZZLE_COUNT)
local impassables = get_blocks_impassable()
local ptr = memory.readdword(RAM_ROTATING_GATE_PUZZLE)
for i = 0, gates do
local gate_x = memory.readword(ptr)
local gate_y = memory.readword(ptr + 2)
if x >= gate_x -2 and x < gate_x +2
and y >= gate_y -2 and y < gate_y +2 then
if dir == -1 then
return 1
end

local rotation = get_gate_rotation_info(x -gate_x +2, y -gate_y +2, dir)

if rotation ~= 0xFF then
local arm_info = bit.band(rotation, 0xF)
local rotation_dir = bit.rshift(bit.band(rotation, 0xF0), 4)
local orientation = memory.readbyte(get_var_pointer(VARS_START) +i)
local shape = memory.readbyte(ptr + 4)
if gate_has_arm(arm_info, orientation, shape) ~= 0 then
if can_rotate_gate(gate_x, gate_y, shape, orientation, rotation_dir, impassables) then
return 2
end
return 0
end
end
return 1
end
ptr = ptr +8
end
return -1
end

function is_rotating_gate_collision(x, y, dir)
local mapid = get_map_id()
if not contains(ROTATING_GATE_MAPS, mapid) then
return false
end

local gates = memory.readbyte(RAM_ROTATING_GATE_PUZZLE_COUNT)
local ptr = memory.readdword(RAM_ROTATING_GATE_PUZZLE)
for gate = 0, gates do
local gate_x = memory.readword(ptr)
local gate_y = memory.readword(ptr + 2)
if x >= gate_x -2 and x < gate_x +2
and y >= gate_y -2 and y < gate_y +2 then
local rotation = get_gate_rotation_info(x -gate_x +2, y -gate_y +2, dir)

if rotation ~= 0xFF then
local arm_info = bit.band(rotation, 0xF)
local rotation_dir = bit.rshift(bit.band(rotation, 0xF0), 4)
local orientation = memory.readbyte(get_var_pointer(VARS_START) +gate)
local shape = memory.readbyte(ptr + 4)
if gate_has_arm(arm_info, orientation, shape) ~= 0 then
return true
end
end
end
ptr = ptr +8
end
return false
end

function trigger_new_mauville(results)
local mapid = get_map_id()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local triggers = memory.readbyte(eventstart +2)
local ptr = memory.readdword(eventstart+12)
for i = 1, triggers do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
local var = memory.readword(ptr +6)
if check_coordinates_on_screen(x, y) then
local ignorable = (get_var(var) == 1)
local name
if var == 0x4001 then
name = message.translate("blue_switch")
elseif var == 0x4002 then
name = message.translate("green_switch")
else
name = message.translate("red_switch")
end
local trigger = {x=x, y=y, name=name, type="object", id="switch_" .. y .. x, ignorable=ignorable}
trigger.name = get_name(mapid, trigger)
table.insert(results, trigger)
end
ptr = ptr +16
end
end

function trigger_switch(results)
local mapid = get_map_id()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local triggers = memory.readbyte(eventstart +2)
local ptr = memory.readdword(eventstart+12)
for i = 1, triggers do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
local ignorable = (get_var(0x4008) == i)
local trigger = {x=x, y=y, name=message.translate("switch"), type="object", id="switch_" .. y .. x, ignorable=ignorable}
trigger.name = get_name(mapid, trigger)
table.insert(results, trigger)
end
ptr = ptr +16
end
end

function trigger_rotating_gate(results)
local mapid = get_map_id()
local gates = memory.readbyte(RAM_ROTATING_GATE_PUZZLE_COUNT)
local impassables = get_blocks_impassable()
local ptr = memory.readdword(RAM_ROTATING_GATE_PUZZLE)
for i = 0, gates do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
--[[ for y = gate_y -1, gate_y +1 do
for x = gate_x -1, gate_x +1 do
for dir = DOWN, RIGHT do
local rotation = get_gate_rotation_info(x -gate_x +2, y -gate_y +2, dir)

if rotation ~= 0xFF then
local arm_info = bit.band(rotation, 0xF)
local rotation_dir = bit.rshift(bit.band(rotation, 0xF0), 4)
local orientation = memory.readbyte(get_var_pointer(VARS_START) +i)
local shape = memory.readbyte(ptr + 4)
if gate_has_arm(arm_info, orientation, shape) ~= 0
and can_rotate_gate(gate_x, gate_y, shape, orientation, rotation_dir, impassables) then
--]] local gate = {x=x, y=y, name=message.translate("rotating_gate"), type="object", id="gate_" .. y .. x, ignorable=true}
gate.name = get_name(mapid, gate)
table.insert(results, gate)
-- end
-- end
-- end
-- end
-- end
end
ptr = ptr +8
end
end

function get_metatile_color(color)
if color < 8 then
return "yellow"
elseif color < 16 then
return "blue"
elseif color < 24 then
return "green"
elseif color < 32 then
return "purple"
elseif color < 40 then
return "red"
end
return nil
end

function trigger_rotating_puzzle(results)
local mapid = get_map_id()
local blocks = get_map_blocks()
for _,v in pairs(results) do
local metatile = bit.band(blocks[v.y][v.x], 0x3FF)
if metatile >= ROTATING_PUZZLE_START[mapid] and metatile < ROTATING_PUZZLE_START[mapid] +40 then
v.name = string.format("%s (%s %s)", v.name, message.translate("over"), message.translate(get_metatile_color(metatile -ROTATING_PUZZLE_START[mapid]) .. "_tile"))
end
end
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local triggers = memory.readbyte(eventstart +2)
local ptr = memory.readdword(eventstart+12)
for i = 1, triggers do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
if check_coordinates_on_screen(x, y) then
local metatile = bit.band(blocks[y][x], 0x3FF)
local trigger = {x=x, y=y, name=message.translate(get_metatile_color(metatile -ROTATING_PUZZLE_START[mapid]) .. "_switch"), type="object", id="switch_" .. y .. x, ignorable=true}
trigger.name = get_name(mapid, trigger)
table.insert(results, trigger)
end
ptr = ptr +16
end
end

function trigger_battle_pike(results)
local mapid = get_map_id()
local eventstart = memory.readdword(RAM_MAP_EVENT_HEADER_POINTER)
local triggers = memory.readbyte(eventstart +2)
local ptr = memory.readdword(eventstart+12)
for i = 1, triggers do
local x = memory.readword(ptr)
local y = memory.readword(ptr + 2)
local var = memory.readword(ptr +6)
if check_coordinates_on_screen(x, y) and var ~= 0x4002 then
local trigger = {x=x, y=y, name=message.translate("door"), type="warp", id="door" .. y .. x, ignorable=true}
trigger.name = get_name(mapid, trigger)
table.insert(results, trigger)
end
ptr = ptr +16
end
end

function exit_battle_pyramid(results)
local blocks = get_map_blocks()
for y = 0, #blocks -8 do
for x = 0, #blocks[0] -9 do
local metatile = bit.band(blocks[y][x], 0x3FF)
if metatile == 0x28E then
if check_coordinates_on_screen(x, y) then
local exit = {x=x, y=y, name=message.translate("door"), type="warp", id="door" .. y .. x}
exit.name = get_name(mapid, exit)
table.insert(results, exit)
end
end
end
end
end

map_object_triggers = {
[3073] = {trigger_rotating_gate},
[3584] = {trigger_rotating_puzzle},
[6197] = {trigger_new_mauville},
[6682] = {exit_battle_pyramid},
[6692] = {trigger_battle_pike},
[6693] = {trigger_battle_pike},
[6695] = {trigger_battle_pike},
[7428] = {true, "switch"},
[7429] = {trigger_switch},
[7432] = {trigger_rotating_gate},
[7433] = {trigger_rotating_puzzle},
}

specific_functions = {
[ROM_COPY_TYPE_ICONS] = show_types_in_summary,
[ROM_FISHING_GOT_BITE] = fishing_got_bite,
[ROM_BERRY_BLENDER_INPUT] = berry_blender_arrow,
[ROM_PRINT_POKENAV_DESCRIPTION] = read_pokenav_description,
[ROM_SET_FLY_MAP_LOCATION] = can_fly,
[ROM_SET_WALL_CLOCK] = set_wall_clock,
[ROM_SELECT_POKEBLOCK] = read_pokeblock,
[ROM_SELECT_POKEBLOCK_POKEMON] = read_pokeblock_pokemon,
[ROM_CHECK_BERRY_TAG] = read_berry_tag,
[ROM_CHECK_ANOTHER_BERRY_TAG] = read_berry_tag
}

indicator = nil

