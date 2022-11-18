-- Sideway Stairs

function is_sideway_stair(node, x, y)
local base = SIDEWAY_STAIR_BASE or 0xB0
if node.type < base or node.type > base +5 then
return false
end

local block = nil
if y == 0 then
if x == 1 then
if node.type == base
or node.type == base +2 then
block = get_map_block(node.x +1, node.y +1)
elseif node.type == base +3
or node.type == base +4 then
block = get_map_block(node.x +1, node.y -1)
end
elseif x == -1 then
if node.type == base
or node.type == base +1 then
block = get_map_block(node.x -1, node.y -1)
elseif node.type == base +3
or node.type == base +5 then
block = get_map_block(node.x -1, node.y +1)
end
end
end

if block then
if not is_collision(false, node, {impassable=get_block_impassable(block), type=get_block_type(block), elevation=get_block_elevation(block)}) then
return true
end
end
return false
end

function valid_path(node, neighbor)
advance_pathfinder_counter()
for dir = DOWN, RIGHT do
local dir_x, dir_y = decode_direction(dir)
dir_x = dir_x + dir_x
dir_y = dir_y + dir_y
if (neighbor.x == node.x + dir_x and neighbor.y == node.y + dir_y)
and ((has_talking_over_around(node.special_tiles, dir) and neighbor.is_dest)) then
return true
end
end
if astar.dist_between(node, neighbor) == 1 and neighbor.is_dest then
return true
elseif check_wall(node.type, neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return false
elseif jump_ledge(node.type, neighbor.x - node.x, neighbor.y - node.y)
or jump_ledge(neighbor.type, neighbor.x - node.x, neighbor.y - node.y) then
return true
elseif astar.dist_between(node, neighbor) ~= 1 then
return false
elseif is_collision(false, node, neighbor) then
if is_sideway_stair(node, neighbor.x - node.x, neighbor.y - node.y)
or is_sideway_stair(neighbor, neighbor.x - node.x, neighbor.y - node.y) then
return true
end
return false
end
return true
end

