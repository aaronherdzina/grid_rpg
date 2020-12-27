extends Node2D

var speed = rand_range(300, 450)
var path = []
var target_pos = Vector2()
var target_tile = null
var current_tile = null
var processing_turn = false
var id = 0

var move_distance = rand_range(2, 5)

func _ready():
	set_process(true)


func set_tile_target(target_node):
	var l = get_node("/root/level")
	if not target_node.can_move:
		target_tile = meta.get_closest_adjacent_tile(self, target_node)
		if target_tile:
			target_pos = target_tile.global_position
			return

	target_tile = target_node
	target_pos = target_node.global_position

func set_spawn_tile(target_node):
	position = target_node.global_position
	current_tile = target_node


func set_navigation():
	if not target_tile or not current_tile:
		return
	var l = get_node("/root/level")
	var point_path = l.level_astar.get_id_path(current_tile.index, target_tile.index)
	path = []
	var debug_idx_path = []
	#print('debug_idx_path is ' + str(debug_idx_path) + ' made from start ' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	
	# WE seem to be adding path tile nodes in wrong order compared to astar point array
	# we probably want to do this and just correct though then we have reference to the tile too
	for p in point_path:
		for t in l.level_tiles:
			if p == t.index:
				path.append(t)
				debug_idx_path.append(t.index)
			if len(path) > move_distance:
				break
		if len(path) > move_distance:
			break
	#print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]
		#path[0].modulate = Color(0, 0, .5, 1)
		#path[-1].modulate = Color(1, 1, 0, 1)


func start_turn():
	# start turn
	# process turn
	# consider delay to move animations
	move()
	#######

	# after turn


func stop_turn():
	processing_turn = false


func move():
	var player = get_node("/root/player")
	set_tile_target(player.current_tile)
	set_navigation()


func _process(delta):
	# note the path is a list of actual tiles 
	if path.size() > 0:
		var d = self.global_position.distance_to(path[0].global_position)
		if d > 10:
			position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
		else:
			current_tile = path[0]
			position = current_tile.global_position
			path.remove(0)
	else:
		stop_turn() # does not handle attacking or anything yet
