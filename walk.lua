walk_attempts = 160
camera_xy = {}
walking_to_item = true

function walk_to_item()
	walking_to_item = true
	local path = get_path()
	if path == nil then 
		return
	end
	-- standing on destination
	if #path < 1 then
		tolk.output(message.translate("standing_on_destination"))
		return
	end
	walk_path(path)
end

function walk_to_camera()
	camera_xy = {get_camera_xy()}
	walking_to_item = false
	local x = camera_xy[1]
	local y = camera_xy[2]
	if x < 0 or y < 0 
	or x >= memory.readbyte(RAM_MAP_WIDTH)*2 or y >= memory.readbyte(RAM_MAP_HEIGHT)*2 then
		tolk.output(message.translate("not_map"))
		return
	end
	if standing_at_desination() then
		tolk.output(message.translate("camera_on_player"))
		return
	end
	local path = get_path()
	if path == nil then 
		return
	end
	walk_path(path)
end

-- Returns true or false indicating whether reached walking end
function walk_path(new_path)
	local starting_map_id = get_map_id()
	local was_facing = false
	read_on_way()
	for i = 1, walk_attempts, 1 do
		screen = get_screen()
		if not on_map() then 
			break
		end
		local path = new_path
		if path == nil or #path < 1 then
			break
		end
		-- tries to execute hm command incase standing next to an hm tile
		local impassable = execute_hm_command(path[1][1])
		if impassable then
			break
		end
		walk_direction(path[1][1])
		-- sometimes new map loads sooner than it's possible to check if arrived at destination
		-- so checking if entered a new map
		if starting_map_id ~= get_map_id() or joypad_key_pressed() then
			break
		end
		new_path = get_path()
		if reached_destination(path, new_path, was_facing) then
			break
		end
		if facing_destination(path, new_path) then
			if was_facing == false then 
				was_facing = true
			end
		end
	end -- for
	tolk.silence()
	tolk.output(message.translate("walk_end"))
end -- function

-- Checks if destination was reached. 
-- If reached item destination by facing the selected item, activates destination item
-- Returns true or false indicating whether destination was reached
function reached_destination(path, new_path, was_facing)
	if standing_at_desination() then 
		return true
	end
	if facing_destination(path, new_path) and was_facing then
		-- used to not stop, in case it's possible to arrive on destination
		if walking_to_item then
			local destination_x, destination_y = get_destination_xy()
			set_key("A", 2)
			-- waiting for npc to reach new tile, in case it's walking
			walk_wait(FRAMES_PRESS_WALK + FRAMES_WALK_FINISH)
			local new_x, new_y = get_destination_xy()
			if destination_x == new_x and destination_y == new_y then
				return true
			end -- destination
		else 
			return true
		end -- on_way_to_item
	end -- facing_destination
end -- function

-- Returns true or false indicating whether player is facing the destination
function facing_destination(path, new_path)
	if #path < 1 or new_path == nil then
		return false
	end
	local last_movement = path[1]
	local new_movement = new_path[1]
	if new_movement == nil then 
		return false
	end
	-- checks, if one movement away from destination 
	if #new_path == 1 and new_movement[2] < 2 then
		-- true, if last movement was in direction of destination
		return new_movement[1] == last_movement[1]
	end
	return false
end -- function

-- Returns true or false indicating whether player is standing at destination coordinates
function standing_at_desination()
	local destination_x, destination_y = get_destination_xy()
	local player_x, player_y = get_player_xy()
	return destination_x == player_x and destination_y == player_y
end -- function

function read_on_way()
	local destination_name
	if walking_to_item then
		local info = get_map_info()
		reset_current_item_if_needed(info)
		local map_id = get_map_id()
		destination_name = get_name(mapid, info.objects[current_item])
	else
		destination_name = message.translate("camera") 
	end
	tolk.output(message.translate("on_way_to") .. " " .. destination_name)
end -- function

-- Returns path in directional movement form as obtained from clean_path
function get_path()
	screen = get_screen()
	local path
	if not on_map() then 
		return
	end
	if walking_to_item then
		local info = get_map_info()
		reset_current_item_if_needed(info)
		local obj = info.objects[current_item]
		-- necessary in crystal, when player is walking and npc is one tile beyond the edge of screen
		-- the npc object contains wrong values
		-- such as the x  and y both being -4 
		if obj.x == -4 and obj.y == -4 then
			walk_wait(FRAMES_PRESS_WALK)
		end
		path = pathfind()
	else
		path = find_path_to_xy(camera_xy[1], camera_xy[2])
	end
	if path == nil then
		if not walking_to_item then
			tolk.output(message.translate("no_path"))
		end
	else
		path = clean_path(path)
	end
	return path
end -- function

function get_destination_xy()
	if on_map() then
		if walking_to_item then
			local info = get_map_info()
			reset_current_item_if_needed(info)
			local obj = info.objects[current_item]
			destination_x = obj.x
			destination_y = obj.y	
		else
			destination_x = camera_xy[1]
			destination_y = camera_xy[2]
		end
		return destination_x, destination_y
	end
end

-- Determines which hm command to execute. 
-- And announces the command and depending on it's type might walk in it's direction.
-- hm_command is formatted by function format_hm_command with an added direction at end
-- example. "bush on way left"
-- Returns true when hm command leads into an impassable tile
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
	walk_wait(FRAMES_WALK_FINISH)
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
		screen = get_screen()
		if on_map() == false or joypad_key_pressed() then
			return
		end
		joypad.set(1, keys)
		emu.frameadvance()
	end -- for
end -- function

function walk_direction(direction)
	set_key(direction, FRAMES_PRESS_WALK)
	if not on_map() then 
		return
	end
	walk_wait(FRAMES_WALK_FINISH)
end

function walk_wait(frames)
	for i = 1, frames, 1 do
		screen = get_screen()
		if not on_map() or joypad_key_pressed() then 
			return
		end
		emu.frameadvance()
	end -- for
end

-- returns true, if A, B, L, R, start, select or a directional button is pressed
function joypad_key_pressed()
	local keys = joypad.getdown(0)
	if next(keys) == nil then
		return false
	else
		return true
	end
end

return {
item = walk_to_item,
camera = walk_to_camera,
}
