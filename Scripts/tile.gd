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
var highlight_background_color = Color(1, 1, .5, .7)
var path_highlight_background_color = Color(.8, .8, 1, .7)
var default_background_color = Color(0, 0, 0, 0)
var too_far_background_color = Color(1, .3, .3, .2)
var current_tile_background_color = Color(.3, .3, .6, .7)

var highlight_tile_color = Color(1, 1, .8, 1)
var path_highlight_tile_color = Color(.8, .8, 1, 1)
var too_far_tile_color = Color(1, .8, .8, 1)

var player_on_tile = false
var enm_on_tile = false
var custom_weight = null

var forest = false
var special = false
var forest_path = false
var tags = []

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
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	var weight =  meta.unccupied_tile_weight
	can_move = true
	if custom_weight:
		weight = custom_weight

	tags = []
	# $Sprite.set_texture(main.MOUNTAIN_TILE)
	if tile_type == "move" or tile_type == "" or not tile_type:
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.BASIC_TILE)
	elif tile_type == "enemy spawn":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.ENEMY_SPAWN_TILE)
		print('enemy spawn')
		tags.append("Enemy Spawn")
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
		tags.append("Forest")
		tags.append("+1 Defense")
		description = "+1 Defense"
	elif tile_type == "forest path":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.FOREST_PATH_TILE_1)
		forest = true
		special = true
		forest_path = true
		tags.append("Forest")
		tags.append("Special")
		tags.append("+2 Move")
		description = "+2 Move starting turn here"
	else:
		if not custom_weight: weight = meta.wall_tile_weight
		tags.append("Wall")
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
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	if main.debug:
		for t in l.level_tiles:
			t.modulate = Color(1, 1, 1, 1)
			if not t.can_move:
				t.modulate = Color(.4, .4, .4, 1)
	move_or_attack()


func move_or_attack():
	if not get_node("/root").has_node("player"):
		return
	var p = get_node("/root/player")

	if meta.player_turn:
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive and self.index == enm.current_tile.index:
				p.attack(enm)
				return
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
	if not get_node("/root").has_node("player"):
		return
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	var point_path = l.level_astar.get_id_path(player.current_tile.index, index)
	var path = []
	var debug_idx_path = []
	var tile_hover_color = Color(.7, .7, 1, 1)
	
	var tile_text = "Tile " + str(index)


	if not can_move:
		tile_hover_color = Color(.5, .5, .5, 1)
	
	if enm_on_tile:
		tile_hover_color = Color(1, .5, .5, 1)

	player.current_tile.get_node("background").modulate = current_tile_background_color
	player.current_tile.z_index = 1
	player.current_tile.modulate = Color(1, 1, 1, 1)

	self.modulate = tile_hover_color
	#for n in neighbors:
	#	if n.can_move:
	#		n.z_index = 1
	var index_count = 0
	var scale_variant = .015
	var scale_var = .95
	var scale_var_default = .95
	for p in point_path:
		if l.level_astar.get_point_weight_scale(p) >= meta.max_weight:
			l.get_node("text_overlay/tile_text").set_text(tile_text)
			return
		for t in l.level_tiles:
			if p == t.index and t != player.current_tile:
				t.get_node("Sprite").modulate = Color(.9, .9, 1, 1)
				t.set_scale(Vector2(scale_var, scale_var))
				path.append(t)
				debug_idx_path.append(t.index)
				index_count += 1
				scale_var += scale_variant
				if len(path) > player.remaining_move:
					t.z_index = index_count
					# t.get_node("background").modulate = too_far_background_color
					t.modulate = too_far_tile_color
				elif len(path) == player.remaining_move: # full move
					t.get_node("background").modulate = highlight_background_color
					t.modulate = highlight_tile_color
					t.z_index = index_count
				else:
					t.z_index = index_count
					t.get_node("background").modulate = path_highlight_background_color
					t.modulate = path_highlight_tile_color
				break
			else:
				t.set_scale(Vector2(scale_var_default, scale_var_default))
	z_index = index_count + 1
	tile_text += "\n"
	for i in range(0, len(tags)):
		tile_text += str(tags[i]) + " "
		if i % 6 == 0:
			tile_text += "\n"

	for t in meta.get_adjacent_tiles_in_distance(self, 1):
		t.modulate = Color(1, 0, 1, 1)
		
	l.get_node("text_overlay/tile_text").set_text(tile_text)


func exit_hover():
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	l.get_node("text_overlay/tile_text").set_text("")
	for t in l.level_tiles:
		t.modulate = Color(1, 1, 1, 1)
		t.get_node("background").modulate = default_background_color
		t.get_node("Sprite").modulate = Color(1, 1, 1, 1)
		t.z_index = 0
	z_index = 0


func _on_Button_mouse_entered():
	hover()


func _on_Button_mouse_exited():
	exit_hover()
