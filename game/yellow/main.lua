MAX_TILESETS = 25
BOULDER_SPRITE = 0x49

function is_water_tile(tile)
local tileset = memory.readbyte(RAM_MAP_HEADER)
for _, v in ipairs(water_tilesets) do
if tileset == v then
local tile_start = 1
if tileset == 0x05 or tileset == 0x07 or tileset == 0x0e then
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

water_tiles = get_rom_table(ROM_WATER_TILESETS + 10, 1)

get_warp_tiles()
