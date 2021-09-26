walk_attempts = 6

function walk_to_item()
	walk()
end

function walk_to_camera()
	local camera_xy = {get_camera_xy()}
	local x = camera_xy[1]
	local y = camera_xy[2]
	if x < 0 or y < 0 
	or x >= memory.readbyte(RAM_MAP_WIDTH)*2 or y >= memory.readbyte(RAM_MAP_HEIGHT)*2 then
		tolk.output(message.translate("not_map"))
		return
	end
	walk(camera_xy)
end

function walk(camera_xy)
	local old_path = {}
	local starting_map_id = get_map_id()
	local new_path
	local path
	for i = 1, walk_attempts, 1 do
		if starting_map_id ~= get_map_id() then 
			tolk.output(message.translate("end"))
			return
		end
		if new_path == nil then
			path = get_path(camera_xy)
		else 
			path = new_path
		end
		if path == nil then
			return
		end
		if #path < 1 then -- arrived or was standing at destination
			tolk.output(message.translate("end"))
			return
		end
		local on_way_to_item = camera_xy == nil
		read_on_way(on_way_to_item)
		local walk_complete = walk_path(path, camera_xy) 
		new_path = get_path(camera_xy)
		local at_destination = reached_destination(camera_xy) and facing_destination(path, new_path)
		walk_complete = walk_complete or at_destination
		if walk_complete then
			if on_way_to_item then
				set_key("A", 2)
			end -- on_way_to_item
			break
		end -- walk_complete
	end -- for
	tolk.output(message.translate("end"))
end -- function

function facing_destination(path, new_path)
	if #path < 1 then
		return false
	end
	local last_movement = path[#path]
	local new_movement = new_path[1]
	if new_movement == nil then 
		return true
	end
	return new_movement[1] == last_movement[1] 
end -- function

-- Returns true if standing on or next to destination
function reached_destination(camera_xy)
	local destination_x
	local destination_y
	local on_way_to_item = camera_xy == nil
	if on_way_to_item then
		local info = get_map_info()
		reset_current_item_if_needed(info)
		local obj = info.objects[current_item]
		destination_x = obj.x
		destination_y = obj.y
	else
		destination_x = camera_xy[1]
		destination_y = camera_xy[2]
	end -- if
	local player_x, player_y = get_player_xy()
	return destination_x == x and destination_y == y 
		or destination_x == player_x - 1 and destination_y == player_y
		or destination_x == player_x + 1 and destination_y == player_y
		or destination_x == player_x and destination_y == player_y - 1
		or destination_x == player_x and destination_y == player_y + 1
end -- function

-- Returns true if reached walking end
function walk_path(path, camera_xy)
	-- tries to execute hm command incase standing next to an hm tile
	local impassable = execute_hm_command(path[1][1])
	if impassable then 
		return true
	end
	-- walk once, so player has enough frames to turn from standing position
	walk_direction(path[1][1])
	path = get_path(camera_xy)
	if path == nil or #path < 1 then 
		return true
	end
	for _, v in ipairs(path) do
		local old_player_x, old_player_y = get_player_xy()
		-- tries to execute hm command incase standing next to an hm tile
		impassable = execute_hm_command(v[1])
		if impassable then 
			return true
		end
		local times = v[2]
		screen = get_screen()
		while times > 0 and on_map() do
			walk_direction(v[1])
			times = times - 1
		end -- while
		local current_player_x, current_player_y = get_player_xy()
		local same_player_xy = (old_player_x == current_player_x and old_player_y == current_player_y)
		if same_player_xy then
			break
		end
	end -- for
	return false
end -- function

function read_on_way(on_way_to_item)
	if on_way_to_item then
		local info = get_map_info()
		reset_current_item_if_needed(info)
		local map_id = get_map_id()
		local name = get_name(mapid, info.objects[current_item])
		tolk.output(message.translate("on_way") .. name)
	else
		tolk.output(message.translate("on_way"))
	end
end -- function

-- Returns path run through clean_path function
function get_path(camera_xy)
	screen = get_screen()
	local path
	if not on_map() then 
		return
	end
	local on_way_to_item = camera_xy == nil
	if on_way_to_item then
		path = pathfind()
	else
		path = find_path_to_xy(camera_xy[1], camera_xy[2])
	end
	if path == nil then
		if camera_xy then
			tolk.output(message.translate("no_path"))
		end
	else
		path = clean_path(path)
	end
	return path
end -- function

-- Executes hm command. Returns true when leads into an impassable tile
-- hm_command is formatted by function format_hm_command with an added direction at end
-- example. bush on way left
function execute_hm_command(hm_command)
	if hm_command == nil then
		return false
	end
	local message_bush = message.translate("bush")
	local message_whirlpool = message.translate("whirlpool")
	local message_waterfall = message.translate("waterfall")
	local message_enter_water = message.translate("enter_water")
	local message_exit_water = message.translate("exit_water")
	--  gets beggining from hm_command of each message's length
	--	then compares the result to the message itself
	if string.sub(hm_command, 1, #message_bush) == message_bush then 
		walk_hm(hm_command, message_bush)
		tolk.silence()
		tolk.output(hm_command)
		return true
	elseif string.sub(hm_command, 1, #message_whirlpool) == message_whirlpool then
		walk_hm(hm_command, message_whirlpool)
		tolk.silence()
		tolk.output(hm_command)
		return true
	elseif string.sub(hm_command, 1, #message_waterfall) == message_waterfall then 
		if get_hm_direction(hm_command, message_waterfall) == message.translate("down") then
			walk_hm(hm_command, message_waterfall)
		end
		tolk.silence()
		tolk.output(hm_command)
		return true
	elseif string.sub(hm_command, 1, #message_enter_water) == message_enter_water then
		walk_hm(hm_command, message_enter_water)
		tolk.silence()
		tolk.output(hm_command)
		return true
	elseif string.sub(hm_command, 1, #message_exit_water) == message_exit_water then
		walk_hm(hm_command, message_exit_water)
		tolk.silence()
		tolk.output(message_exit_water)
		return false
	end -- if
end -- function

-- Gets direction from hm command and walks in it
function walk_hm(hm_command, command)
	local direction = get_hm_direction(hm_command, command)
	walk_direction(direction)
	walk_finish()
end

function get_hm_direction(hm_command, command)
	local command_beginning = format_hm_command(command) .. " "
	return string.sub(hm_command, #command_beginning, #hm_command)
end

function set_key(key, frames)
	local keys = {}
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
		end -- if
		joypad.set(1, keys)
		emu.frameadvance()
	end -- for
end -- function

function walk_direction(direction)
	set_key(direction, FRAMES_PRESS_WALK)
	walk_finish()
end

-- Advances frames till walk is finished
function walk_finish()
	if on_bike_gsc() then
		for i = 1, 4, 1 do
			emu.frameadvance()
		end -- for
	elseif FRAMES_WALK_FINISH > 0 then
		for i = 1, FRAMES_WALK_FINISH, 1 do
			emu.frameadvance()
		end -- for
	end
end -- function

function on_bike_gsc() -- For gsc only. Because rby doesn't have a unique number for bike sprite 
	local ptr = RAM_MAP_OBJECTS 
	local sprite = memory.readbyte(ptr+0x01)
	return sprite == 0x02 or sprite == 0x61
end

return {
item = walk_to_item,
camera = walk_to_camera,
}
