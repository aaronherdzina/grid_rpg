extends Node2D

var wall_spawn_chance = 9
var text_x_buffer = -1150
var text_y_buffer = 700
var test_lvl = {
	"cols": 6,
	"rows": 8,
	
	"tile_list": ["forest", "forest", "enemy spawn", "forest", "move", "move", "enemy spawn", "move",
				"forest", "forest", "forest", "forest", "move", "move", "move", "wall",
				"forest", "enemy spawn", "forest path", "move", "move", "forest", "move", "move",
				"forest", "forest", "forest", "move", "enemy spawn", "move", "move", "move",
				"forest", "move", "forest", "forest", "move", "wall", "wall", "move",
				"forest", "player spawn", "move", "move", "move", "move", "move", "move"]
	}

var random_lvl = {
	"cols": 0,
	"rows": 0,
	"turns": 10,
	"tile_list": []
	}

var process_displays = true
var random_turns = 4
var current_turn = 0
var lvl_turns = 10
var max_lvl_cols = 28
var min_lvl_cols = 6

var min_lvl_turns = 3
var max_lvl_turns = 5

var max_lvl_rows = 24
var min_lvl_rows = 4
# debug for pathfinding tests

var path_end_tile = null
###

var starting_tile = null
var level_tiles = []
var top_tiles = []
var bottom_tiles = []
var left_tiles = []
var right_tiles = []
var round_turns = []
var round_turn_icons = []
var tile_gap = 110
var far_tile_gap_setting = 130
var far_gap_tile_outline_size = 1.012
var close_tile_gap_setting = 125
var close_gap_tile_outline_size = 1.01
var enms = 5
var level_astar = null
var current_enm_count = 0
var processing_turns = false
var spawn_types_display_speed = .01
var current_cols = 0
var current_rows = 0
var mouse_cam_range = 3 
# Called when the node enters the scene tree for the first time.


#func _ready():
	#pass


"""
 Because we'll have a camera have a setting for tile gap 104 and tile gap 150 for visual
"""
func remove_tiles():
	for t in level_tiles:
		if main.checkIfNodeDeleted(t) == false:
			t.queue_free()
	for tile in get_tree().get_nodes_in_group("tiles"):
		if main.checkIfNodeDeleted(tile) == false:
			tile.queue_free()
	level_tiles = []


func set_full_level(lvl_obj):
	lvl_obj["cols"] = max_lvl_cols
	lvl_obj["rows"] = max_lvl_rows
	var tile_count  = lvl_obj["cols"] * lvl_obj["rows"]
	for i in range(0, tile_count):
		lvl_obj["tile_list"].append("wall")


func remove_icons():
	for icon in round_turn_icons:
		if icon and main.checkIfNodeDeleted(icon) == false:
			icon.queue_free()


func spawn_premade_tiles(lvl_obj, overwrite_details=true, preset_course=false):
	randomize()
	""" lvl_obj example:
	lvl_obj = {
		tile_list = [],
		cols = 7,
		rows = 6
	}
	"""
	var col = lvl_obj["cols"]
	var row = lvl_obj["rows"]
	var tiles = lvl_obj["tile_list"]
	current_rows = row
	current_cols = col
	#if not starting_tile:
	#	starting_tile = get_node("starting_tile")

	var tile_index = -1

	level_astar = AStar2D.new()
	#var res = astar.get_id_path(1, 3) # Returns [1, 2, 3]
	#tile_gap = close_tile_gap_setting if rand_range(0, 1) >= .5 else far_tile_gap_setting

	var shadow_noise_x = 0
	var shadow_noise_y = 0
	var shadow_noise_vel = 1.2
	var shadow_max_x = 12
	var shadow_max_y = 12
	for c in range(0, col):
		for r in range(0, row):
			var t = main.TILE.instance()
			var tile_info = ""
			tile_index += 1
			get_node("tile_container").add_child(t)
			t.row = r
			t.col = c
			t.map_tile_type("water")
			level_tiles.append(t)
			t.index = tile_index
			shadow_noise_x += rand_range(-shadow_noise_vel, shadow_noise_vel)
			shadow_noise_y += rand_range(-shadow_noise_vel, shadow_noise_vel)

			if shadow_noise_x > shadow_max_x:
				shadow_noise_x = shadow_max_x
			if shadow_noise_x < -shadow_max_x:
				shadow_max_x = -shadow_max_x

			if shadow_noise_y > shadow_max_y:
				shadow_noise_y = shadow_max_y
			if shadow_noise_y < -shadow_max_y:
				shadow_noise_y = -shadow_max_y
			#t.z_index = t.index - 100
			# print('Vector2(shadow_noise_x, shadow_noise_y) ' + str(Vector2(shadow_noise_x, shadow_noise_y)))
			t.get_node("shadow").position = Vector2(shadow_noise_x, shadow_noise_y)
			if main.debug: tile_info += " |index " + str(tile_index)

			if not starting_tile:
				starting_tile = t
				t.position = Vector2(0, 0)
			else:
				t.position = Vector2(starting_tile.global_position.x -\
									(r * (-tile_gap)),\
									(starting_tile.global_position.y +\
									(c * (tile_gap))))
				#t.position.y += tile_gap * 6
				#t.position.x += tile_gap + 700
			if main.debug: 
				tile_info += " |row/col " + str(r) + '/' + str(c) + "\ntile_gap: " + str(tile_gap * r)
				t.get_node("debug_info").visible = true
				t.get_node("debug_info").set_text(tile_info)
			if get_node("/root").has_node("camera"):
				get_node("/root/camera").position = t.global_position
		if tile_index % 75 == 0:
			var timer = Timer.new()
			timer.set_wait_time((len(level_tiles)*.02) * spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()

	

	var timer = Timer.new()
	timer.set_wait_time((len(level_tiles)*.02) * spawn_types_display_speed)
	timer.set_one_shot(true)
	get_node("/root").add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()

	set_points(level_astar, level_tiles)
	set_tile_neighbors(row, col)
	if not overwrite_details and preset_course:
		var timer1 = Timer.new()
		timer1.set_wait_time((len(level_tiles)*.01) * spawn_types_display_speed)
		timer1.set_one_shot(true)
		get_node("/root").add_child(timer1)
		timer1.start()
		yield(timer1, "timeout")
		timer1.queue_free()
		map_tiles(null, preset_course)
	else:
		map_tiles(lvl_obj)
		var timer1 = Timer.new()
		timer1.set_wait_time((len(level_tiles)*.01) * spawn_types_display_speed)
		timer1.set_one_shot(true)
		get_node("/root").add_child(timer1)
		timer1.start()
		yield(timer1, "timeout")
		timer1.queue_free()
		set_borders(lvl_obj)

	#var timer15 = Timer.new()
	#timer15.set_wait_time((len(level_tiles)*.01) * spawn_types_display_speed)
	#timer15.set_one_shot(true)
	#get_node("/root").add_child(timer15)
	#timer15.start()
	#yield(timer15, "timeout")
	#timer15.queue_free()

	for t in level_tiles:
		t.set_tile_neighbor_nodes(level_tiles)
	reset_level_vals()
	spawn_player()
	meta.spawn_enemies()
	
	meta.set_turn_order_info()



func reset_level_vals():
	meta.can_spawn_level = true
	main.current_screen = 'battle'


func randomize_level(lvl_obj):
	randomize()
	random_turns = floor(rand_range(min_lvl_turns, max_lvl_turns))
	var min_tiles_needed = 20
	lvl_obj["tiles_list"] = []
	var map_size_mod = .5
	var max_col = min_tiles_needed+(max_lvl_cols * map_size_mod)
	var max_row = min_tiles_needed+(max_lvl_rows * map_size_mod)
	lvl_obj["cols"] =  floor(rand_range(min_tiles_needed, max_col))
	lvl_obj["rows"] = floor(rand_range(min_tiles_needed, max_row))
	lvl_obj["turns"] = random_turns
	var tile_count = lvl_obj["cols"] * lvl_obj["rows"]
	var player_spawn_set = false
	enms = 2 + round(tile_count * .01)
	map_tiles(lvl_obj)
	var tile_type_set = [meta.DIRT_TYPE, meta.DIRT_TYPE, meta.DIRT_TYPE,\
						#meta.WATER_TYPE, meta.WATER_TYPE, meta.WATER_TYPE,
						#meta.EMPTY_TYPE, 
						meta.GRASS_TYPE,meta.GRASS_TYPE, meta.GRASS_TYPE, meta.GRASS_TYPE, meta.GRASS_TYPE]

	for t in level_tiles:
		var random_tile_type = tile_type_set[rand_range(0, len(tile_type_set))]
		if t.row <= lvl_obj["rows"] - 1  and t.col <= lvl_obj["cols"] - 1 and\
			t.row > 1 and t.col > 1:
			t.current = true
			t.map_tile_type(random_tile_type)
			if rand_range(0, 1) >= .999:
				t.spawn_enemies = true
			elif rand_range(0, 1) >= .9987 and not player_spawn_set:
				player_spawn_set = true
				t.spawn_player = true
		else:
			t.map_tile_type(meta.EMPTY_TYPE)
			t.current = false

	for t in level_tiles:
		t.map_tile_type_by_neighbors(false, false, false, true)

	var randomly_set_water = true
	if randomly_set_water:
		if rand_range(0, 1) >= .3:
			set_bodies_of_water(lvl_obj)
	else:
		set_bodies_of_water(lvl_obj)
	#for t in level_tiles:
		#if t.col == 2 and t.index < len(level_tiles) * .7:
	var t = level_tiles[rand_range(2, 15)]

	var randomly_set_paths = true
	if randomly_set_paths:
		if rand_range(0, 1) >= .3:
			var random_type = meta.BASIC_TYPE[floor(rand_range(0, len(meta.BASIC_TYPE)))]
			var paths = floor(rand_range(2, 4))
			var width = floor(rand_range(0, 2))
					
			for p in paths:
				var spot_start = level_tiles[rand_range(0, len(level_tiles))]
				var end_start = level_tiles[rand_range(0, len(level_tiles))]
				if p == paths - 1:
					if get_node("/root").has_node("player"):
						var player = get_node("/root/player")
						spot_start = player.current_tile
				for tile in level_tiles:
					if tile.spawn_enemies:
						end_start = tile
						break
				meta.set_tiles_in_path(spot_start, end_start, random_type, width)
	
	else:
		var random_type = meta.BASIC_TYPE[floor(rand_range(0, len(meta.BASIC_TYPE)))]
		meta.set_tiles_in_path(level_tiles[t.index], level_tiles[len(level_tiles) - int(t.index * .80)], random_type)


	var timer14 = Timer.new()
	timer14.set_wait_time((len(level_tiles)*.01) * spawn_types_display_speed)
	timer14.set_one_shot(true)
	get_node("/root").add_child(timer14)
	timer14.start()
	yield(timer14, "timeout")
	timer14.queue_free()

	reset_level_vals()
	spawn_player()


	for t in level_tiles:
		meta.helpers_set_edge_tiles(t)
		if t.tile_type == meta.WATER_TYPE:
			pass
			#t.get_node("AnimationPlayer").play("water anim")


func set_random_level(lvl_obj):
	randomize()
	lvl_obj["cols"] = max_lvl_cols#floor(rand_range(min_lvl_cols, max_lvl_cols))
	lvl_obj["rows"] = floor(rand_range(min_lvl_rows, max_lvl_rows))
	
	var tile_count  = lvl_obj["cols"] * lvl_obj["rows"]
	var tile_types = []
	var water_chance = .25
	var forest_path_chance = .14
# warning-ignore:unused_variable
	var wall_chance = .4
	var wall_limit = tile_count * .25
	var player_spawned = false
	var enemy_spawns = 3 + (tile_count * .015)
	
# warning-ignore:unused_variable
	for _i in range(0, tile_count * water_chance):
		tile_types.append("water")
# warning-ignore:unused_variable
	for _i  in range(0, tile_count * forest_path_chance):
		wall_limit -= 1
		tile_types.append("forest path")
		if wall_limit <= 0:
			break
# warning-ignore:unused_variable
	for _i in range(0, enemy_spawns + 1):
		enemy_spawns -= 1
		tile_types.append("enemy spawn")
		if enemy_spawns <= 0:
			break
	
	var left_over_tiles = tile_count - len(tile_types) - 1
	if left_over_tiles > 0:
		for i in range(0, left_over_tiles):
			tile_types.append("move")

	# TODO FIX PLAYER SPAWN
	for i in range(0, tile_count):
		if not player_spawned:
			if i > 0 and i < len(lvl_obj["tile_list"]) - 1:
				if i <= tile_count * .95 and i >= tile_count * .05 and not "enemy spawn" in lvl_obj["tile_list"][i]:
					player_spawned = true
					lvl_obj["tile_list"].append("player spawn")
				else:
					lvl_obj["tile_list"].append(tile_types[rand_range(0, len(tile_types) - 1)])
			else:
				lvl_obj["tile_list"].append(tile_types[rand_range(0, len(tile_types) - 1)])
		else:
			lvl_obj["tile_list"].append(tile_types[rand_range(0, len(tile_types) - 1)])


func set_points(astar_path_obj, list, tile_weight=meta.unccupied_tile_weight):
	for t in list:
		astar_path_obj.add_point(t.index, t.global_position, tile_weight)


func set_bodies_of_water(lvl_obj, bodies=0):
	randomize()
	var used_indexes = []
	var row_edge_buffer = 2
	var col_edge_buffer = 2
	var grouping_buffer = 3
	var grouping_buffer_default = 15
	if bodies <= 0:
		bodies = floor(rand_range(2, 11))
	for body in range(0, bodies):
		var body_set = false
		for t in level_tiles:
			if body_set:
				break
			if t.row <= lvl_obj["rows"] and t.col <= lvl_obj["cols"]\
			   and t.row > row_edge_buffer and t.col > col_edge_buffer\
			   and t.index % 3 == 0:
				if grouping_buffer <= 0:
					grouping_buffer = grouping_buffer_default
					var body_size = rand_range(0, 4)
					var body_of_water = meta.get_adjacent_tiles_in_distance(t, body_size)
					var already_set = false
					
					### Make sure we didn't set this tile already, if we did skip
					for idx in used_indexes:
						if idx == t.index:
							already_set = true
					if already_set:
						continue
					###
					else:
						for water_body_tile in body_of_water:
							if rand_range(0, 1) >= .05:
								water_body_tile.current = true
								water_body_tile.map_tile_type(meta.WATER_TYPE)
								used_indexes.append(water_body_tile.index)
						body_set = true
				else: 
					grouping_buffer -= 1


func map_tiles(lvl_obj=null, preset_level=null):
	if len(level_tiles) >= 100:
		wall_spawn_chance = 9.8
	if preset_level:
		for t in level_tiles:
			if not "wall" in t.tags:
					t.map_tile_type("wall")
		var row = 1
		var col = 1
		for idx in range(0, len(preset_level["tile_list"])):
			preset_level["tile_list"][idx] += " ("+str(row)+")["+str(col)+"]"
			#print(preset_level["tile_list"][idx])
			for t in level_tiles:
				#if i < len(level_tiles):
					#print("[" + str(level_tiles[i].col) + "] " +  str(preset_level["tile_list"][idx]))
				if "[" + str(t.col) + "]" in str(preset_level["tile_list"][idx])\
					and "(" + str(t.row) + ")" in str(preset_level["tile_list"][idx]):# and level_tiles[i].col <= preset_level["cols"] and level_tiles[i].row <= preset_level["rows"]:
					var tile_type = str(preset_level["tile_list"][idx].split(" (")[0])
					#print("mapping tile type/row/col/" + str(tile_type) + "/" + str(t.row) + "/" + str(t.col))
					#print("type " + str(tile_type))
					t.map_tile_type(tile_type)
					break
			row += 1
			if row % preset_level["rows"] == 0:
				col += 1
				row = 0
	elif lvl_obj:
		#var i = 0
		for i in range(0, len(level_tiles)):
			if i <= len(lvl_obj["tile_list"]) - 1:
				var tile_type = lvl_obj["tile_list"][i]
				level_tiles[i].map_tile_type(tile_type)
			else:
				level_tiles[i].map_tile_type("wall")
			#i += 1
	else:
		for t in level_tiles:
			if rand_range(0, 10) >= wall_spawn_chance:
				t.map_tile_type("wall")
			else:
				t.map_tile_type("move")


func set_borders(lvl_obj=null):
	randomize()
	if lvl_obj:
		for t in level_tiles:
			if t.row <= lvl_obj["rows"] * .20 or t.row >= lvl_obj["rows"] * .80:
				var type = "water"
				var rand_types = ["water", "wall"]
				if t.row <= random_lvl["rows"] * .4 or t.row >= random_lvl["rows"] * .96:
					if rand_range(0, 1) >= .98:
						type = rand_types[rand_range(0, len(rand_types))]
				t.map_tile_type(type)
	else:
		for t in level_tiles:
			var type = "rough"
			var rand_val = rand_range(0, 1)
			var rand_types = ["wall", "water"]
			if t.row <= random_lvl["rows"] * .20 or t.row >= random_lvl["rows"] * .80:
				if t.row <= random_lvl["rows"] * .4 or t.row >= random_lvl["rows"] * .96:
					if rand_range(0, 1) >= .98:
						type = rand_types[rand_range(0, len(rand_types))]
				t.map_tile_type(type)


func spawn_player(new_player=true):
	if new_player:
		#print("in spawn_player")
		meta.player_turn = true
		if get_node("/root").has_node("player"):
			var p = get_node("/root/player")
			p.queue_free()
		meta.current_characters = []
		meta.current_characters_idx = 0
		var p = main.PLAYER.instance()
		get_node("/root").add_child(p)
		meta.current_characters.append(p)
		meta.current_character_turn = p
		p.char_type = meta.DOG_TYPE
		var spawn_tile = level_tiles[0]
		
		for t in level_tiles:
			if t.spawn_player:
				spawn_tile = t
				break
		
		if spawn_tile == level_tiles[0]:
			for t in level_tiles:
				if t.row != 0 and t.col != 0:
					spawn_tile = t
					break
		
		
		p.set_spawn_tile(spawn_tile)
		if has_node("text_overlay/text_overlay_node"):
			var text_overlay = get_node("text_overlay/text_overlay_node")
			var text_overlay_parent = text_overlay.get_parent()
			text_overlay_parent.remove_child(text_overlay)
			p.get_node("cam_body/cl").add_child(text_overlay)
			text_overlay.position = p.get_node("cam_body/cl/display_node").global_position
		change_turn_display_name(p)
		meta.map_char(p.char_type, p)
		for btn in p.skill_btns:
			if main.checkIfNodeDeleted(btn) == false and btn:
				btn.call_defered("queue_free")
		p.skill_btns = []
		p.set_skill_btn_position()
	else:
		var p = get_node("/root/player")
		p.reset_player()
		meta.current_character_turn = p
		meta.map_char(p.char_type, p)
		p.set_skill_btn_position()
	handle_level_start_camera_change_display()
	

func handle_level_start_camera_change_display():
	var p = get_node("/root/player")
	main.handle_in_battle_input("scroll_forward")
	for i in range(4):
		var timer = Timer.new()
		timer.set_wait_time((3.4-i)*.03)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
		main.handle_in_battle_input("scroll_back")
	if main.checkIfNodeDeleted(p) == false and p.current_tile:
		p.current_tile.hover()
		p.current_tile.exit_hover()


func get_spawn_tile():
	for t in level_tiles:
		if t.spawn_player:
			return t
	#print("no spawn could be looking for 'tee'???")


func spawn_player_old():
	var p = main.PLAYER.instance()
	get_node("/root").add_child(p)
	var spawn_tile = level_tiles[0]
	var count = 0
	for t in level_tiles:
		if t.can_move and t.spawn_player:
			if spawn_tile == level_tiles[0] and t != level_tiles[0] and t.row != 0 and t.col != 0:
				spawn_tile = t
			if len(t.neighbors) >= 2:
				# must have at least 2 open spots nearby
				var safe_spawn = true
				for n in t.neighbors:
					# check each neighbor, if any are not movable
					# it will not be used except just as a default/fallback
					if not n.can_move:
						safe_spawn = false
				if safe_spawn:
					spawn_tile = t

	p.set_spawn_tile(spawn_tile)
	change_turn_display_name(p)


func set_tile_neighbors(row, col):
	for t in level_tiles:
		connect_astart_path_neightbors(level_astar, t.index, t, row, col, meta.unccupied_tile_weight)
		t.get_tile_neighbors()


func connect_astart_path_neightbors(astar_path_obj, tile_index, tile, row, col, tile_weight):
	# We use the current tile's index as reference
	var above_tile_idx = tile_index - row
	var right_tile_idx = tile_index + 1
	var below_tile_idx = tile_index + row
	var left_tile_idx = tile_index - 1

	var below_left_tile_idx = tile_index - 1 + row
	var above_left_tile_idx = tile_index - 1 - row
	var below_right_tile_idx = tile_index + 1 + row
	var above_right_tile_idx = tile_index + 1 - row
	var tile_count = len(level_tiles)
	if main.checkIfNodeDeleted(astar_path_obj) == false:
		if tile.col > 0 and astar_path_obj.has_point(above_tile_idx) and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, above_tile_idx, true)
	
		if tile.row < row-1 and astar_path_obj.has_point(right_tile_idx) and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, right_tile_idx, true)
	
		if tile.col < col-1 and astar_path_obj.has_point(below_tile_idx) and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, below_tile_idx, true)
	
		if tile.row > 0 and astar_path_obj.has_point(left_tile_idx) and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, left_tile_idx, true)
	
		if tile.row > 0 and astar_path_obj.has_point(below_left_tile_idx) and below_left_tile_idx >= 0 and below_left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, below_left_tile_idx, true)
		
		if tile.row > 0 and astar_path_obj.has_point(above_left_tile_idx) and above_left_tile_idx >= 0 and above_left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, above_left_tile_idx, true)
		
		if tile.row > 0 and astar_path_obj.has_point(below_right_tile_idx) and below_right_tile_idx >= 0 and below_right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, below_right_tile_idx, true)
		
		if tile.row > 0 and astar_path_obj.has_point(above_right_tile_idx) and above_right_tile_idx >= 0 and above_right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
			astar_path_obj.connect_points(tile_index, above_right_tile_idx, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if len(round_turns) > 0 and main.checkIfNodeDeleted(round_turns) == false:
		change_turn_display_name(round_turns[0])
	
	if get_node("/root").has_node("player"):
		if process_displays:
			handle_turn_order_display()
		var p = get_node("/root/player")
		if p.show_overlay:
			show_enm_atk_range()

func handle_turn_order_display():
	var p = get_node("/root/player")
	var char_count = 0
	var x_buffer = 132
	for character_icon in round_turn_icons:
		char_count += 1
		if p and p.has_node("cam_body/cl/text_overlay"):
			character_icon.position = p.get_node("cam_body/cl/text_overlay").global_position #$text_overlay/text_overlay_node/turn_order_container.global_position
		character_icon.position.x += char_count * x_buffer
		if char_count > 1:
			character_icon.modulate = Color(1, 1, 1, (1- (char_count*.1)))


func attach_text_overlay(follow_node, global=false):
	var p = get_node("/root/player")
	return
	if p and p.has_node("cam_body/cl/text_overlay_node"):
		var text_overlay = p.get_node("cam_body/cl/text_overlay_node")
		if not global:
			if $text_overlay/text_overlay_node.position.x != follow_node.position.x + text_x_buffer:
				$text_overlay/text_overlay_node.position.x = follow_node.position.x + text_x_buffer
				
			if $text_overlay/text_overlay_node.position.y != follow_node.position.y + text_y_buffer:
				$text_overlay/text_overlay_node.position.y = follow_node.position.y + text_y_buffer
		else:
			if $text_overlay/text_overlay_node.position.x != follow_node.global_position.x + text_x_buffer:
				$text_overlay/text_overlay_node.position.x = follow_node.global_position.x + text_x_buffer
				
			if $text_overlay/text_overlay_node.position.y != follow_node.global_position.y + text_y_buffer:
				$text_overlay/text_overlay_node.position.y = follow_node.global_position.y + text_y_buffer


func process_enemy_turns():
	if not processing_turns:
		processing_turns = true
		update_turn_order_details()
		while len(round_turns) > 0 and main.checkIfNodeDeleted(round_turns[0]) == false:
			print('starting turn for ' + str(round_turns[0].char_name))
			var turn_time_limit = 12
			if not round_turns[0].processing_turn:
				round_turns[0].validate_enm_for_turn()
				if round_turns[0].should_remove:
					print("should remove")
					round_turns[0].remove_enemy()
					round_turns.remove(0)
					continue
				else:
					round_turns[0].start_turn()
			var player = get_node("/root/player")
			while round_turns[0] and main.checkIfNodeDeleted(round_turns[0]) == false and round_turns[0].processing_turn:
				change_turn_display_name(round_turns[0])
				update_turn_order_details()
				var timer = Timer.new()
				timer.set_wait_time(1)
				timer.set_one_shot(true)
				get_node("/root").add_child(timer)
				timer.start()
				yield(timer, "timeout")
				timer.queue_free()
				turn_time_limit -= 1
				if turn_time_limit <= 0:
					print("turn didn't end before limit moving on")
					if len(round_turns) > 0 and round_turns[0] and main.checkIfNodeDeleted(round_turns[0]) == false:
						round_turns[0].stop_turn("level.gd too slow")
					if turn_time_limit <= -round(turn_time_limit * .50):
						break
			print('turn over')
			if main.checkIfNodeDeleted(round_turns[0]) == false:
				if round_turns[0].should_remove:
					print("should remove")
					round_turns[0].remove_enemy()
				round_turns.remove(0)
		if get_node("/root").has_node("player"):
			change_turn_display_name(get_node("/root/player"))
		update_turn_order_details()
		processing_turns = false
		end_turn()


func update_turn_order_details():
	var index = 0
	for icon in round_turn_icons:
		icon.visible = false
		if index < len(round_turns):
			var char_node = round_turns[index]
			var char_detail_text = "HP: "+str(char_node.health)+"/"+str(char_node.default_health)+" DEF: " + str(char_node.current_defense)+"/"+str(str(char_node.default_defense))\
								  +"\n"+str(char_node.current_attack)+"/"+str(char_node.default_attack)
			icon.get_node("title").set_text(char_node.char_name)
			icon.get_node("misc").set_text(char_detail_text)
			icon.visible = true
		else:
			icon.get_node("title").set_text("")
			icon.get_node("misc").set_text("")
		index += 1


func check_should_end_level():
	var level_objective = "destroy"
	if level_objective == "destroy":
		var enms_left = 0
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive:
				enms_left += 1
		if enms_left <= 0: # or current_turn >= random_turns: for turn length goal?
			meta.spawn_new_level()
			return true
	return false


func end_turn():
	if processing_turns:
		return
	if not get_node("/root").has_node("player"):
		return
	if check_should_end_level():
		return
	var p = get_node("/root/player")
	p.stealth = is_player_stealth()
	if meta.player_turn: 
		p.get_node("cam_body/cl/overlays and underlays/stealth_overlay").visible = p.stealth
		p.get_node("cam_body/cl/overlays and underlays/chased_overlay").visible = not p.stealth
		if p.stealth:
			pass
		meta.player_turn = false
		p.stop_turn()
		round_turns = []
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive:
				enm.current_tile.set_popout_details()
				enm.get_node("card").visible = false
				round_turns.append(enm)
		process_enemy_turns()
	else:
		p.get_node("cam_body/cl/overlays and underlays/stealth_overlay").visible = p.stealth
		p.get_node("cam_body/cl/overlays and underlays/chased_overlay").visible = not p.stealth

		if p.stealth:
			pass
		current_turn += 1
		meta.player_turn = true
		p.start_turn()
		change_turn_display_name(p)
		#print('player turn')
	meta.set_turn_order_info()

func is_player_stealth():
	# reset to player stealth value as its change with enm and player turns
	var player = get_node("/root/player")
	if not player.alive:
		print("log: player dead in stealth check")
		return false
	for enm in get_tree().get_nodes_in_group("enemies"):
		if main.checkIfNodeDeleted(enm) == false and enm.alive:
			if enm.chasing_player:
				if not player.invisible:
					return false
				else:
					pass
					# enm.chasing_player = false
	return true



func change_static_battle_ui(action):
	if action == "change_turns":
		pass


func show_enm_atk_range():
	if get_node("/root").has_node("player"):
		var p = get_node("/root/player")
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive:
				var enm_v_tiles = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.view_range)
				for enm_v_t in enm_v_tiles:
					if self != enm_v_t:
						enm_v_t.modulate = Color(enm.red, enm.green, enm.blue, 1)


func change_turn_display_name(character):
	meta.get_character_display_text(character)
	var p = get_node("/root/player")
	if p and p.has_node("cam_body/cl/text_overlay_node"):
		p.get_node("cam_body/cl/text_overlay_node/level_text").set_text("Turn " + str(current_turn) + "  /  " + str(random_turns))
	#var character_stats = all_stats[0]
	#var additional_details = all_stats[1]
	#$text_overlay/character_stats.set_text(character_stats)
	#$text_overlay/additional_details.set_text(additional_details)


func _on_end_turn_button_pressed():
	if meta.player_turn:
		end_turn()

func _on_end_turn_button_mouse_entered():
	pass # Replace with function body.


func _on_end_turn_button_mouse_exited():
	pass # Replace with function body.
