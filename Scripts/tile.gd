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
var highlight_background_color = Color(1, 1, .5, .7)
var path_highlight_background_color = Color(.8, .8, 1, .7)
var default_background_color = Color(0, 0, 0, 0)
var too_far_background_color = Color(1, .3, .3, .2)
var current_tile_background_color = Color(.3, .3, .6, .7)
var hovering = false
var pressing = false
var highlight_tile_color = Color(1, 1, .8, 1)
var path_highlight_tile_color = Color(.8, .8, 1, 1)
var too_far_tile_color = Color(1, .8, .8, 1)

var enm_highlight_tile_color = Color(1, .3, .3, 1)

var player_on_tile = false
var enm_on_tile = false
var custom_weight = false

### *******
var special = false # used to check for things links tile highlighting.
var water = false
var forest = false
var forest_path = false
var tags = []
###

### BUFFS/DEBUFFS
var difficult_terrain = false # flag, use for labeling, conditionals, etc.
#
var passthrough_defense = 0
var passthrough_attack = 0
var passthrough_atk_range = 0
var passthrough_damage = 0
var passthrough_vol = 0
var passthrough_hp = 0
var passthrough_move = 0
#
var end_and_start_turn_defense = 0
var end_and_start_turn_attack = 0
var end_and_start_turn_atk_range = 0
var end_and_start_turn_damage = 0
var end_and_start_turn_vol = 0
var end_and_start_turn_hp = 0
var end_and_start_turn_move = 0

var bonus_activated = false
var activated_by = [] # player and enm names, used to track who is allowed to get a bonus 
###

var description = ""
###

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func reset_vals():
	spawn_enemies = false
	player_on_tile = false
	spawn_player = false
	can_move = true
	passthrough_defense = 0
	passthrough_attack = 0
	passthrough_atk_range = 0
	passthrough_damage = 0
	passthrough_vol = 0
	passthrough_hp = 0
	passthrough_move = 0
#
	end_and_start_turn_defense = 0
	end_and_start_turn_attack = 0
	end_and_start_turn_atk_range = 0
	end_and_start_turn_damage = 0
	end_and_start_turn_vol = 0
	end_and_start_turn_hp = 0
	end_and_start_turn_move = 0
	special = false # used to check for things links tile highlighting.
	water = false
	forest = false
	forest_path = false
	enm_on_tile = false
	custom_weight = false
	tags = []

func map_tile_type(tile_type):
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	reset_vals()
	var weight =  float(meta.unccupied_tile_weight)
	
	if custom_weight:
		weight = custom_weight

	visible = true
	# $Sprite.set_texture(main.MOUNTAIN_TILE)
	if tile_type == "move" or tile_type == "" or not tile_type:
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.BASIC_TILE)
		end_and_start_turn_damage = 10
		tags.append("+10 Dmg")
	elif tile_type == "enemy spawn":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.ENEMY_SPAWN_TILE)
		#print('enemy spaw tile placen')
		tags.append("Enemy Spawn")
		end_and_start_turn_damage = 50
		end_and_start_turn_hp = 5
		tags.append("+30 Dmg")
		tags.append("+5 HP")
		spawn_enemies = true
	elif tile_type == "player spawn":
		l.level_astar.set_point_weight_scale(index, weight)
		tags.append("Player Spawn")
		end_and_start_turn_damage = 50
		end_and_start_turn_atk_range = 2
		tags.append("+30 Dmg")
		tags.append("+2 ATK Range")
		$Sprite.set_texture(main.PLAYER_SPAWN_TILE)
		print('player spawn tile place')
		spawn_player = true
		can_move = true
	elif tile_type == "water":
		if not custom_weight: weight = meta.difficult_terrain_weight
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.basic_water_tiles[rand_range(0, len(main.basic_water_tiles))])
		water = true
		special = true
		difficult_terrain = true
		end_and_start_turn_defense += 5
		end_and_start_turn_move -= 2
		tags.append("Water")
		tags.append("-2 Move")
		tags.append("Double Electricity Dmg")
		tags.append("-5 Defense")
		description += "Double Electricity attacks targeting this tile, -1 Move starting turn here."
	elif tile_type == "forest path":
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.FOREST_PATH_TILE_1)
		forest = true
		special = true
		forest_path = true
		end_and_start_turn_move += 4
		tags.append("Forest")
		tags.append("Special")
		tags.append("+2 Move")
		description = "+2 Move starting turn here."
	else:
		if not custom_weight: weight = meta.wall_tile_weight
		tags.append("Wall")
		l.level_astar.set_point_weight_scale(index, weight)
		$Sprite.set_texture(main.WALL_TILE)
		visible = false
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


func on_press():
	if pressing:
		return
	pressing = true

	var l = get_node("/root/level")
	if main.debug:
		for t in l.level_tiles:
			t.modulate = Color(1, 1, 1, 1)
			if not t.can_move:
				t.modulate = Color(.4, .4, .4, 1)
	move_or_attack()
	pressing = false


func _on_Button_pressed():
	on_press()


func move_or_attack():
	if not meta.player_turn or not get_node("/root").has_node("player"):
		return
	var p = get_node("/root/player")
	var has_enemy = false
	p.get_node("card").visible = false
	for enm in get_tree().get_nodes_in_group("enemies"):
		if main.checkIfNodeDeleted(enm) == false and enm.alive:
			enm.get_node("card").visible = false
			if self.index == enm.current_tile.index:
				has_enemy = true
				break
	if meta.player_turn and p.can_atk and has_enemy:
		for enm in get_tree().get_nodes_in_group("enemies"):
			if main.checkIfNodeDeleted(enm) == false and enm.alive and self.index == enm.current_tile.index:
				p.attack(enm, true, p.selected_attack)
				return
	if can_move and p.current_move_distance > 0 and not has_enemy:
		print("moving to a tile?")
		move_to_tile_on_press()


func move_to_tile_on_press():
	if not meta.player_turn or not get_node("/root").has_node("player"):
		return
	var p = get_node("/root/player")
	p.chosen_tile = self
	p.move()


func hover():
	if hovering or not meta.player_turn:
		return
	if not get_node("/root").has_node("player"):
		return
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	meta.hovering_on_something = true
	hovering = true

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
	#player.current_tile.z_index = 1
	player.current_tile.modulate = Color(1, 1, 1, 1)

	if self == player.current_tile:
		player.get_node("card").visible = true
	else:
		player.get_node("card").visible = false
	self.modulate = tile_hover_color
	#for n in neighbors:
	#	if n.can_move:
	#		n.z_index = 1
	var index_count = 0
	var scale_variant = .015
	var scale_var = .95
	var scale_var_default = .95
	
	# visualize attack range from the tile hovered over
	#for t in meta.get_adjacent_tiles_in_distance(self, player.current_atk_range):
	#	t.modulate = Color(1, .3, .5, 1)
	var should_break = false
	for p in point_path:
		for t in l.level_tiles:
			if p == t.index and t != player.current_tile:
				t.get_node("Sprite").modulate = Color(.9, .9, 1, 1)
				path.append(t)
				debug_idx_path.append(t.index)
				index_count += 1
				t.get_node("AnimationPlayer").stop()
				if len(path) > player.current_move_distance:
					t.modulate = too_far_tile_color
				elif len(path) == player.current_move_distance: # full move
					t.get_node("AnimationPlayer").play("wobble repeat")
					t.get_node("background").modulate = highlight_background_color
					t.modulate = highlight_tile_color
				else:
					t.get_node("AnimationPlayer").play("wobble")
					t.get_node("background").modulate = path_highlight_background_color
					t.modulate = path_highlight_tile_color
				break
			else:
				t.set_scale(Vector2(scale_var_default, scale_var_default))
	#z_index = index_count + 1
	tile_text += "\n"
	for i in range(0, len(tags)):
		tile_text += str(tags[i]) + (", " if len(tags) > 1 else " ")
		if i % 6 == 0:
			tile_text += "\n"
	
	#for enm in get_tree().get_nodes_in_group("enemies"):
	#	if main.checkIfNodeDeleted(enm) == false and enm.alive and enm.current_tile.index == index:
	#		enm.z_index = z_index + 5
	#		l.change_turn_display_name(enm)
	#		modulate = enm_highlight_tile_color
	#		get_node("background").modulate = enm_highlight_tile_color
	#		for t in enm.tiles_in_view:
	#			t.modulate = enm_highlight_tile_color
	l.get_node("text_overlay/tile_text").set_text(tile_text)
	
	for enm in get_tree().get_nodes_in_group("enemies"):
		if enm.alive and self != enm.current_tile:
			enm.get_node("card").visible = false
		else:
			enm.get_node("card").visible = true

		#if enm.alive and enm.current_opportunity_attacks > 0:
		#	var tiles_in_range = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.current_atk_range, enm.atk_tile_pattern_name)
		#	for t in tiles_in_range:
		#		t.modulate = Color(1, .4, .4, 1)


func exit_hover():
	meta.hovering_on_something = false
	if not get_node("/root").has_node("player"):
		return
	if not get_node("/root").has_node("level"):
		return
	meta.reset_graphics_and_overlays()
	hovering = false


func _on_Button_mouse_entered():
	hover()


func _on_Button_mouse_exited():
	exit_hover()


func _on_Button_button_up():
	print("in _on_Button_button_up in tile.gd")
	pass
	#on_press()
