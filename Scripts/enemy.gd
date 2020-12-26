extends Node2D

var speed = 350
var path = []
var target_pos = Vector2()
var target_tile = null
var current_tile = null

func _ready():
	set_process(true)


func set_tile_target(target_node):
	
	if not target_node.can_move:
		for n in target_node.neighbors:
			if n.can_move:
				target_tile = n
				target_pos = n.global_position
				return

	target_tile = target_node
	target_pos = target_node.global_position

func set_spawn_tile(target_node):
	position = target_node.global_position
	current_tile = target_node


func set_navigation():
	var l = get_node("/root/level")
	var point_path = l.level_astar.get_id_path(current_tile.index, target_tile.index)
	path = []
	var debug_idx_path = []
	print('debug_idx_path is ' + str(debug_idx_path) + ' made from start ' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	
	# WE seem to be adding path tile nodes in wrong order compared to astar point array
	# we probably want to do this and just correct though then we have reference to the tile too
	for p in point_path:
		for t in l.level_tiles:
			if p == t.index:
				path.append(t)
				debug_idx_path.append(t.index)
				t.modulate = Color(.7, .7, .2, 1)
	print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]
		path[0].modulate = Color(0, 0, .5, 1)
		path[-1].modulate = Color(1, 1, 0, 1)


func _process(delta):
	# note the path is a list of actual tiles 
	if path.size() > 0:
		var d = self.global_position.distance_to(path[0].global_position)
		if d > 2:
			position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
		else:
			current_tile = path[0]
			position = current_tile.global_position
			path.remove(0)
