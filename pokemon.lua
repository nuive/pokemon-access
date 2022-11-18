require "a-star"
serpent = require "serpent"
message = require "message"
controls = require "win-controls"
scriptpath = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
callback_functions = {}
langmap = {
["D"] = "de",
["E"] = "en",
["F"] = "fr",
["I"] = "it",
["S"] = "es",
}
FILTER_ALL = 1
FILTER_WARPS = 2
FILTER_CONNECTIONS = 3
FILTER_SIGNPOSTS = 4
FILTER_OBJECTS = 5

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

function list_files(path, filter, remove_extension)
local list = {}
if path_exists(path) then
local pfile = io.popen("dir /b \"" .. path .."\"")
for filename in pfile:lines() do
if not contains(filter, filename) then
if remove_extension then
local index = filename:find("%.")
if index then
table.insert(list, filename:sub(1, index -1))
else
table.insert(list, filename)
end
else
table.insert(list, filename)
end
end
end
pfile:close()
end
return list
end

function list_directories(path, filter)
local list = {}
if path_exists(path) then
local pfile = io.popen("dir /b /ad \"" .. path .."\"")
for filename in pfile:lines() do
if not contains(filter, filename) then
table.insert(list, filename)
end
end
pfile:close()
end
return list
end

function get_game_list(list)
local game_list = {}
for _, v in pairs(list) do
table.insert(game_list, message.translate(v))
end
return game_list
end

function get_game_expansions(path)
local list = {}
if path_exists(path) then
local pfile = io.popen("dir /b \"" .. path .."\"")
for filename in pfile:lines() do
local file = io.open(path .. "\\" .. filename)
local name = file:read()
table.insert(list, name:sub(4, #name))
file:close()
end
pfile:close()
end
return list
end

function load_game()
if data == nil then
tolk.output(message.translate("data_not_found"))
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
tolk.output(message.translate("data_not_found"))
return false
end
end
-- load the core script
if core_file ~= nil then
f = loadfile(scriptpath .. "game\\common\\" .. core_file .. ".lua")
if f ~= nil then
f()
else
tolk.output(message.translate("core_script_problem"))
return false
end
else
tolk.output(message.translate("core_script_missing"))
return false
end
-- load specific game script
f = loadfile(scriptpath .. "game\\" .. game .. "\\main.lua")
if f ~= nil then
f()
end
-- load possible expansions
if expansion_files ~= nil then
for _, v in pairs(expansion_files) do
f = loadfile(scriptpath .. "game\\expansion\\" .. game .. "\\" .. v .. ".lua")
if f ~= nil then
f()
else
tolk.output(message.translate("expansion_problem"))
end
end
end
return load_data()
end

function load_data()
if data == nil then
tolk.output(message.translate("data_not_found"))
return false
end
local path = scriptpath .. "game\\" .. game .. "\\" .. data .. "\\"
local t = {"maps.lua", "sprites.lua"}
local partial = false
for _, v in pairs(t) do
local f = loadfile(path .. v)
if f ~= nil then
f()
else
partial = true
tolk.output(v)
end
end
if partial then
tolk.output(message.translate("game_not_fully_supported"))
end
-- load optional core script
path = path .. "core.lua"
if path_exists(path) then
local f = loadfile(path)
if f ~= nil then
f()
else
tolk.output(message.translate("custom_core_script_problem"))
end
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
reset_current_item_filter_if_needed()
for i, warp in ipairs(get_warps()) do
table.insert(results.objects, warp)
end
for i, connection in ipairs(get_connections()) do
table.insert(results.objects, connection)
end
for i, signpost in ipairs(get_signposts()) do
table.insert(results.objects, signpost)
end
for i, object in ipairs(get_objects()) do
table.insert(results.objects, object)
end
filter_list(results.objects, current_item_filter)
return results
end

function filter_list(results, filter)
local filter_key = nil
if filter == FILTER_ALL then
return
elseif filter == FILTER_WARPS then
filter_key = "warp"
elseif filter == FILTER_CONNECTIONS then
filter_key = "connection"
elseif filter == FILTER_SIGNPOSTS then
filter_key = "signpost"
elseif filter == FILTER_OBJECTS then
filter_key = "object"
end
if filter_key then
local i = 1
while i <= #results do
if results[i].type ~= filter_key then
table.remove(results, i)
else
i = i +1
end
end
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
		elseif device == "gba" then
			camera_elevation = get_player_elevation()
		end
	end
end

function set_camera_default()
	camera_x = DEFAULT_CAMERA_X
	camera_y = DEFAULT_CAMERA_Y
end

function set_camera_to_player()
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

function find_path_to_camera()
path = find_path_to_xy(get_camera_xy())
if path == nil then
tolk.output(message.translate("no_path"))
return
end
speak_path(clean_path(path))
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

function contains(list, value)
if list == nil or value == nil then
return nil
end
if type(value) == "table" then
local index_list = {}
for _, item in pairs(value) do
for i, v in pairs(list) do
if v == item then
table.insert(index_list, i)
end
end
end
return index_list
else
for i, v in pairs(list) do
if v == value then
return i
end
end
end
return nil
end

function handle_user_actions()
local kbd = input.read()
local pressed_keys = {}
kbd.xmouse = nil
kbd.ymouse = nil
for k, v in pairs(kbd) do
if v and k ~= "capslock" and k ~= "numlock" and k ~= "scrolllock" then
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
tolk.output(message.translate("script_not_loaded"))
end -- data check
end

function read_current_item()
local info = get_map_info()
reset_current_item_if_needed(info)
if info.objects[current_item] ~= nil then
read_item(info.objects[current_item])
else
tolk.output(message.translate("empty_list"))
end
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

function read_current_item_filter()
reset_current_item_filter_if_needed()
local filter = ""
if current_item_filter == FILTER_ALL then
filter = message.translate("all")
elseif current_item_filter == FILTER_WARPS then
filter = message.translate("warps")
elseif current_item_filter == FILTER_CONNECTIONS then
filter = message.translate("connections")
elseif current_item_filter == FILTER_SIGNPOSTS then
filter = message.translate("signposts")
elseif current_item_filter == FILTER_OBJECTS then
filter = message.translate("objects")
end
if filter ~= "" then
tolk.output(filter)
current_item = 1
read_current_item()
end
end

function reset_current_item_filter_if_needed()
if current_item_filter == nil then
current_item_filter = FILTER_ALL
end
end

function read_next_item_filter()
reset_current_item_filter_if_needed()
current_item_filter = current_item_filter +1
if current_item_filter > FILTER_OBJECTS then
current_item_filter = FILTER_ALL
end
read_current_item_filter()
end

function read_previous_item_filter()
reset_current_item_filter_if_needed()
current_item_filter = current_item_filter -1
if current_item_filter == 0 then
current_item_filter = FILTER_OBJECTS
end
read_current_item_filter()
end

function set_camera_follow()
if not camera_follow_player then
camera_follow_player = true
tolk.output(message.translate("camera_follow_player"))
else
camera_follow_player = false
tolk.output(message.translate("camera_not_follow_player"))
end
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
if info.objects[current_item] ~= nil then
local obj = info.objects[current_item]
find_path_to(obj)
else
tolk.output(message.translate("object_needed"))
end
end

function advance_pathfinder_counter()
if max_paths > 0 then
path_counter = path_counter +1
if path_counter % (max_paths *1000) == 0 then
emu.frameadvance()
if search_message_repeat > 0
and (path_counter == max_paths *5000 or path_counter % (max_paths *100000 *search_message_repeat) == 0) then
tolk.output(message.translate("searching"))
end
end
end
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
command, count = get_hm_command(node, last)
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
name = controls.inputbox(message.translate("new_name"), string.format(message.translate("enter_newname"), info.objects[current_item].name), info.objects[current_item].name)
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
name = controls.inputbox(message.translate("new_name"), string.format(message.translate("enter_newname"), mapname), mapname)
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
core_file = nil
expansion_files = nil
for _,cb_function  in pairs(callback_functions) do
memory.registerexec(cb_function, nil)
end
callback_functions = {}
device = get_device()
loadfile(scriptpath .. device .. ".lua")()
commands = {
[{"Y"}] = {read_coords, true, true};
[{"Y", "shift"}] = {read_camera, true, true};
[{"J"}] = {read_previous_item, true, true};
[{"K"}] = {read_current_item, true, true};
[{"L"}] = {read_next_item, true, true};
[{"J", "shift"}] = {read_previous_item_filter, true, true};
[{"L", "shift"}] = {read_next_item_filter, true, true};
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
[{"F"}] = {set_camera_to_player, true, true},
[{"D", "shift"}] = {camera_move_left_ignore_wall, true, true},
[{"G", "shift"}] = {camera_move_right_ignore_wall, true, true},
[{"R", "shift"}] = {camera_move_up_ignore_wall, true, true},
[{"V", "shift"}] = {camera_move_down_ignore_wall, true, true},
[{"F", "shift"}] = {find_path_to_camera, true, true};
[{"C"}] = {set_camera_follow, true, true};
[{"H"}] = {read_enemy_health, true, false},
[{"H", "shift"}] = {read_player_health, true, false},
[{"0", "shift"}] = {add_hackrom_values, false, false},
}

game = nil
game_checksum = nil
language = nil
data = nil
base_game = nil
old_pressed_keys = {}
chars = {}
fonts = {}
maps = {}
sprites = {}
default_language = "en"
pathfind_hm_available = false
pathfind_hm_all = false
camera_follow_player = true
max_paths = 100
search_message_repeat = 2

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
current_item_filter = nil
camera_x = DEFAULT_CAMERA_X
camera_y = DEFAULT_CAMERA_Y
path_counter = 0
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

function is_game(game)
if core_file == game then
return true
end
return false
end

function get_game()
local valid = false
local game_title = memory.readbyterange(ROM_TITLE_ADDRESS, 16)
local code = ""
for i = 1, 3 do
code = code .. string.char(game_title[ROM_GAMECODE_START +i])
end
local lang = string.char(game_title[ROM_GAMECODE_START +4])
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
tolk.output(message.translate("data_not_found"))
return false
end
elseif set_hackrom_values(checksum, code .. lang) then
valid = true
elseif device == "gb" and parse_old_title(game_title, checksum) then
valid = true
end
if valid then
game_checksum = checksum
message.set_strings(language)
return load_game()
end
tolk.output(message.translate("game_not_supported"))
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
list = list_files(scriptpath .. "message", nil, true)
index = controls.combobox(message.translate("game_language"), message.translate("select_game_language"), list, contains(list, hack_lang or hacks[id][game_checksum].lang or language))
if index == nil then
return
end
hack_lang = list[index]
hacks[curgame][checksum].lang = hack_lang
local file = io.open("hacks.lua", "wb")
file:write(serpent.block(hacks, {comment=false}))
io.close(file)
end
base_game = game
game = hacks[curgame][checksum].game
expansion_files = hacks[curgame][checksum].expansions
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
id = id .. string.char(memory.readbyte(ROM_TITLE_ADDRESS +ROM_GAMECODE_START +i))
end
elseif base_game ~= nil then
id = base_game
else
id = game
end
if hacks[id] == nil then
hacks[id] = {}
end
if hacks[id][game_checksum] == nil then
hacks[id][game_checksum] = {}
end
local path = scriptpath .. "game\\"
local list = list_directories(path, {"common", "expansion"})
local hack_game = nil
local index = controls.combobox(message.translate("base_game"), message.translate("select_base_game"), get_game_list(list), contains(list, hack_game or hacks[id][game_checksum].game or game))
if index == nil then
return
end
hack_game = list[index]
local hack_expansions = nil
if path_exists(path .. "expansion\\" .. hack_game) then
list = list_files(path .. "expansion\\" .. hack_game, nil, true)
local expansions = controls.combobox(message.translate("game_expansions"), message.translate("select_game_expansions"), get_game_expansions(path .. "expansion\\" .. hack_game), contains(list, hacks[id][game_checksum].expansions) or {})
if expansions == nil then
return
end
hack_expansions = {}
for _, v in pairs(expansions) do
table.insert(hack_expansions, list[v])
end
end
local hack_data = nil
list = list_directories(path .. hack_game)
index = controls.combobox(message.translate("data_folder"), message.translate("select_data_folder"), list, contains(list, hack_data or hacks[id][game_checksum].data or language))
if index == nil then
return
end
hack_data = list[index]
local hack_lang = nil
list = list_files(scriptpath .. "message", nil, true)
index = controls.combobox(message.translate("game_language"), message.translate("select_game_language"), list, contains(list, hack_lang or hacks[id][game_checksum].lang or language))
if index == nil then
return
end
hack_lang = list[index]
hacks[id][game_checksum].game = hack_game
hacks[id][game_checksum].expansions = hack_expansions
hacks[id][game_checksum].lang = hack_lang
hacks[id][game_checksum].data = hack_data
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
