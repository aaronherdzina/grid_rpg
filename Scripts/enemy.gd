extends Node2D

const IS_PLAYER = false
var enm_z_index = 6
var green = rand_range(0, 1)
var red = rand_range(0, 1)
var blue = rand_range(0, 1)
var speed = rand_range(350, 475)
var path = []
var start_movement = false
var target_pos = Vector2()
var target_tile = null
var current_tile = null
var processing_turn = false
var should_remove = false
var id = 0
var char_name = "Enemy"
var chasing_player = true
var atk_tile_pattern_name = "fill" # this should match to a conditional check in meta.get_adjacent_tiles_in_distance()
var char_type = meta.CAT_TYPE
var current_battle_move_distance = round(rand_range(2, 7))
var default_distance = current_battle_move_distance
var battle_move_debuff = 0
var current_move_distance = current_battle_move_distance

var health = 15
var default_health = 5
var current_battle_health = 50

var current_battle_attack = 1
var default_attack = 1
var battle_attack_debuff = 0
var current_attack = round(rand_range(1, 2))

var current_battle_damage = 3
var default_damage = 3
var current_damage = round(rand_range(1, 3))
var battle_damage_debuff = 0

var current_battle_defense = 0
var default_defense = 0
var battle_defense_debuff = 0
var current_defense = 0

var default_evasion = 0
var current_battle_evasion = 0
var current_evasion = 0
var battle_evasion_debuff = 0


var current_battle_atk_range = 1
var default_atk_range = 1
var current_atk_range = round(rand_range(.7, 2.8))
var view_range = 1
var view_type = "star"

var current_battle_toughness = 2
var current_toughness = 3
var default_toughness = 2
var battle_toughness_debuff = 0

var current_opportunity_attacks = 1
var default_opportunity_attacks = 1
var current_battle_opportunity_attacks = 1

var energy = 3
var default_energy = 3
var battle_energy_debuff = 0

var stealth = false
var can_attack = true
var processing_after_move = false


var passengers = 0
var passenger_limit = 20
var type_1_passengers = 0
var type_2_passengers = 0
var type_3_passengers = 0
var type_4_passengers = 0
var type_5_passengers = 0
var type_6_passengers = 0
var type_7_passengers = 0
var type_8_passengers = 0


var control_cam = false
var alive = true

var noise = 2
var stealth_noise_val = 0
var stealth_dmg_bonus = 0
var stealth_dmg_mod = 1.2

var ending_move_tile = null

var tiles_in_view = []
var atk_anim_delay = .6
var between_atk_delay = 1
var player = null

var facing_dir = "fl_"
var can_atk = true
var current_pt_dmg = 0
var current_pt_range = 0

var chosen_skill_atk_range = 0
var chosen_skill = "melee_skill_1_push"

var stats = {
	classes.STRENGTH_STAT: 1,
	classes.SPEED_STAT: 1,
	classes.REASON_STAT: 1
}



func _ready():
	pass


func spawn(spawn_tile):
	randomize()
	green = rand_range(0, rand_range(.1, 1))
	red = rand_range(0, rand_range(.1, 1))
	blue = rand_range(0, rand_range(.1, 1))
	should_remove = false
	spawn_tile.map_tile_type(meta.SPAWN_ENEMY_TYPE)
	spawn_tile.enm_on_tile = true
	alive = true
	visible = true
	target_tile = spawn_tile
	spawn_tile.current = true
	set_spawn_tile(spawn_tile)
	set_tile_target(spawn_tile)
	add_to_group("enemies")
	meta.map_char(char_type, self)
	set_process(true)


func show_card():
	$card.visible = true
	current_tile.z_index = z_index + current_tile.base_index + 1


func hide_card():
	$card.visible = false
	current_tile.z_index = current_tile.base_index


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
	current_tile = target_node
	position = target_node.global_position
	current_tile.set_popout_details()


func check_if_player_attackable():
	#var player = get_node("/root/player")
	if not can_atk:
		return
	if not player or main.checkIfNodeDeleted(player) == true or current_attack <= 0:
		return false
	var tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, current_atk_range+chosen_skill_atk_range, atk_tile_pattern_name)
	var player_in_atk_range = false
	
	for t_in_v in tiles_in_view:
		if t_in_v.index == player.current_tile.index:
			player_in_atk_range = true
	return player_in_atk_range and current_attack > 0 and not player.stealth and not player.invisible


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
		if l.level_astar.get_point_weight_scale(p) >= meta.max_weight:
			return
		for t in l.level_tiles:
			if p == t.index and t.can_move:
				path.append(t)
				debug_idx_path.append(t.index)
			if len(path) > current_move_distance:
				break
		if len(path) > current_move_distance:
			break
	#print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]
		ending_move_tile = path[-1]


func start_turn():
	# start turn
	meta.reset_char_sprite_pos($Sprite)
	player = get_node("/root/player")
	meta.set_turn_order_info()
	processing_turn = true
	$cam_body/cam.zoom = player.get_node("cam_body/cam").zoom
	control_cam = true
	get_node("/root/level").attach_text_overlay($cam_body/cam, true)
	handle_overheard_text(char_name + " Thinking...")
	#if energy <= 0:
	meta.set_default_round_stats(self)
	#meta.set_new_turn_stats(self)
	view_range = floor(current_battle_move_distance) # current_atk_range
	current_tile.enm_on_tile = false
	meta.set_end_and_start_turn_tile_based_details(self, current_tile)
	$cam_body/cam.position = Vector2(0, 0)
	$cam_body/cam.current = true
	$card.visible = true

	var timer = main.make_timer(.2)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	var l = get_node("/root/level")
	var default_weight =  meta.unccupied_tile_weight if current_tile.can_move else meta.wall_tile_weight
	l.level_astar.set_point_weight_scale(current_tile.index, default_weight)
	var tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, view_range)
	for tile_in_view in tiles_in_view:
		if tile_in_view.index == player.current_tile.index:
			chasing_player = true
			break
	# process turn
	# consider delay to move animations
	handle_overheard_text(char_name, false)
	if chasing_player and check_if_player_attackable() and rand_range(0, 1) >= .4:
		for atks in current_attack:
			z_index = enm_z_index + 5
			handle_overheard_text(char_name + " Attacking...", true)
			enm_specific_attack_details()
			
	
			var t = main.make_timer(atk_anim_delay)
			t.start()
			yield(t, "timeout")
			t.queue_free()

			meta.attack(self, player)
			handle_overheard_text(char_name, false)

			var timer1 = main.make_timer(between_atk_delay)
			timer1.start()
			yield(timer1, "timeout")
			timer1.queue_free()
		var skills = ["melee_skill_1_push", "wrestler_skill_1_throw", "wrestler_skill_2_swap"]
		classes.ready_skill(self, skills[rand_range(0, len(skills))])
		classes.call(chosen_skill, player, self, stats, meta.player_stats)
		stop_turn("start_turn")
		z_index = enm_z_index
	else:
		move()
	#######

	# after turn


func handle_overheard_text(new_text, is_on=true):
	var final_text = ""
	var player_name = get_node("/root/player").char_name
	if chasing_player:
		final_text = char_name + " - TRACKING " + str(player_name) + "\n" + new_text
	else:
		final_text = new_text
	$Sprite2.visible = is_on
	$Label.set_text(final_text)
	$Label.visible = is_on


func enm_specific_attack_details():
	$AnimationPlayer.play("ranged_attack")


func reset_can_atk():
	var timer = main.make_timer(.3)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	can_atk = true


func validate_enm_for_turn():
	if health <= 0:
		if alive or visible:
			defeat_enemy()


func defeat_enemy():
	print("remove enm from defeat_enemy")
	# remove from play but don't free the instance
	var l = get_node("/root/level")
	alive = false
	$card.modulate = Color(0, 0, 0, 0)
	if current_tile:
		l.level_astar.set_point_weight_scale(current_tile.index, meta.unccupied_tile_weight)
		current_tile.enm_on_tile = false
		current_tile = null
	should_remove = true
	
	$AnimationPlayer.stop()
	$AnimationPlayer.play(facing_dir + "knockback")


func remove_enemy(vol_range=0):
	#print("remove enm?")
	if alive:
		alive = false
	visible = false
	queue_free()


func stop_turn(stop_callee):
	# astar set point of current tile to
	meta.reset_char_sprite_pos($Sprite)
	#print("stopping turn in " + str(self.name) + " from func " + str(stop_callee))
	var l = get_node("/root/level")
	l.level_astar.set_point_weight_scale(current_tile.index, meta.occupied_tile_weight)
	current_tile.enm_on_tile = true
	start_movement = false
	tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, view_range, view_type)

	var nearby_tile = meta.get_closest_adjacent_tile(self, current_tile, (not chasing_player), false)
	var tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, view_range)
	for tile_in_view in tiles_in_view:
		if tile_in_view.index == player.current_tile.index:
			chasing_player = true
			break
	handle_overheard_text(char_name, false)
	var timer1 = Timer.new()
	timer1.set_wait_time(.75)
	timer1.set_one_shot(true)
	get_node("/root").add_child(timer1)
	timer1.start()
	yield(timer1, "timeout")
	timer1.queue_free()
	if path.size() > 0:
		current_tile = path[len(path) -1 ]
		path = []
	if current_tile:
		position = current_tile.global_position
	#$Sprite.position = Vector2(0, 0)
	handle_overheard_text(char_name, false)
	meta.reset_graphics_and_overlays()
	processing_turn = false
	processing_after_move = false
	$card.visible = false
	$cam_body/cam.current = false



func is_player_in_vision_range():
	var player = get_node("/root/player")
	for n in current_tile.neighbors:
		if not player.invisible:
			if n.index == player.current_tile.index:
				#print("player near " + char_name + " on tile " + str(n.index))
				chasing_player = true
				break
			elif chasing_player:
				# check double neighbors when CONTINUING CHASE
				for next_n in n.neighbors:
					if n.index == player.current_tile.index or\
					   next_n.index == player.current_tile.index:
						chasing_player = true
						break
		if chasing_player:
			break

	return [chasing_player]

func move():
	#var player = get_node("/root/player")
	var nearby_tile = meta.get_closest_adjacent_tile(self, current_tile, (not chasing_player), false)
	var tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, view_range)
	for tile_in_view in tiles_in_view:
		if tile_in_view.index == player.current_tile.index:
			chasing_player = true
			break

	if chasing_player:
		handle_overheard_text(char_name, true)
		modulate = Color(1, .8, .8, 1)
		#print('chasing player')
		player.get_node("cam_body/cl/overlays and underlays/stealth_overlay").visible = false
		player.get_node("cam_body/cl/overlays and underlays/chased_overlay").visible = true
		nearby_tile = meta.get_closest_adjacent_tile(self, player.current_tile)
	else:
		handle_overheard_text(char_name + " Moving...", true)
		modulate = Color(1, 1, 1, 1)
	set_scale(Vector2(1, 1))
	set_tile_target(nearby_tile if nearby_tile else current_tile)
	set_navigation()
	start_movement = true


func take_damage(attacker, attack_details):
	print("calling old take dmg in enm script")
	return


func set_passthrough_tile_based_details(t):
	meta.set_passthrough_tile_based_details(self, t)


func set_next_current_tile(tile):
	if path[0] != current_tile and tile != current_tile: # ensure we don't count starting tile
		# meta.check_if_in_op_atk_range(self)
		current_move_distance -= 1
		current_tile = tile
		position = current_tile.global_position
		set_passthrough_tile_based_details(tile)
		if not player.stealth:
			var tiles_in_view = meta.get_adjacent_tiles_in_distance(current_tile, view_range)
			for tile_in_view in tiles_in_view:
				if tile_in_view.index == player.current_tile.index:
					chasing_player = true
		meta.check_if_in_pt_atk_range(self)
	path[0].enm_on_tile = false
	path.remove(0)
	if len(path) > 0:
		$AnimationPlayer.play("wireframe_" + meta.set_char_anims(self, "move", current_tile, path[0]))
		if current_tile:
			current_tile.enm_on_tile = true
			current_tile.set_popout_details()

func handle_movement_animations(delta):
	if alive and not meta.player_turn and start_movement:
		var should_stop_path = false
		if len(path) > 0:
			# meta.check_if_in_op_atk_range(self)
			var d = self.global_position.distance_to(path[0].global_position)
			if d > 4:
				position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
			else:
				set_next_current_tile(path[0])
				if len(path) > 0:
					for enm in get_tree().get_nodes_in_group("enemies"):
						if enm != self and enm.current_tile and enm.current_tile.index == path[0].index:
							should_stop_path = true
							break
					if player.current_tile and path[0].index == player.current_tile.index:
						should_stop_path = true
						# if our next move would be the same as the player's stop and end move
				else:
					should_stop_path = true
				if should_stop_path:
					path = []
				####
				#MAKE FUNC TO END MOVE AND SNAP PLAYER TO TILE TO CALL WHEN TURN ENDS
				#TO ENSURE CONSISTENT AI MOVEMENT
		else:
			if not processing_after_move:
				processing_after_move = true
				if chasing_player and check_if_player_attackable():
					#var player = get_node("/root/player")
					for atks in current_attack:
						handle_overheard_text(char_name + " Attacking...", true)
						enm_specific_attack_details()
						var atk_anim_timer = Timer.new()
						atk_anim_timer.set_wait_time(atk_anim_delay)
						atk_anim_timer.set_one_shot(true)
						get_node("/root").add_child(atk_anim_timer)
						atk_anim_timer.start()
						yield(atk_anim_timer, "timeout")
						atk_anim_timer.queue_free()
						var did_atk_hit = meta.attack(self, player)
						handle_overheard_text(char_name, false)
						
						if did_atk_hit:
							if player.alive:
								player.is_player_stealth(1)
						var timer1 = Timer.new()
						timer1.set_wait_time(between_atk_delay)
						timer1.set_one_shot(true)
						get_node("/root").add_child(timer1)
						timer1.start()
						yield(timer1, "timeout")
						timer1.queue_free()
				stop_turn("_process") # does not handle attacking or anything yet


func _process(delta):
	# note the path is a list of actual tiles 
	if control_cam and not meta.player_turn:
		var lvl = get_node("/root/level")
		lvl.attach_text_overlay($cam_body/cam, true)
		#lvl.get_node("text_overlay").position = Vector2(self.global_position.x + lvl.text_x_buffer, self.global_position.y + lvl.text_y_buffer)
	if processing_turn:
		handle_movement_animations(delta)


func _on_AnimationPlayer_animation_finished(anim_name):
	if "knockback" in anim_name and alive:
		#print("facing is " + str(facing_dir) + "stand_up")
		$AnimationPlayer.play(str(facing_dir) + "stand_up")
	meta.reset_char_sprite_pos($Sprite)
