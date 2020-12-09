strings = nil
default_strings = {
["warp"] = "Warp",
["signpost"] = "Signpost",
["object"] = "Object",
["pc"] = "PC",
["connection_to"] = "%1 connection",
["north"] = "North",
["south"] = "South",
["east"] = "East",
["west"] = "West",
["map"] = "Map",
["up"] = "Up",
["down"] = "Down",
["left"] = "Left",
["right"] = "Right",
["now_on"] = "Now on",
["not_map"] = "Not on a map.",
["facing"] = "Facing",
["no_path"] = "No path",
["new_name"] = "New name",
["enter_newname"] = "Enter a new name for",
["names_saved"] = "Names saved.",
["no_bar"] = "No bar found.",
["unknown"] = "Unknown",
["end"] = "End",
["enemy_health"] = "Enemy health",
["ready"] = "Ready",
["trashcan"] = "Trash Can",
["use_hm"] = "Use HMs",
["not_use_hm"] = "Do not use HMs",
["bush"] = "Bush",
["on_way"] = "on way",
["closed_door"] = "Closed Door",
["enter_water"] = "Enter in water",
["exit_water"] = "Exit from water",
["statue"] = "Statue",
["cliff"] = "Cliff",
["quiz"] = "Quiz",
["bookshelf"] = "Bookshelf",
["radio"] = "Radio",
["martshelf"] = "Mart Shelf",
["tv"] = "TV",
["window"] = "Window",
["incense_burner"] = "Incense Burner",
["tree"] = "Tree",
["whirlpool"] = "Whirlpool",
["waterfall"] = "Waterfall",
["unown_puzzle_tip"] = "Sort the numbers. Leave a zero-border around them. Press Start to cancel.",
["unown_puzzle_pick_piece"] = "You have to pick a piece first.",
}

function init(lang)
local f = loadfile(scriptpath .. "\\message\\" .. lang .. ".lua")
if f ~= nil then
f()
end
end

function translate(id, ...)
local message = ""
if strings ~= nil and strings[id] ~= nil then
message = strings[id]
elseif default_strings ~= nil and default_strings[id] ~= nil then
message = default_strings[id]
else
message = id
end
for i = 1, select("#", ...) do
message = string.gsub(message, "%%" .. i, select(i, ...))
end
return message
end

return {
translate = translate,
set_strings = init
}
