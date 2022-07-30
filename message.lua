strings = nil

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
