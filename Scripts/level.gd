extends Node2D

var test_lvl = {
	"cols": 6,
	"rows": 8,
	
	"tile_list": ["move", "move", "enemy spawn", "forest", "move", "move", "enemy spawn", "move",
				"move", "move", "forest", "forest", "move", "move", "move", "wall",
				"move", "enemy spawn", "forest path", "move", "move", "forest", "move", "move",
				"move", "forest", "forest", "move", "enemy spawn", "move", "move", "move",
				"move", "move", "forest", "forest", "move", "wall", "wall", "move",
				"move", "player spawn", "move", "move", "move", "move", "move", "move"]
	}

var random_lvl = {
	"cols": 0,
	"rows": 0,
	
	"tile_list": []
	}

var max_lvl_cols = 7
var min_lvl_cols = 4

var max_lvl_rows = 20
var min_lvl_rows = 5
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
var tile_gap = 125
var far_tile_gap_setting = 150
var far_gap_tile_outline_size = 1.03
var close_tile_gap_setting = 125
var close_gap_tile_outline_size = 1.06
var enms = 5
var level_astar = null
var current_enm_count = 0
var processing_turns = false
var spawn_types_display_speed = .01
var current_cols = 0
var current_rows = 0
# Called when the node enters the scene tree for the first time.


func _ready():
	pass


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


func spawn_premade_tiles(lvl_obj):
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

	print('lvl_obj ' + str(lvl_obj))
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
			
			print('Vector2(shadow_noise_x, shadow_noise_y) ' + str(Vector2(shadow_noise_x, shadow_noise_y)))
			t.get_node("shadow").position = Vector2(shadow_noise_x, shadow_noise_y)
			if main.debug: tile_info += " |index " + str(tile_index)

			if not starting_tile:
				starting_tile = t
				t.position = Vector2(tile_gap * 2.8, tile_gap * .75)
			else:
				t.position = Vector2(starting_tile.global_position.x +\
									(r * tile_gap),\
									starting_tile.global_position.y +\
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
			spawn_enemies(level_astar,  t, level_tiles[0])
			var timer = Timer.new()
			timer.set_wait_time(spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
	spawn_player()


func spawn_tiles():
	randomize()
	var col = meta.current_level_cols
	var row = meta.current_level_rows
	remove_tiles()
	#if not starting_tile:
	#	starting_tile = get_node("starting_tile")

	var tile_index = -1

	level_astar = AStar2D.new()
	#var res = astar.get_id_path(1, 3) # Returns [1, 2, 3]
	
	current_rows = row
	current_cols = col
	for c in range(0, col):
		for r in range(0, row):
			tile_index += 1
			var t = main.TILE.instance()
			var tile_map = $tile_container
			var tile_info = ""
			get_node("tile_container").add_child(t)
			t.row = r
			t.col = c
			level_tiles.append(t)
			t.index = tile_index

			if not starting_tile:
				starting_tile = t
				t.position = Vector2(tile_gap * 2.2, tile_gap * .75)
			else:
				t.position = Vector2(starting_tile.global_position.x +\
									(r * tile_gap),\
									starting_tile.global_position.y +\
									(c * tile_gap))
			if main.debug: tile_info += " |row/col " + str(r) + '/' + str(c) + "tile_gap: " + str(tile_gap * c)
			if main.debug: 
				t.get_node("debug_info").visible = true
				t.get_node("debug_info").set_text(tile_info)
	set_points(level_astar, level_tiles)
	set_tile_neighbors(row, col)
	map_tiles()
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
			spawn_enemies(level_astar,  t, level_tiles[0])
			var timer = Timer.new()
			timer.set_wait_time(spawn_types_display_speed)
			timer.set_one_shot(true)
			get_node("/root").add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
	spawn_player()


func set_random_level(lvl_obj):
	randomize()
	lvl_obj["cols"] = max_lvl_cols#floor(rand_range(min_lvl_cols, max_lvl_cols))
	lvl_obj["rows"] = floor(rand_range(min_lvl_rows, max_lvl_rows))
	
	var tile_count  = lvl_obj["cols"] * lvl_obj["rows"]
	var tile_types = []
	var forest_chance = .25
	var forest_path_chance = .14
	var wall_chance = .4
	var wall_limit = tile_count * .25
	var player_spawned = false
	var enemy_spawns = 1 + (tile_count * .015)
	
	for i in range(0, tile_count * forest_chance):
		tile_types.append("forest")
	for i in range(0, tile_count * forest_path_chance):
		wall_limit -= 1
		tile_types.append("wall")
		if wall_limit <= 0:
			break
	for i in range(0, enemy_spawns):
		enemy_spawns -= 1
		tile_types.append("enemy spawn")
		if enemy_spawns <= 0:
			break
	
	var left_over_tiles = tile_count - len(tile_types) - 1
	if left_over_tiles > 0:
		for i in range(0, left_over_tiles):
			tile_types.append("move")
	
	for i in range(0, tile_count):
		if not player_spawned:
			if rand_range(0, 10) >= 8.5 or i >= tile_count * .70:
				player_spawned = true
				lvl_obj["tile_list"].append("player spawn")
			else:
				lvl_obj["tile_list"].append(tile_types[rand_range(0, len(tile_types) - 1)])
		else:
			lvl_obj["tile_list"].append(tile_types[rand_range(0, len(tile_types) - 1)])


func set_points(astar_path_obj, list, tile_weight=meta.unccupied_tile_weight):
	for t in list:
		astar_path_obj.add_point(t.index, t.global_position, tile_weight)


func map_tiles(lvl_obj=null):
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
			if rand_range(0, 10) >= 8.5:
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


func spawn_player():
	var p = main.PLAYER.instance()
	get_node("/root").add_child(p)
	var spawn_tile = level_tiles[0]
	var count = 0
	for t in level_tiles:
		count += 1
		if count < len(level_tiles) * .5:
			continue

		if t.can_move:
			if spawn_tile == level_tiles[0]:
				spawn_tile = t
			if len(t.neighbors) >= 3:
				# must have at least 3 open spot nearby
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


func spawn_enemies(astar_path_obj, starting_tile, target_tile):
	var e = main.ENEMY.instance()
	get_node("/root").add_child(e)
	e.set_spawn_tile(starting_tile)
	e.set_tile_target(target_tile)
	e.add_to_group("enemies")
	e.char_name = meta.char_names[rand_range(0, len(meta.char_names) - 1)]
	print('spawned: ' + e.char_name)
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


func connect_astart_path_neightbors(astar_path_obj, tile_index, tile, row, col, tile_weight):
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
	print('right_tile_idx ' + str(tile_index) + ' v right_tile_idx ' + str(right_tile_idx))
	
	if tile.col > 0 and astar_path_obj.has_point(above_tile_idx) and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, above_tile_idx, true)

	if tile.row < row-1 and astar_path_obj.has_point(right_tile_idx) and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, right_tile_idx, true)

	if tile.col < col-1 and astar_path_obj.has_point(below_tile_idx) and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, below_tile_idx, true)

	if tile.row > 0 and astar_path_obj.has_point(left_tile_idx) and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, left_tile_idx, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func process_enemy_turns():
	if not processing_turns:
		processing_turns = true
		while len(round_turns) > 0:
			print('starting turn for ' + str(round_turns[0].id))
			var turn_time_limit = 20
			round_turns[0].processing_turn = true
			round_turns[0].start_turn()
			while round_turns[0].processing_turn:
				change_turn_display_name(round_turns[0])
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
					if len(round_turns) > 0: round_turns[0].processing_turn = false
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
	if meta.player_turn: 
		meta.player_turn = false
		p.stop_turn()
		round_turns = []
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive:
				round_turns.append(enm)
		process_enemy_turns()
	else:
		meta.player_turn = true
		p.start_turn()
		print('player turn')


func change_static_battle_ui(action):
	if action == "change_turns":
		pass


func change_turn_display_name(character):
	var character_stats = meta.get_character_display_text(character)
	$text_overlay/character_stats.set_text(character_stats)


func _on_end_turn_button_pressed():
	if meta.player_turn:
		end_turn()

func _on_end_turn_button_mouse_entered():
	pass # Replace with function body.


func _on_end_turn_button_mouse_exited():
	pass # Replace with function body.
