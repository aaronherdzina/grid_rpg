extends Node2D

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
var tile_gap = 160

var enms = 5
var level_astar = null
var current_enm_count = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func spawn_tiles():
	randomize()
	var col = meta.current_level_cols
	var row = meta.current_level_rows
	#if not starting_tile:
	#	starting_tile = get_node("starting_tile")

	var tile_index = -1

	level_astar = AStar2D.new()
	#var res = astar.get_id_path(1, 3) # Returns [1, 2, 3]
	
	for c in range(0, col):
		for r in range(0, row):
			tile_index += 1
			var t = main.TILE.instance()
			var tile_map = $nav/tile_map
			var tile_info = ""
			get_node("nav/tile_map").add_child(t)
			t.row = r
			t.col = c
			level_tiles.append(t)
			t.index = tile_index

			if main.debug: tile_info += " |row/col " + str(r) + '/' + str(c)

			if not starting_tile:
				starting_tile = t
				t.position = Vector2(tile_gap * 1.65, tile_gap * .65)
			else:
				t.position = Vector2(starting_tile.global_position.x +\
									(c * tile_gap),\
									starting_tile.global_position.y +\
									(r * tile_gap))
			if main.debug: 
				t.get_node("debug_info").visible = true
				t.get_node("debug_info").set_text(tile_info)

	print('level_astar ' + str(level_astar))
	set_tile_neighbors(row, col)
	spawn_player()
	for _i in range(0, enms):
		var timer = Timer.new()
		timer.set_wait_time(1)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
		var count = -1
		for t in level_tiles:
			count += 1
			randomize()
			if t.can_move:
				if rand_range(0, 10) >= 7 or count >= len(level_tiles) * .99:
					spawn_enemies(level_astar,  t, level_tiles[col+1])
					break


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


func spawn_enemies(astar_path_obj, starting_tile, target_tile):
	var e = main.ENEMY.instance()
	get_node("/root").add_child(e)
	e.set_spawn_tile(starting_tile)
	e.set_tile_target(target_tile)
	e.set_navigation()
	e.add_to_group("enemies")
	e.id = current_enm_count
	if main.debug:
		e.get_node("Sprite/debug_info").visible = true
		e.get_node("Sprite/debug_info").set_text(str(e.id))
	current_enm_count += 1


func set_tile_neighbors(row, col):
	for t in level_tiles:
		if rand_range(0, 10) >= 8:
			t.can_move = false
			#connect_astart_path_neightbors(level_astar, t.index, t, row, col, meta.wall_tile_weight)
			t.get_node("Sprite").set_texture(main.WALL_TILE)
		elif rand_range(0, 10) >= 9:
			connect_astart_path_neightbors(level_astar, t.index, t, row, col, meta.unccupied_tile_weight)
			t.get_node("Sprite").set_texture(main.MOUNTAIN_TILE)
		else:
			connect_astart_path_neightbors(level_astar, t.index, t, row, col, meta.unccupied_tile_weight)
			t.get_node("Sprite").set_texture(main.BASIC_TILE)


func connect_astart_path_neightbors(astar_path_obj, tile_index, tile, row, col, tile_weight):
	# We use the current tile's index as reference
	var above_tile_idx = tile_index - 1
	var right_tile_idx = tile_index + row
	var below_tile_idx = tile_index + 1
	var left_tile_idx = tile_index - row
	var tile_count = len(level_tiles) - 1 # from 0

	# set initial spot
	astar_path_obj.add_point(tile_index, tile.global_position, tile_weight)
	# make sure point exists, node exists and make sure the
	# index is not out of range or the tile array
	if tile.row > 0 and astar_path_obj.has_point(above_tile_idx) and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, above_tile_idx, true)

	if tile.col < col - 1 and astar_path_obj.has_point(right_tile_idx) and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, right_tile_idx, true)

	if tile.row < row - 1 and astar_path_obj.has_point(below_tile_idx) and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, below_tile_idx, true)

	if tile.col > 0 and astar_path_obj.has_point(left_tile_idx) and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(level_tiles[tile_index]) == false:
		astar_path_obj.connect_points(tile_index, left_tile_idx, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func process_enemy_turns():
	while len(round_turns) > 0:
		print('starting turn for ' + str(round_turns[0].id))
		var turn_time_limit = 20
		round_turns[0].processing_turn = true
		round_turns[0].start_turn()
		while round_turns[0].processing_turn:
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
				round_turns[0].processing_turn = false
				break
		print('turn over')
		round_turns.remove(0)


func _on_end_turn_button_pressed():
	var p = get_node("/root/player")
	if meta.player_turn: 
		p.stop_turn()
		meta.player_turn = false
		round_turns = []
		for enm in get_tree().get_nodes_in_group("enemies"):
			round_turns.append(enm)
		process_enemy_turns()
	else:
		p.start_turn()
		print('player turn')

func _on_end_turn_button_mouse_entered():
	pass # Replace with function body.


func _on_end_turn_button_mouse_exited():
	pass # Replace with function body.
