extends Node2D

var wall_spawn_chance = 9
var text_x_buffer = 0
var text_y_buffer = 400
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
	
	"tile_list": []
	}

var max_lvl_cols = 15
var min_lvl_cols = 5

var max_lvl_rows = 17
var min_lvl_rows = 7
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
var tile_gap = 145
var far_tile_gap_setting = 150
var far_gap_tile_outline_size = 1.012
var close_tile_gap_setting = 140
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


"""
func spawn_premade_tiles_old(lvl_obj):
	randomize()
	#lvl_obj example:
	#lvl_obj = {
	#	tile_list = [],
	#	cols = 7,
	#	rows = 6
	#}
	
	var col = lvl_obj["cols"]
	var row = lvl_obj["rows"]
# warning-ignore:unused_variable
	var tiles = lvl_obj["tile_list"]
	current_rows = row
	current_cols = col
	#if not starting_tile:
	#	starting_tile = get_node("starting_tile")

	var tile_index = -1

	#print('lvl_obj ' + str(lvl_obj))
	level_astar = AStar2D.new()
	#var res = astar.get_id_path(1, 3) # Returns [1, 2, 3]
	tile_gap = close_tile_gap_setting if rand_range(0, 1) >= .5 else far_tile_gap_setting
	
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
			
			#print('Vector2(shadow_noise_x, shadow_noise_y) ' + str(Vector2(shadow_noise_x, shadow_noise_y)))
			t.get_node("shadow").position = Vector2(shadow_noise_x, shadow_noise_y)
			if main.debug: tile_info += " |index " + str(tile_index)

			if not starting_tile:
				starting_tile = t
				t.position = Vector2(tile_gap * 2.8, tile_gap * .75)
			else:
				t.position = Vector2(starting_tile.global_position.x +
									(r * tile_gap),
									starting_tile.global_position.y +
									(c * tile_gap))
			if main.debug: tile_info += " |row/col " + str(r) + '/' + str(c) + "\ntile_gap: " + str(tile_gap * r)
			if main.debug: 
				t.get_node("debug_info").visible = true
				t.get_node("debug_info").set_text(tile_info)

	set_points(level_astar, level_tiles)
	set_tile_neighbors(row, col)
	map_tiles(lvl_obj)
	# call to ensure we wait longer than the delay in map_tiles() or we have a race condition
	var timer1 = Timer.new()
	timer1.set_wait_time(len(level_tiles) * (spawn_types_display_speed * 1.5))
	timer1.set_one_shot(true)
	get_node("/root").add_child(timer1)
	timer1.start()
	yield(timer1, "timeout")
	timer1.queue_free()
	for t in level_tiles:
		if t.spawn_enemies:
			print("spawn enemy")
			spawn_enemies(level_astaq,  t, t)
			var timer = Timer.new()
			timer.set_wait_time(spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
	spawn_player()
"""

func set_full_level(lvl_obj):
	lvl_obj["cols"] = max_lvl_cols
	lvl_obj["rows"] = max_lvl_rows
	var tile_count  = lvl_obj["cols"] * lvl_obj["rows"]
	for i in range(0, tile_count):
		lvl_obj["tile_list"].append("wall")

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
				t.position = Vector2(tile_gap, tile_gap)
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
	reset_level_vals()
	for t in level_tiles:
		if t.spawn_enemies:
			spawn_enemies(level_astar,  t, t)
			var tmr = Timer.new()
			tmr.set_wait_time(spawn_types_display_speed)
			tmr.set_one_shot(true)
			get_node("/root").add_child(tmr)
			tmr.start()
			yield(tmr, "timeout")
			tmr.queue_free()
	spawn_player()


func reset_level_vals():
	meta.remove_enemies()
	meta.can_spawn_level = true
	main.current_screen = 'battle'


func randomize_level(lvl_obj):
	randomize()
	lvl_obj["tiles_list"] = []
	lvl_obj["cols"] = floor(rand_range(min_lvl_cols, max_lvl_cols))
	lvl_obj["rows"] = floor(rand_range(min_lvl_rows, max_lvl_rows))
	var tile_count  = lvl_obj["cols"] * lvl_obj["rows"]
	var enms = 2 + round(tile_count * .02)
	var player_spawned = false
	map_tiles(lvl_obj)
	#
	for t in level_tiles:
		if t.row <= lvl_obj["rows"] and t.col <= lvl_obj["cols"] and\
		   t.row >= 0 and t.col >= 0:
			if rand_range(0, 1) >= .9:
				t.map_tile_type("water")
			elif rand_range(0, 1) >= .7 and enms > 0:
				enms -= 1
				t.map_tile_type("enemy spawn")
			elif rand_range(0, 1) >= .8:
				t.map_tile_type("forest path")
			else:
				t.map_tile_type("move")
	
	for t in level_tiles:
		if not player_spawned and t.row <= lvl_obj["rows"] and t.col <= lvl_obj["cols"] and\
		   t.row >= 0 and t.col >= 0 and "move" in t.tags:
			for n in t.neighbors:
				if not "wall" in n.tags:
					n.map_tile_type("player spawn")
					break
		if player_spawned:
			break
	#

	#set_borders(lvl_obj)
	reset_level_vals()
	var timer14 = Timer.new()
	timer14.set_wait_time((len(level_tiles)*.01) * spawn_types_display_speed)
	timer14.set_one_shot(true)
	get_node("/root").add_child(timer14)
	timer14.start()
	yield(timer14, "timeout")
	timer14.queue_free()
	
	reset_level_vals()
	for t in level_tiles:
		if t.spawn_enemies:
			spawn_enemies(level_astar,  t, t)
			var tmr = Timer.new()
			tmr.set_wait_time(spawn_types_display_speed)
			tmr.set_one_shot(true)
			get_node("/root").add_child(tmr)
			tmr.start()
			yield(tmr, "timeout")
			tmr.queue_free()
	spawn_player()


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


"""
func map_tiles_old(lvl_obj=null):
	if len(level_tiles) >= 100:
		wall_spawn_chance = 8.2
	if lvl_obj:
		var i = 0
		for t in level_tiles:
			if i <= len(lvl_obj["tile_list"]):
				var tile_type = lvl_obj["tile_list"][i]
				t.map_tile_type(tile_type)
			else:
				break
			i += 1
			var timer = Timer.new()
			timer.set_wait_time(spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
	else:
		for t in level_tiles:
			if rand_range(0, 10) >= wall_spawn_chance:
				t.map_tile_type("wall")
			else:
				t.map_tile_type("")
			var timer = Timer.new()
			timer.set_wait_time(spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
"""


func spawn_player(new_player=true):
	if new_player:
		print("in spawn_player")
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
		var spawn_tile = level_tiles[0]
		for t in level_tiles:
			#print("here???" + str(t.player_spawn) + str(t.can_move))
			if t.player_spawn:
				spawn_tile = t
		"""
		var idx = len(level_tiles) - 1
		var prefered_index = 0
		for i in level_tiles:
			if idx < len(level_tiles) and idx >= 0:
				if not "wall" in level_tiles[idx].tags
				   and not "water" in level_tiles[idx].tags
				   and not "enemy spawn" in level_tiles[idx].tags:
					for n in level_tiles[idx].neighbors:
						if not "enemy spawn" in n.tags:
							prefered_index = idx
			idx -= 1
		var spawn_tile = level_tiles[prefered_index]
		"""
		
		p.set_spawn_tile(spawn_tile)
		change_turn_display_name(p)
	else:
		var p = get_node("/root/player")
		p.reset_player()
		meta.current_character_turn = p


func get_spawn_tile():
	for t in level_tiles:
		if t.player_spawn:
			return t
	print("no spawn could be looking for 'tee'???")


func spawn_player_old():
	var p = main.PLAYER.instance()
	get_node("/root").add_child(p)
	var spawn_tile = level_tiles[0]
	var count = 0
	for t in level_tiles:
		print("here???" + str(t.player_spawn) + str(t.can_move))
		if t.can_move and t.player_spawn:
			print("acceptable spawn point")
			if spawn_tile == level_tiles[0] and t != level_tiles[0] and t.row != 0 and t.col != 0:
				print("found player tile")
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
					print("found player tile is safe spawn")
					spawn_tile = t

	p.set_spawn_tile(spawn_tile)
	change_turn_display_name(p)


func spawn_enemies(astar_path_obj, enm_starting_tile, target_tile):
	var e = main.ENEMY.instance()
	get_node("/root").add_child(e)
	e.set_spawn_tile(enm_starting_tile)
	e.set_tile_target(target_tile)
	e.add_to_group("enemies")
	e.char_name = meta.char_names[rand_range(0, len(meta.char_names) - 1)]
	#print('spawned: ' + e.char_name)
	e.id = current_enm_count
	if main.debug:
		e.get_node("Sprite/debug_info").visible = true
		e.get_node("Sprite/debug_info").set_text(str(e.id))
	else:
		e.get_node("Sprite/debug_info").visible = false
	current_enm_count += 1


func set_tile_neighbors(row, col):
	for t in level_tiles:
		connect_astart_path_neightbors(level_astar, t.index, t, row, col, meta.unccupied_tile_weight)
		t.get_tile_neighbors()

"""
func connect_astart_path_neightbors_OLD(astar_path_obj, tile_index, tile, row, col, tile_weight):
	# We use the current tile's index as reference
	var above_tile_idx = tile_index - row
	var right_tile_idx = tile_index + 1
	var below_tile_idx = tile_index + row
	var left_tile_idx = tile_index - 1
	var tile_count = len(level_tiles)# from 0
	# tiles set for row in for each col, row set on x, col on y
	# set initial spot
	# make sure point exists, node exists and make sure the
	# index is not out of range or the tile array
	#print('right_tile_idx ' + str(tile_index) + ' v right_tile_idx ' + str(right_tile_idx))
	
	if tile.col > 0 and astar_path_obj.has_point(above_tile_idx) and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, above_tile_idx, true)

	if tile.row < row-1 and astar_path_obj.has_point(right_tile_idx) and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, right_tile_idx, true)

	if tile.col < col-1 and astar_path_obj.has_point(below_tile_idx) and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, below_tile_idx, true)

	if tile.row > 0 and astar_path_obj.has_point(left_tile_idx) and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, left_tile_idx, true)
"""


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
func _process(delta):
	if not get_node("/root").has_node("player"):
		return
	var player = get_node("/root/player") # TODO define elsewhere
	if len(round_turns) > 0 and main.checkIfNodeDeleted(round_turns) == false:
		change_turn_display_name(round_turns[0])


func attach_text_overlay(follow_node, global=false):
	if not global:
		if $text_overlay.position.x != follow_node.position.x + text_x_buffer:
			$text_overlay.position.x = follow_node.position.x + text_x_buffer
			
		if $text_overlay.position.y != follow_node.position.y + text_y_buffer:
			$text_overlay.position.y = follow_node.position.y + text_y_buffer
	else:
		if $text_overlay.position.x != follow_node.global_position.x + text_x_buffer:
			$text_overlay.position.x = follow_node.global_position.x + text_x_buffer
			
		if $text_overlay.position.y != follow_node.global_position.y + text_y_buffer:
			$text_overlay.position.y = follow_node.global_position.y + text_y_buffer


func process_enemy_turns():
	if not processing_turns:
		processing_turns = true
		while len(round_turns) > 0:
			print('starting turn for ' + str(round_turns[0].id))
			var turn_time_limit = 12
			if not round_turns[0].processing_turn:
				round_turns[0].start_turn()
			var player = get_node("/root/player")
			while round_turns[0].processing_turn:
				change_turn_display_name(round_turns[0])
				if player and main.checkIfNodeDeleted(player) == false:
					pass
					#player.move_cam(round_turns[0])
					#draw_line (player.global_position, round_turns[0].global_position, Color(1, .4, .4, .4), .5, true)
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
					if len(round_turns) > 0: round_turns[0].stop_turn("level.gd too slow")
					if turn_time_limit <= -round(turn_time_limit * .50):
						break
			print('turn over')
			round_turns.remove(0)
		change_turn_display_name(get_node("/root/player"))
		processing_turns = false
		end_turn()


func end_turn():
	if processing_turns:
		return
	if not get_node("/root").has_node("player"):
		return
	var p = get_node("/root/player")
	p.stealth = is_player_stealth()
	if meta.player_turn: 
		p.get_node("cam/overlays and underlays/stealth_overlay").visible = p.stealth
		p.get_node("cam/overlays and underlays/chased_overlay").visible = not p.stealth
		if p.stealth:
			print('here? stealth')
		meta.player_turn = false
		p.stop_turn()
		round_turns = []
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive:
				round_turns.append(enm)
		process_enemy_turns()
	else:
		p.get_node("cam/overlays and underlays/stealth_overlay").visible = p.stealth
		p.get_node("cam/overlays and underlays/chased_overlay").visible = not p.stealth
		
		if p.stealth:
			print('here? stealth')
		meta.player_turn = true
		p.start_turn()
		change_turn_display_name(p)
		print('player turn')


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
					enm.chasing_player = false
	return true



func change_static_battle_ui(action):
	if action == "change_turns":
		pass


func change_turn_display_name(character):
	var all_stats = meta.get_character_display_text(character)
	var character_stats = all_stats[0]
	var additional_details = all_stats[1]
	$text_overlay/character_stats.set_text(character_stats)
	$text_overlay/additional_details.set_text(additional_details)


func _on_end_turn_button_pressed():
	if meta.player_turn:
		end_turn()

func _on_end_turn_button_mouse_entered():
	pass # Replace with function body.


func _on_end_turn_button_mouse_exited():
	pass # Replace with function body.
