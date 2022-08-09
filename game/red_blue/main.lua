MAX_TILESETS = 24
BOULDER_SPRITE = 0x3f

function is_water_tile(tile)
local tileset = memory.readbyte(RAM_MAP_HEADER)
for _, v in ipairs(water_tilesets) do
if tileset == v then
local tile_start = 1
if tileset == 0x0e then
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

water_tiles = {0x48, 0x32, 0x14}

get_warp_tiles()
