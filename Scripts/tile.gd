extends Node2D

# debug stuff for testing nav
var tile_subtype = meta.EMPTY_TYPE
var tile_type = meta.EMPTY_TYPE
var is_end = false
var is_start = true
var can_move = false
var spawn_player = false
var spawn_enemies = false
var picked_for_spawn = false
var current = false
var base_index = 0
var has_item = false
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
var displaying_popout = false
var highlight_tile_color = Color(.8, .8, .5, 1)
var path_highlight_tile_color = Color(.8, .8, 1, 1)
var too_far_tile_color = Color(1, .8, .8, 1)
var previous_img = null
var enm_highlight_tile_color = Color(1, .3, .3, 1)
var change_this_turn = false
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

var n_top = null
var n_bottom = null
var n_left = null
var n_right = null
var n_bottom_left = null
var n_top_left = null
var n_top_right = null
var n_bottom_right = null
var description = ""
###


## passenger stuff
var tile_passenger = "none"

##

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
	can_move = false
	current = false
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

func set_grass(award_points=false, preview_only=false, player_pressed=false):
	randomize()
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	var sprite_choice = main.grass_pieces[rand_range(0, len(main.grass_pieces))]
	$AnimationPlayer.stop()
	
	$Sprite.set_texture(sprite_choice)
	visible = true
	$feature_sprite.visible = false
	can_move = true
	tile_type = meta.GRASS_TYPE
	tile_subtype = meta.GRASS_TYPE
	return [points, previous_texture]

func set_foliage_grass(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	var sprite_choice =  main.roads_pieces[rand_range(0, len(main.roads_pieces) - 1)]
	$AnimationPlayer.stop()
	$Sprite.set_texture(sprite_choice)
	visible = true
	$feature_sprite.visible = true
	can_move = true
	tile_type = meta.FOLIAGE_GRASS_TYPE
	tile_subtype = meta.GRASS_TYPE
	return [points, previous_texture]

func set_foliage_water(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.WATER_TILE_2)
	$feature_sprite.visible = true
	visible = true
	tile_type = meta.FOLIAGE_WATER_TYPE
	can_move = true
	tile_subtype = meta.WATER_TYPE
	return [points, previous_texture]

func set_foliage_dirt(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	can_move = true
	$Sprite.set_texture(main.dirt_road_pieces[rand_range(0, len(main.dirt_road_pieces))])
	visible = true
	$feature_sprite.visible = true
	tile_type = meta.FOLIAGE_DIRT_TYPE
	tile_subtype = meta.DIRT_TYPE
	return [points, previous_texture]

func set_overgrowth(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.GRASS_TILE_LARGE_ROCK)
	visible = true
	$feature_sprite.visible = false
	can_move = false
	tile_type = meta.OVERGROWN_GRASS_TYPE
	tile_subtype = meta.GRASS_TYPE
	return [points, previous_texture]

func set_water(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.WATER_TILE_1)
	visible = true
	can_move = false
	$feature_sprite.visible = false
	tile_type = meta.WATER_TYPE
	tile_subtype = meta.WATER_TYPE
	return [points, previous_texture]

func set_dirt(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.ROCKY_GROUND_TILE)#main.DIRT_TILE)
	visible = true
	$feature_sprite.visible = false
	spawn_enemies = true
	can_move = true
	tile_type = meta.DIRT_TYPE
	tile_subtype = meta.DIRT_TYPE
	return [points, previous_texture]

func set_grass_rock(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.GRASS_TILE_LARGE_ROCK)#main.DIRT_TILE)
	visible = true
	$feature_sprite.visible = false
	spawn_enemies = true
	can_move = true
	tile_type = meta.GRASS_TYPE_NO_MOVE
	tile_subtype = meta.GRASS_TYPE
	return [points, previous_texture]

func set_empty(award_points=false, preview_only=false, player_pressed=false):
	var points = 0
	var previous_texture = $Sprite.texture.resource_path
	$AnimationPlayer.stop()
	$Sprite.set_texture(main.SLATE_TILE)
	$feature_sprite.visible = false
	visible = false
	can_move = false
	tile_type = meta.EMPTY_TYPE
	tile_subtype = meta.EMPTY_TYPE
	return [points, previous_texture]


func map_tile_type(t_type, award_points=false, preview_only=false, player_pressed=false):
	if not get_node("/root").has_node("level") or not $Sprite.texture:
		set_grass()
		return
	var l = get_node("/root/level")
	reset_vals()
	var weight =  float(meta.unccupied_tile_weight)
	var tile_set_obj = []
	var points_awarded = 0
	if custom_weight:
		weight = custom_weight

	visible = true
	current = true
	if not t_type:
		# custom value not given default to global
		t_type = tile_type
	if t_type == meta.GRASS_TYPE:
		tile_set_obj = set_grass(award_points, preview_only, player_pressed)
	elif t_type == meta.WATER_TYPE:
		tile_set_obj = set_water(award_points, preview_only, player_pressed)
	elif t_type == meta.DIRT_TYPE:
		tile_set_obj = set_dirt(award_points, preview_only, player_pressed)
	elif t_type == meta.OVERGROWN_GRASS_TYPE:
		tile_set_obj = set_overgrowth(award_points, preview_only, player_pressed)
	elif t_type == meta.FOLIAGE_GRASS_TYPE:
		tile_set_obj = set_foliage_grass(award_points, preview_only, player_pressed)
	elif t_type == meta.FOLIAGE_DIRT_TYPE:
		tile_set_obj = set_foliage_dirt(award_points, preview_only, player_pressed)
	elif t_type == meta.FOLIAGE_WATER_TYPE:
		tile_set_obj = set_foliage_water(award_points, preview_only, player_pressed)
	else:
		tile_set_obj = set_empty(award_points, preview_only, player_pressed)

	points_awarded += tile_set_obj[0]
	previous_img = tile_set_obj[1]
	if preview_only and tile_type == meta.EMPTY_TYPE:
		change_this_turn = false
	elif not preview_only:
		change_this_turn = true
	if points_awarded != 0 and not preview_only and award_points:
		var point_text = main.DMG_EFFECT_SCENE.instance()
		get_node("/root").call_deferred("add_child", point_text)
		point_text.position = global_position
		point_text.set_new_text(str(points_awarded))
	var default_weight =  meta.unccupied_tile_weight if can_move else meta.wall_tile_weight
	if l.level_astar.has_point(index):
		l.level_astar.set_point_weight_scale(index, default_weight)
	set_popout_details()


func map_tile_type_by_neighbors(award_points=false, preview_only=false, player_pressed=false, skip_empty=false):
	var grass_amount = 0
	var water_amount = 0
	var dirt_amount = 0
	var empty_amount = 0
	var foliage_grass_amount = 0
	var foliage_water_amount = 0
	var foliage_dirt_amount = 0
	var overgrown_amount = 0
	var points_awarded = 0
	var tile_set_obj = []

	for t in neighbors:
		# keep priority in mind
		if !t.visible or !t.current:
			continue
		if t.tile_type == meta.GRASS_TYPE:
			grass_amount += 1
		elif t.tile_type == meta.WATER_TYPE:
			water_amount += 1
		elif t.tile_type == meta.DIRT_TYPE:
			dirt_amount += 1
		elif t.tile_type == meta.OVERGROWN_GRASS_TYPE:
			overgrown_amount += 1
		elif t.tile_type == meta.FOLIAGE_DIRT_TYPE:
			foliage_dirt_amount += 1
		elif t.tile_type == meta.FOLIAGE_GRASS_TYPE:
			foliage_grass_amount += 1
		elif t.tile_type == meta.FOLIAGE_WATER_TYPE:
			foliage_water_amount += 1
		else:
			empty_amount += 1
	if !skip_empty:
		if grass_amount >= 2 or foliage_grass_amount >= 3:
			tile_set_obj = set_grass_rock(award_points, preview_only, player_pressed)
		elif water_amount + grass_amount >= 6 or foliage_water_amount >= 4:
			tile_set_obj = set_foliage_water(award_points, preview_only, player_pressed)
		elif dirt_amount + grass_amount >= 6  or foliage_dirt_amount >= 4:
			tile_set_obj = set_foliage_grass(award_points, preview_only, player_pressed)
		elif grass_amount >= 2 and grass_amount > dirt_amount and water_amount >= 2 or overgrown_amount >= 3:
			tile_set_obj = set_overgrowth(award_points, preview_only, player_pressed)
			points_awarded += tile_set_obj[0]
		elif dirt_amount >= 1 and water_amount >= 1\
		   or grass_amount > dirt_amount:
			tile_set_obj = set_grass(award_points, preview_only, player_pressed)
			points_awarded += tile_set_obj[0]
		elif water_amount > grass_amount and water_amount > dirt_amount:
			tile_set_obj = set_water(award_points, preview_only, player_pressed)
			points_awarded += tile_set_obj[0]
		elif dirt_amount >= water_amount and dirt_amount >= grass_amount:
			tile_set_obj = set_dirt(award_points, preview_only, player_pressed)
			points_awarded += tile_set_obj[0]
		else:
			print("fallback set empty call")
			tile_set_obj = set_empty(award_points, preview_only, player_pressed)
			points_awarded += tile_set_obj[0]
	
		previous_img = tile_set_obj[1]
		if preview_only and tile_type == meta.EMPTY_TYPE:
			change_this_turn = false
		elif not preview_only:
			change_this_turn = true
		if points_awarded != 0 and not preview_only:
			var point_text = main.DMG_EFFECT_SCENE.instance()
			get_node("/root").call_deferred("add_child", point_text)
			point_text.position = global_position
			point_text.set_new_text(str(points_awarded))
	set_popout_details()

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


func set_tile_passenger_bonuses(p_dict):
	var passenger_details = {
		"type_name": p_dict["type_name"],
		"amount": p_dict["amount"],
		"bonuses": p_dict["bonuses"]
	}

	return passenger_details


func tile_has_enm():
	for enm in get_tree().get_nodes_in_group("enemies"):
		if enm.alive:
			if self.index == enm.current_tile.index:
				print("tile has enm")
				return enm
			else:
				enm.get_node("card").visible = false
	return null


func on_press():
	print("pressed tile " + str(index))
	# Not always seeing popout
	if pressing or not meta.player_turn:
		print("backing out of press. Pressing: " + str(pressing) + " player turn?: " + str(meta.player_turn))
		return
	
	var player = get_node("/root/player")
	if player.moving:
		return
	var l = get_node("/root/level")
	for t in l.level_tiles:
		t.pressing = false
	pressing = true
	var enm = tile_has_enm()
	if enm != null:
		enm.show_card()
	if not displaying_popout:
		meta.reset_graphics_and_overlays(false, self)
		displaying_popout = true
		set_popout_details()
		$popout_container.visible = true
		for enm in get_tree().get_nodes_in_group("enemies"):
			if enm.alive and self != enm.current_tile:
				enm.hide_card()
				if enm.current_tile:
					enm.current_tile.z_index = 0
		var timer = Timer.new()
		get_node("/root").add_child(timer)
		timer.set_wait_time(.1)
		timer.set_one_shot(true)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
		pressing = false
		return
	else:
		meta.reset_graphics_and_overlays(true, self)


	if main.debug:
		for t in l.level_tiles:
			t.modulate = Color(1, 1, 1, 1)
			if not t.can_move:
				t.modulate = Color(.4, .4, .4, 1)
	for t in l.level_tiles:
		meta.helpers_set_edge_tiles(t)

	var timer = Timer.new()
	timer.set_wait_time(.1)
	timer.set_one_shot(true)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	pressing = false


func _on_Button_pressed():
	on_press()


func move_or_attack():
	meta.reset_graphics_and_overlays()
	return
	if not meta.player_turn or not get_node("/root").has_node("player"):
		pressing = false
		return
	var p = get_node("/root/player")
	var has_enemy = false
	p.get_node("card").visible = false
	var has_enm = tile_has_enm()
	if has_enm:
		has_enemy = true
	if meta.player_turn and p.can_atk and has_enemy:
		for enm in get_tree().get_nodes_in_group("enemies"):
			if enm.alive and self.index == enm.current_tile.index:
				p.attack(enm, true, p.selected_attack)
				pressing = false
				return
	elif can_move and p.current_move_distance > 0 and not has_enemy:
		print("moving to a tile?")
		move_to_tile_on_press()
	pressing = false


func move_to_tile_on_press():
	var p = get_node("/root/player")
	p.chosen_tile = self
	p.move()


func set_tile_neighbor_nodes(list):
	# get top
	var offest_x = -1
	var offest_y = +1
	for tile in list:
		var indx = tile.index
		if indx - row > 0  + offest_x and indx - row  + offest_x < len(list):
			tile.n_top = list[indx - row + offest_x]
			#print(str(index) + " checking n_top " + str(tile.index))
		# get top right
		if indx - row + 1 + offest_x > 0 and indx - row + 1  + offest_x < len(list) and tile.row < row-1 + offest_x:
			tile.n_top_right = list[indx - row + 1 + offest_x]
			#print(str(index) + " checking n_top_right " + str(tile.index))
		# get top left
		if indx - row - 1  + offest_x> 0 and indx - row - 1 + offest_x< len(list) and tile.row > 1 + offest_x:
			tile.n_top_left = list[indx - row - 1 + offest_x]

		# get bottom
		if indx + row  + offest_y > 0 and indx + row + offest_y < len(list):
			tile.n_bottom = list[indx + row + offest_y]
		# get bottom right
		if indx + row + 1  + offest_y > 0 and indx + row + 1 + offest_y < len(list) and tile.row < row-1 + offest_y:
			tile.n_bottom_right = list[indx + row + 1 + offest_y]
		# get bottom left
		if indx + row - 1 + offest_y > 0 and indx + row - 1 + offest_y < len(list) and tile.row > 1 + offest_y:
			tile.n_bottom_left = list[indx + row - 1 + offest_y]

		# get right
		if indx + 1 > 0 and indx + 1 < len(list) and tile.row < row-1:
			tile.n_right = list[indx + 1]
		# get left
		if indx - 1 > 0 and indx - 1 < len(list) and tile.row > 1:
			tile.n_left = list[indx - 1]


func hover():
	if hovering or not meta.player_turn or pressing:
		return
	if not get_node("/root").has_node("player"):
		return
	if not get_node("/root").has_node("level"):
		return
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	if player.moving:
		return
	meta.hovering_on_something = true
	hovering = true
	set_popout_details()
	var point_path = l.level_astar.get_id_path(player.current_tile.index, index)
	var path = []
	var debug_idx_path = []
	var tile_hover_color = Color(.6, .6, 1, 1)

	var tile_text = "Tile " + str(index)

	if enm_on_tile:
		tile_hover_color = Color(1, .3, .3, 1)

	if not can_move:
		tile_hover_color = Color(.5, .5, .5, 1)
	player.current_tile.get_node("background").modulate = current_tile_background_color
	#player.current_tile.z_index = 1
	player.current_tile.modulate = Color(1, 1, 1, 1)

	#player.get_node("cam_body/card").visible = self == player.current_tile
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
				#t.get_node("Sprite").modulate = Color(.85, .85, 1, 1)
				path.append(t)
				debug_idx_path.append(t.index)
				index_count += 1
				if t.tile_type != meta.WATER_TYPE:
					t.get_node("AnimationPlayer").stop()
				if len(path) > player.current_move_distance:
					t.modulate = too_far_tile_color
				elif len(path) == player.current_move_distance: # full move
					#t.get_node("AnimationPlayer").play("wobble repeat")
					#t.get_node("background").modulate = highlight_background_color
					t.modulate = highlight_tile_color
					if t.tile_type != meta.WATER_TYPE:
						t.get_node("AnimationPlayer").play("wobble selected")
				else:
					if t.tile_type != meta.WATER_TYPE:
						t.get_node("AnimationPlayer").play("wobble")
					#t.get_node("background").modulate = path_highlight_background_color
					t.modulate = path_highlight_tile_color
				
			else:
				t.set_scale(Vector2(scale_var_default, scale_var_default))
				t.modulate = Color(1, 1, 1, 1)
	#z_index = index_count + 1
	tile_text += "\n"
	for i in range(0, len(tags)):
		tile_text += str(tags[i]) + (", " if len(tags) > 1 else " ")
		if i % 6 == 0:
			tile_text += "\n"

	for enm in get_tree().get_nodes_in_group("enemies"):
		if main.checkIfNodeDeleted(enm) == false and enm.alive:
			var enm_v_tiles = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.view_range)
			for enm_v_t in enm_v_tiles:
				if self != enm_v_t:
					if player.show_overlay:
						enm_v_t.modulate = Color(enm.red, enm.green, enm.blue, 1)
			if enm.current_tile.index == index:
	#		enm.z_index = z_index + 5
				l.change_turn_display_name(enm)
				enm.get_node("card").visible = true
	#		modulate = enm_highlight_tile_color
	#		get_node("background").modulate = enm_highlight_tile_color
	#		for t in enm.tiles_in_view:
	#			t.modulate = enm_highlight_tile_color
	if player and player.has_node("cam_body/cl/text_overlay_node"):
		player.get_node("cam_body/cl/text_overlay_node/tile_text").set_text(tile_text)
		#if enm.alive and enm.current_opportunity_attacks > 0:
		#	var tiles_in_range = meta.get_adjacent_tiles_in_distance(enm.current_tile, enm.current_atk_range, enm.atk_tile_pattern_name)
		#	for t in tiles_in_range:
		#		t.modulate = Color(1, .4, .4, 1)
		
	if main.debug:
		# neighbor validation
		if n_top:
			n_top.modulate = Color (1, .2, .2, 1)
		if n_left:
			n_left.modulate = Color (.2, 1, .2, 1)
		if n_right:
			n_right.modulate = Color (.2, .2, 1, 1)
		if n_bottom:
			n_bottom.modulate = Color (.2, .2, .2, 1)
		if n_bottom_left:
			n_bottom_left.modulate = Color (.2, .2, .2, .5)
		if n_top_left:
			n_top_left.modulate = Color (1, 1, .2, .5)
		if n_bottom_right:
			n_bottom_right.modulate = Color (.2, .2, 1, .5)
		if n_top_right:
			n_top_right.modulate = Color (1, .2, .2, .5)


func exit_hover():
	meta.hovering_on_something = false
	hovering = false
	if not get_node("/root").has_node("player"):
		return
	if not get_node("/root").has_node("level"):
		return
	meta.reset_graphics_and_overlays(true)


func _on_Button_mouse_entered():
	hover()


func _on_Button_mouse_exited():
	exit_hover()


func _on_Button_button_up():
	print("in _on_Button_button_up in tile.gd")
	if not pressing:
		pass
		#on_press()


func _on_Button_button_down():
	on_press()


func _on_top_btn_button_up():
	# MOVE
	if not meta.player_turn:
		print("player yurn? " + str(meta.player_turn))
		return
	var p = get_node("/root/player")
	var has_enemy = tile_has_enm()

	if can_move and p.current_move_distance > 0 and has_enemy == null:
		print("moving to a tile?")
		move_to_tile_on_press()
	print("can move?? " + str(can_move) + " " + str(p.current_move_distance) + " " + str(has_enemy))
	pressing = false
	meta.reset_graphics_and_overlays()


func _on_mid_btn_button_up():
	# attack/interact
	if not meta.player_turn:
		print("player yurn? " + str(meta.player_turn))
		return
	var p = get_node("/root/player")
	#p.get_node("cam_body/card").visible = false
	for enm in get_tree().get_nodes_in_group("enemies"):
		if enm.alive:
			enm.get_node("card").visible = false

	if meta.player_turn and p.can_atk:
		for enm in get_tree().get_nodes_in_group("enemies"):
			print("can attack?? " + str(p.can_atk) + " has_enemy:" + str(self.index == enm.current_tile.index) + " in range>? " + str(meta.is_target_in_range(p, enm)))
	
			if enm.alive and self.index == enm.current_tile.index\
			   and meta.is_target_in_range(p, enm):
				enm.get_node("card").visible = true
				p.attack(enm, true, p.selected_attack)
				break

	pressing = false

	meta.reset_graphics_and_overlays(false)

func set_popout_details(in_range=true):
	var has_enemy = false
	for enm in get_tree().get_nodes_in_group("enemies"):
		if enm.alive and enm.current_tile:
			enm.get_node("card").visible = false
			if self.index == enm.current_tile.index:
				has_enemy = true
				break
	$popout_container/top_btn/Label.visible = false
	$popout_container/mid_btn/Label.visible = false
	if has_enemy:
		$popout_container/top_btn/Label.set_text("")
		$popout_container/mid_btn/Label.set_text("Attack")
		$popout_container/btm_btn.set_text("Cancel")
		$popout_container/mid_btn/Label.visible = true
	elif has_item:
		$popout_container/top_btn/Label.set_text("")
		$popout_container/mid_btn/Label.set_text("Interact")
		$popout_container/btm_btn.set_text("Cancel")
		$popout_container/mid_btn/Label.visible = true
	elif in_range:
		$popout_container/top_btn/Label.set_text("Move")
		$popout_container/mid_btn/Label.set_text("")
		$popout_container/btm_btn.set_text("Cancel")
		$popout_container/top_btn/Label.visible = true
	else:
		$popout_container/top_btn/Label.set_text("")
		$popout_container/mid_btn/Label.set_text("")
		$popout_container/btm_btn.set_text("Cancel")


func _on_btm_btn_button_up():
	pressing = false
	meta.reset_graphics_and_overlays()
