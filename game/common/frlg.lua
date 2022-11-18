OPTION_WIDTH = 0x72
PRIMARY_METATILES = 0x280
BADGES_START = 0x820
BADGE_CUT = 2
BADGE_SURF = 5
BADGE_WATERFALL = 0
MAP_POPUP_LINE = 9
BATTLE_MENU_LINE = 11
DOUBLE_COORDS = {
[0] = {71, 72},
[1] = {15},
[2] = {96, 97},
[3] = {40}
}
BATTLE_YESNO_WINDOW = 14
BATTLE_YESNO_LINE = 11
DEPOSIT_BOX_LINE = 19
BOULDER_SPRITE = 0x61
GRASS_TILES = {0x02, 0xD1}
WATER_TILES = {0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x1A, 0x1B, 0x50, 0x51, 0x52, 0x53}
WARP_TILES = {0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x71}
HOLE_TILES = {0x66, 0x68}
tile_objects = {
[0x20] = {"switch", true},
[0x26] = {"thin_ice", true},
[0x27] = {"cracked_ice", false},
[0x83] = {"pc", false}
}
tile_sounds = {
[0x23] = {{"sounds\\common\\s_ice.wav", false}},
[0x26] = {{"sounds\\gba\\s_thin_ice.wav", false}},
[0x27] = {{"sounds\\gba\\s_cracked_ice.wav", true},
{"sounds\\gba\\s_thin_ice.wav", false}},
[0x62] = {{"sounds\\common\\s_stair.wav", true, 100}},
[0x63] = {{"sounds\\common\\s_stair.wav", true, -100}},
[0x64] = {{"sounds\\gba\\s_stairnorth.wav", true}},
[0x65] = {{"sounds\\gba\\s_stairsouth.wav", true}},
[0x6A] = {{"sounds\\common\\s_stairup.wav", false}},
[0x6B] = {{"sounds\\common\\s_stairdown.wav", false}},
[0x6C] = {{"sounds\\common\\s_stairup.wav", false, 100}},
[0x6D] = {{"sounds\\common\\s_stairup.wav", false, -100}},
[0x6E] = {{"sounds\\common\\s_stairdown.wav", false, 100}},
[0x6F] = {{"sounds\\common\\s_stairdown.wav", false, -100}}
}
additional_tile_sounds = {
[0x20] = {"sounds\\common\\s_switch.wav", true},
[0x50] = {"sounds\\common\\s_move.wav", false, 100},
[0x51] = {"sounds\\common\\s_move.wav", false, -100},
[0x52] = {"sounds\\common\\s_move_up.wav", false},
[0x53] = {"sounds\\common\\s_move_down.wav", false},
[0x54] = {"sounds\\common\\s_move.wav", false, 100},
[0x55] = {"sounds\\common\\s_move.wav", false, -100},
[0x56] = {"sounds\\common\\s_move_up.wav", false},
[0x57] = {"sounds\\common\\s_move_down.wav", false},
[0x58] = {"sounds\\common\\no_pass.wav", true},
}

TEXTBOX_BORDER = {
"\x00\x13\x00\x14\x00\x15\x00\x16\x00\x17",
"\x08\x13\x08\x14\x08\x15\x08\x16\x08\x17",
"\x00\x4f\x00\x50\x00\x51\x00\x52\x00\x53",
"\x08\x4f\x08\x50\x08\x51\x08\x52\x08\x53",
"\x00\x6d\x00\x6e\x00\x6f\x00\x70\x00\x71",
"\x08\x6d\x08\x6e\x08\x6f\x08\x70\x08\x71",
"\x02\x00\x02\x01\x02\x02\x02\x03\x02\x04",
"\x0A\x00\x0A\x01\x0A\x02\x0A\x03\x0A\x04",
"\x00\x01\x00\x02\x00\x02\x00\x03",
"\x00\x07\x00\x08\x00\x08\x00\x09",
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

function questlog_clean()
local id = memory.getregister("r0")
if not text_window[id] then
return
end
for i = 0, 0x2D00 do
text_window[id][i] = 0xFF
end
end

function blit_move_info_icon()
local window = get_window(memory.getregister("r0"), false)
if not window.data then
return
end

local type = memory.getregister("r1")
local x = memory.getregister("r2")
local y = memory.getregister("r3") +8
window.data[get_window_pixel_address(window, x, y)] = bit.bor(type, 0xFB00)
ignore_bitmap = true
end

function handle_fake_textbox()
if check_window_present(WINDOW_BATTLE) then
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
elseif check_window_present(WINDOW_BAG) or check_window_present(WINDOW_PC_BAG) or check_window_present(WINDOW_PC_BAG_WITHDRAW) then
fake_textbox = {1}
elseif check_window_present(WINDOW_TM_CASE) then
if not window_is_empty(get_window(6)) then
fake_textbox = {6}
else
fake_textbox = {1}
end
elseif check_window_present(WINDOW_BERRY_POUCH) then
fake_textbox = {1}
elseif check_window_present(WINDOW_NEWGAME_HELP1, 2) then
fake_textbox = {2}
elseif check_window_present(WINDOW_NEWGAME_HELP2, 2) or check_window_present(WINDOW_NEWGAME_HELP3, 2) then
fake_textbox = {2, 3, 4}
elseif check_window_present(WINDOW_NEWGAME_INTRO, 2, 1) then
fake_textbox = {2}
elseif check_window_present(WINDOW_TV) then
fake_textbox = {0}
else
fake_textbox = nil
end
end

function read_mainmenu_item()
local position = memory.getregister("r2") / 0x100
local lines = get_window_screen().lines
tolk.output(lines[position + 19])
end

function read_option_menu_item()
local option = memory.getregister("r2")
option_menu_pos = option +11
read_option = true
end

function read_suboption_menu_item()
read_suboption = true
end

function get_readable_option(tileline, only_option)
local selected_option = translate_tileline(tileline:sub(1, OPTION_WIDTH -1))
local selected_text = translate_tileline(tileline:sub(OPTION_WIDTH))
if not only_option then
return selected_option .. " " .. selected_text
else
return selected_text
end
return selected_option
end

function read_mapname_if_needed()
if check_window_present(WINDOW_MAP) then
read_window(get_window(0))
end
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
return bit.rshift(bit.band(memory.readdword(attributes + block *4), attribute), bit_shift)
end

function get_block_type(block)
return get_block_attribute(block, 0x1FF, 0)
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

function is_water(type, surfing_water)
if surfing_water == nil then
surfing_water = true
end

if surfing_water and type == 0x11 then
return false
end

for _, v in pairs(WATER_TILES) do
if type == v then
return true
end
end
return false
end

function get_num_objects()
return memory.readbyte(memory.readdword(RAM_MAP_EVENT_HEADER_POINTER))
end

specific_functions = {
[ROM_BLIT_MOVE_INFO_ICON] = blit_move_info_icon,
[ROM_MOVE_SELECTION] = read_move_menu_item,
[ROM_TM_CASE_SELECTION] = read_tm_case_info,
[ROM_QUESTLOG_CLEAN] = questlog_clean,
}

