function walk_pathfind()
	local old_path = {}
	local repeat_count = 4
	local starting_map_id = get_map_id()
	for i = 1, repeat_count, 1 do
		screen = get_screen()
		if not on_map() or starting_map_id ~= get_map_id() then 
			return
		end
		local path = pathfind()
		if path == nil or #path <= 1 then
			return
		end
		path = clean_path(path)
		local old_player_x, old_player_y = get_player_xy()
		local walk_complete = walk_path(path) 
		local current_player_x, current_player_y = get_player_xy()
		local same_player_xy = (old_player_x == current_player_x and old_player_y == current_player_y)
		local same_movement = is_movement_repeated(old_path, path)
		local walk_complete = walk_complete or (same_player_xy and same_movement) 
		if walk_complete then
			set_key("A", 2)
			return
		end
		old_path = path
	end
end

function is_movement_repeated(old_path, path)
	if #old_path < 1 then
		return false
	end
	local last_movement = old_path[#old_path]
	local new_movement = path[1]
	if new_movement == nil then 
		return true
	end
	return new_movement[1] == last_movement[1] 
		and new_movement[2] == last_movement[2]
		and #path == #old_path
end
	
function walk_path(path)
	if command_requires_hm(path[1][1]) then 
		return true
	end 
	if TURNING_REQUIRES_EXTRA_ACTION then
		walk_set_key(path[1][1])
		path = pathfind()
		if path == nil then 
			return true
		end
		path = clean_path(path)
	end
	for _, v in ipairs(path) do
		local old_player_x, old_player_y = get_player_xy()
		if command_requires_hm(v[1]) then 
			return true
		end
		local times = v[2]
		screen = get_screen()
		while times > 0 and on_map() do
			walk_set_key(v[1])
			times = times - 1
		end	
		local current_player_x, current_player_y = get_player_xy()
		local same_player_xy = (old_player_x == current_player_x and old_player_y == current_player_y)
		if same_player_xy then
			break
		end
	end
	return false
end

function command_requires_hm(command)
	if command == nil then
		return false
	end
	local command_bush = message.translate("bush")
	local command_whirlpool = message.translate("whirlpool")
	local command_waterfall = message.translate("waterfall")
	local command_enter_water = message.translate("enter_water")
	local command_exit_water = message.translate("exit_water")
	if string.sub(command, 1, #command_bush) == command_bush then 
		command_walk_direction(command, command_bush)
		tolk.output(command)
		return true
	elseif string.sub(command, 1, #command_whirlpool) == command_whirlpool then
		command_walk_direction(command, command_whirlpool)
		tolk.output(command)
		return true
	elseif string.sub(command, 1, #command_waterfall) == command_waterfall then 
		command_walk_direction(command, command_waterfall)
		tolk.output(command)
		return true
	elseif string.sub(command, 1, #command_enter_water) == command_enter_water then
		command_walk_direction(command, command_enter_water)
		tolk.output(command)
		return true
	elseif string.sub(command, 1, #command_exit_water) == command_exit_water then
		command_walk_direction(command, command_exit_water)
		tolk.output(command)
		return false
	end
end

function command_walk_direction(command, command_name)
	local command_up_to_direction = format_command_hm(command_name) .. " "
	local walk_direction = string.sub(command, #command_up_to_direction, #command)
	walk_set_key(walk_direction)	
end

function set_key(key, frames)
	local keys = joypad.get(1)
	for i = 1, frames, 1 do
		if key == message.translate("up") then
			keys.up = true
		elseif key == message.translate("left") then
			keys.left = true
		elseif key == message.translate("right") then
			keys.right = true
		elseif key == message.translate("down") then
			keys.down = true
		elseif key == "A" then
			keys.A = true
		end
		joypad.set(1, keys)
		emu.frameadvance()
	end
end

function walk_set_key(walk_direction)
	set_key(walk_direction, FRAMES_TURN_WALK)
	if FRAMES_WALK_FINISH > 0 then
		for i = 1, FRAMES_WALK_FINISH, 1 do
			emu.frameadvance()
		end
	end	
end

return {
pathfind = walk_pathfind,
}
