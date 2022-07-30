require "a-star"
serpent = require "serpent"
message = require "message"
inputbox = require "Inputbox"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
callback_functions = {}
langmap = {
["D"] = "de",
["E"] = "en",
["F"] = "fr",
["I"] = "it",
["S"] = "es",
}
pathfind_hm_available = false
pathfind_hm_all = false

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
for i, v in ipairs(REQUIRED_FILES) do
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
message.set_strings(language)
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

function get_lesser(num1, num2)
if num1 < num2 then
return num1
else
return num2
end
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

function reset_camera_focus(player_x, player_y)
	if camera_x == DEFAULT_CAMERA_X and camera_y == DEFAULT_CAMERA_Y then
		camera_x = player_x
		camera_y = player_y
if device == "gb" then
last_camera_tile = 0xff
	end
	end
end

function set_camera_default()
	camera_x = DEFAULT_CAMERA_X
	camera_y = DEFAULT_CAMERA_Y
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

function contains(table, key)
for _, v in pairs(table) do
if v == key then
return true
end
end
return false
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
if not pathfind_hm_available and not pathfind_hm_all then
pathfind_hm_available = true
tolk.output(message.translate("use_hm_available"))
elseif pathfind_hm_available then
pathfind_hm_available = false
pathfind_hm_all = true
tolk.output(message.translate("use_hm_all"))
else
pathfind_hm_all = false
tolk.output(message.translate("not_use_hm"))
end
if device == "gb" then
update_impassable_tiles()
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
s = s .. string.format(message.translate("facing"), facing_to_string(item.facing))
end
tolk.output(s)
end

function clean_path(path)
local start = path[1]
local new_path = {}
for i, node in ipairs(path) do
if i > 1 then
local last = path[i-1]
local command = ""
local count = 1
if pathfind_hm_available or pathfind_hm_all then
command, count = get_hm_command(node.type, last.type)
end
if command ~= "" then
command = command .. string.format(" %s ", message.translate("on_way"))
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

function read_health(health_function)
if not in_battle() then
tolk.output(message.translate("not_in_battle"))
return
end

local health = health_function()
if health == nil or health == "" then
tolk.output(message.translate("no_bar"))
else
tolk.output(health)
end
end

function read_enemy_health()
read_health(get_enemy_health)
end

function read_player_health()
read_health(get_player_health)
end

function rename_current()
local info = get_map_info()
reset_current_item_if_needed(info)
local id = get_map_id()
local obj_id = info.objects[current_item].id
name = inputbox.inputbox(message.translate("new_name"), string.format(message.translate("enter_newname"), info.objects[current_item].name), info.objects[current_item].name)
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
name = inputbox.inputbox(message.translate("new_name"), string.format(message.translate("enter_newname"), mapname), mapname)
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

function get_custom_name(name_offset)
local name = ""
local i = 0
local char = memory.readbyte(name_offset+i)
while char ~= CHAR_NAME_END do
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

function get_camera_xy()
if camera_x == DEFAULT_CAMERA_X and camera_y == DEFAULT_CAMERA_Y then
return get_player_xy()
else
return camera_x, camera_y
end
end

function init_script()
device = get_device()
loadfile(scriptpath .. device .. ".lua")()
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
[{"M"}] = {read_mapname, true, true};
[{"K", "shift"}] = {rename_current, true, true};
[{"M", "shift"}] = {rename_map, true, true};
[{"E"}] = {read_tiles, true, true},
[{"D"}] = {camera_move_left, true, true},
[{"G"}] = {camera_move_right, true, true},
[{"R"}] = {camera_move_up, true, true},
[{"V"}] = {camera_move_down, true, true},
[{"F"}] = {set_camera_default, true, true},
[{"D", "shift"}] = {camera_move_left_ignore_wall, true, true},
[{"G", "shift"}] = {camera_move_right_ignore_wall, true, true},
[{"R", "shift"}] = {camera_move_up_ignore_wall, true, true},
[{"V", "shift"}] = {camera_move_down_ignore_wall, true, true},
[{"H"}] = {read_enemy_health, true, false},
[{"H", "shift"}] = {read_player_health, true, false},
[{"0", "shift"}] = {add_hackrom_values, false, false},
}

game = nil
language = nil
data = nil
base_game = nil
old_pressed_keys = {}
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

if device == "gba" then
register_common_callbacks()
end

last_line = ""
last_textbox_text = nil
current_item = nil
camera_x = DEFAULT_CAMERA_X
camera_y = DEFAULT_CAMERA_Y
tolk.output(message.translate("ready"))
end
end

function get_device()
local id = emu.platform()
if id == 0 then
return "gba"
elseif id == 1 then
return "gb"
end

return nil
end

function get_game()
local valid = false
local game_title = memory.readbyterange(ROM_TITLE_ADDRESS, 16)
local code = ""
for i = 0, 2 do
code = code .. string.char(game_title[ROM_GAMECODE_START +i])
end
local lang = string.char(game_title[ROM_GAMECODE_START +3])
local checksum = get_game_checksum()
if codemap[code] then
game = codemap[code]
if langmap[lang] then
language = langmap[lang]
data = language
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
elseif device == "gb" and parse_old_title(game_title) then
valid = true
end
if valid then
return load_game()
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
if hacks[curgame][checksum].lang == nil then
local hack_lang = nil
repeat
hack_lang = inputbox.inputbox("Game Language", "Input the game's language", hack_lang or language or "")
if hack_lang == nil then
return false
end
until hack_lang ~= "" and contains(langmap, hack_lang)
hacks[curgame][checksum].lang = hack_lang
local file = io.open("hacks.lua", "wb")
file:write(serpent.block(hacks, {comment=false}))
io.close(file)
end
base_game = game
game = hacks[curgame][checksum].game
language = hacks[curgame][checksum].lang
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
id = id .. string.char(memory.readbyte(ROM_TITLE_ADDRES +ROM_GAMECODE_START +i))
end
elseif base_game ~= nil then
id = base_game
else
id = game
end
if hacks[id] == nil then
hacks[id] = {}
end
local checksum = get_game_checksum()
if hacks[id][checksum] == nil then
hacks[id][checksum] = {}
end
local path = scriptpath .. "game\\"
local hack_game = nil
repeat
hack_game = inputbox.inputbox("Base game folder", "Input the script base folder for this game", hack_game or hacks[id][checksum].game or game or "")
if hack_game == nil then
return
end
until hack_game ~= "" and path_exists(path .. hack_game .. "\\")
local hack_lang = nil
repeat
hack_lang = inputbox.inputbox("Game Language", "Input the game's language", hack_lang or hacks[id][checksum].lang or language or "")
if hack_lang == nil then
return
end
until hack_lang ~= "" and contains(langmap, hack_lang)
local hack_data = nil
repeat
hack_data = inputbox.inputbox("Data folder", "Input the game's Data folder", hack_data or hacks[id][checksum].data or language or "")
if hack_data == nil then
return
end
until hack_data ~= "" and path_exists(path .. hack_game .. "\\" .. hack_data .. "\\")
hacks[id][checksum].game = hack_game
hacks[id][checksum].lang = hack_lang
hacks[id][checksum].data = hack_data
local file = io.open("hacks.lua", "wb")
file:write(serpent.block(hacks, {comment=false}))
io.close(file)
init_script()
end

tolk = require "tolk"
assert(package.loadlib("audio.dll", "luaopen_audio"))()

init_script()

memory.registerexec(0x100, init_script)
memory.registerexec(0x8000000, init_script)

while true do
emu.frameadvance()
main_loop()
end
