extends Node2D

# debug stuff for testing nav
var is_end = false
var is_start = true
var can_move = false
var spawn_player = false
var spawn_enemies = false
var index = 0
var row = 0
var col = 0
var neighbors = []
var player_spawn = false
var highlight_background_color = Color(1, 1, .5, 1)
var path_highlight_background_color = Color(.5, 0, 1, 1)
var default_background_color = Color(0, 0, 0, 0)
var too_far_background_color = Color(1, .3, .3, 1)
var current_tile_background_color = Color(.2, .1, .4, 1)

var custom_weight = null

var forest = false
var special = false
var forest_path = false

var defense_buff = 0
var description = ""
##

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func map_tile_type(tile_type):
	var l = get_node("/root/level")
	var weight =  meta.unccupied_tile_weight
	can_move = true
	if custom_weight:
		weight = custom_weight

	# $Sprite.set_texture(main.MOUNTAIN_TILE)
	if tile_type == "move" or tile_type == "" or not tile_type:
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.BASIC_TILE)
	elif tile_type == "enemy spawn":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.ENEMY_SPAWN_TILE)
		print('enemy spawn')
		spawn_enemies = true
	elif tile_type == "player spawn":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.PLAYER_SPAWN_TILE)
		print('player spawn')
		spawn_player = true
	elif tile_type == "forest":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.basic_forest_tiles[rand_range(0, len(main.basic_forest_tiles))])
		forest = true
		defense_buff += 1
		description = "+1 Defense"
	elif tile_type == "forest path":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.FOREST_PATH_TILE_1)
		forest = true
		special = true
		forest_path = true
		description = "+2 Move starting turn here"
	else:
		if not custom_weight: weight = meta.wall_tile_weight
		print('wall ' + str(weight))
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.WALL_TILE)
		can_move = false


func get_tile_neighbors(target=null):
	var l = get_node("/root/level")
	var tile = target if target else self
	var point_neighbors = []
	neighbors = []
	point_neighbors = l.level_astar.get_point_connections(tile.index)
	for point_n in point_neighbors:
		for t in l.level_tiles:
			if point_n == t.index:
				neighbors.append(t)


func _on_Button_pressed():
	var l = get_node("/root/level")

	if main.debug:
		for t in l.level_tiles:
			t.modulate = Color(1, 1, 1, 1)
			if not t.can_move:
				t.modulate = Color(.4, .4, .4, 1)
	if can_move:
		move_to_tile_on_press()


func move_to_tile_on_press():
	if not get_node("/root").has_node("player"):
		return
	var p = get_node("/root/player")
	if meta.player_turn:
		p.chosen_tile = self
		p.move()


func hover():
	var l = get_node("/root/level")
	if not get_node("/root").has_node("player"):
		return
	var player = get_node("/root/player")
	var point_path = l.level_astar.get_id_path(player.current_tile.index, index)
	var path = []
	var debug_idx_path = []

	player.current_tile.get_node("background").modulate = current_tile_background_color
	player.current_tile.z_index = 1
	player.current_tile.modulate = Color(1, 1, 1, 1)

	for n in neighbors:
		if n.can_move:
			n.z_index = 1

	for p in point_path:
		if l.level_astar.get_point_weight_scale(p) >= meta.max_weight:
			return
		for t in l.level_tiles:
			if p == t.index and t != player.current_tile:
				t.get_node("Sprite").modulate = Color(.9, .9, 1, 1)
				path.append(t)
				debug_idx_path.append(t.index)
				if len(path) > player.remaining_move:
					t.z_index = 1
					t.get_node("background").modulate = too_far_background_color
				elif len(path) == player.remaining_move: # full move
					t.get_node("background").modulate = highlight_background_color
					t.z_index = 3
				else:
					t.z_index = 2
					t.get_node("background").modulate = path_highlight_background_color
				break
	z_index = 4


func exit_hover():
	var l = get_node("/root/level")
	for t in l.level_tiles:
		t.get_node("background").modulate = default_background_color
		t.get_node("Sprite").modulate = Color(1, 1, 1, 1)
		t.z_index = 0
	z_index = 0


func _on_Button_mouse_entered():
	hover()


func _on_Button_mouse_exited():
	exit_hover()
