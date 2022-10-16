extends Node2D

const FOLLOW_SPEED = 900
const IS_PLAYER = true

var char_type = "dog"
var show_overlay = false
var speed = rand_range(300, 500)
var char_name = "Player"
var path = []
var target_pos = Vector2()
var target_tile = null
var current_tile = null
var chosen_tile = null
var turn_start_tile = null
var previous_tile = null
var moving = false
var current_battle_move_distance = 8
var current_move_distance = 8
var health = 15
var default_health = 5
var current_battle_health = 50
var processing_turn = false
var stealth = true
var invisible = false
var player_cam_clamp_distance = 200
var can_move_cam = true
var cam_vel = Vector2(0, 0)
var noise = 2
var cam_free_move = false
var current_battle_attack = 2
var current_battle_atk_range = 1
var current_battle_damage = 1
var stealth_noise_val = 1
var stealth_dmg_bonus = 1
var stealth_dmg_mod = 1.2
var current_battle_defense = 0
var can_attack = true
var energy = 3
var cam_node_pos = self.position
var selected_attack = meta.standard_atk_type
var current_battle_toughness = 2
var current_toughness = 3
var default_toughness = 2
var battle_toughness_debuff = 0

var default_evasion = 0
var current_battle_evasion = 0
var current_evasion = 0
var battle_evasion_debuff = 0
var default_energy = 3
var default_atk_range = 1
var default_attack = 2
var default_damage = 2
var default_defense = 0
var default_distance = 8
var current_opportunity_attacks = 2
var current_battle_opportunity_attacks = 1
var battle_opportunity_attacks = 1
var battle_energy_debuff = 0
var battle_attack_debuff = 0
var battle_damage_debuff = 0
var battle_defense_debuff = 0
var battle_move_debuff = 0
var alive = true
var mouse_follow_pos = Vector2(0, 0)
var current_attack = 2
var current_damage = 2
var current_defense = 0
var current_atk_range = 1

var facing_dir = "br_"
var char_power = 10 # throw strength & distance, item cary max, wrestle, melee dmg bonus
var char_agil = 8 # move speed, 
var char_tech = 6 # char energy max, ranged dmg donus, 
var char_weaponry = 7 # atks, atk range sometimes, dmg

var can_atk = true
var current_pt_dmg = 0
var current_pt_range = 0

var passengers = []
var passenger_atk_bonus = 0
var passenger_atk_range_bonus = 0
var passenger_dmg_bonus = 0
var passenger_move_bonus = 0
var passenger_health_bonus = 0
var passenger_defense_bonus = 0

var chosen_skill_atk_range = 5
var chosen_skill = classes.MELEE_SKILL_PUSH
var skills = [classes.MELEE_SKILL_PUSH, 
			 classes.WRESTLER_SKILL_THROW, classes.WRESTLER_SKILL_SWAP,
			 classes.SHAPER_SKILL_DIRT_SWEEP]
var skill_btns = []

# when energy runs out buff are removed and we set to our default stats
func reset_energy_based_stats():
	current_attack = default_attack
	current_damage = default_damage
	current_defense = default_defense
	current_atk_range = default_atk_range
	current_move_distance = default_distance
	energy = default_energy
	if energy < 1:
		energy = 1
	if current_battle_move_distance < 0:
		current_battle_move_distance = 0
	if current_battle_defense < 0:
		current_battle_defense = 0
	if current_battle_attack < 0:
		current_battle_attack = 0
	if current_battle_damage < 0:
		current_battle_damage = 0
	if current_battle_atk_range < 0:
		current_battle_atk_range = 0


func _ready():
	if get_node("/root").has_node("Camera2D"):
		get_node("/root/Camera2D").current = false
	set_process(true)


func attack(target, should_move=true, attack_name="standard"):
	""" Check tile, see if enemy is there and we are in range, if so attack (keep
		stats if we want to undo the attack) ELSE do the move to tile stuff
	"""
	randomize()

	if not meta.is_target_in_range(self, target):
		return
	#	chosen_tile = target.current_tile
	#	move()
	 
	#target, self, meta.player_stats, target.stat)
	#classes.melee_skill_1_push(target, self, meta.player_stats, target.stats)
	#classes.wrestler_skill_1_throw(target, self, meta.player_stats, target.stats)
	#classes.wrestler_skill_2_swap(target, self, meta.player_stats, target.stats)
	
	var skill = skills[rand_range(0, len(skills))]
	
	classes.ready_skill(self, chosen_skill)
	classes.call(chosen_skill, target, self, meta.player_stats, target.stats)
	var timer = main.make_timer(.5)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	can_atk = true
	var did_atk_hit = meta.attack(self, target, true, attack_name)
	if did_atk_hit:
		if target.alive:
			if not is_player_stealth(0):
				target.chasing_player = true


func is_player_stealth(vol_mod=0):
	var is_stealth = stealth
	var vol_range = noise
	if stealth: 
		vol_range -= stealth_noise_val
	
	var attack_noise_range = meta.get_adjacent_tiles_in_distance(current_tile, vol_range, "fill")
	for tile in attack_noise_range:
		tile.modulate = Color(1, .1, .1, 1)
		for enm in get_tree().get_nodes_in_group("enemies"):
			if enm.alive and tile.index == enm.current_tile.index:
				is_stealth = false
	if invisible: is_stealth = true
	return is_stealth


func set_tile_target(target_node):
	var l = get_node("/root/level")
	if not target_node.can_move:
		target_tile = meta.get_closest_adjacent_tile(self, target_node)
		if target_tile:
			target_pos = target_tile.global_position
			return

	target_tile = target_node
	target_pos = target_node.global_position


func reset_player():
	handle_start_and_reset_vars()
	var l = get_node("/root/level")
	handle_start_and_reset_vars()
	turn_start_tile = l.get_spawn_tile()
	current_tile = turn_start_tile
	position = turn_start_tile.global_position
	chosen_tile = turn_start_tile
	target_pos = turn_start_tile.global_position


func set_spawn_tile(target_node):
	position = target_node.global_position
	target_node.picked_for_spawn = true
	current_tile = target_node
	chosen_tile = target_node
	turn_start_tile = target_node
	target_pos = target_node.global_position
	current_tile.map_tile_type(meta.GRASS_TYPE)


func set_navigation():
	if not target_tile or not current_tile:
		return
	var l = get_node("/root/level")
	var point_path = l.level_astar.get_id_path(current_tile.index, target_tile.index)
	path = []
	var debug_idx_path = []
	print('debug_idx_path is ' + str(debug_idx_path) + ' made from start ' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	# WE seem to be adding path tile nodes in wrong order compared to astar point array
	# we probably want to do this and just correct though then we have reference to the tile too

	for p in point_path:
		if l.level_astar.get_point_weight_scale(p) >= meta.max_weight:
			return
		for t in l.level_tiles:
			if p == t.index and t.can_move and not t.tile_has_enm():
				path.append(t)
				debug_idx_path.append(t.index)
				break
			if len(path) > current_move_distance:
				break
		if len(path) > current_move_distance:
			break

	print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]
		#path[0].modulate = Color(0, 0, .5, 1)
		#path[-1].modulate = Color(1, 1, 0, 1)


func handle_start_and_reset_vars():
	if moving:
		moving = false


func set_skill_btn_position():
	var i = 1
	var width = 100
	for btn in get_tree().get_nodes_in_group("skill_btns"):
		if btn and main.checkIfNodeDeleted(btn) == false:
			btn.queue_free()
	skill_btns = []
	for s in skills:
		var sbs = main.skill_btn_scene.instance()
		get_node("cam_body/cl").add_child(sbs)
		sbs.set_button(s)
		skill_btns.append(sbs)
		sbs.position = $cam_body/cl/card/skills/start_pos.global_position
		if sbs.skill == chosen_skill:
			sbs.modulate = sbs.set_skill_clr
		if i != 1:
			sbs.position.x += (width * i)
		i += 1


func hold_skill_btn_position():
	var i = 1
	var n = 0
	var width = 150
	var height = 100
	var amnt_in_row = 1
	return
	for sb in skill_btns:
		sb.position = $cam_body/cl/card/skills/start_pos.global_position
		if i != 1 and amnt_in_row % 3 != 0:
			sb.position.x += (width * amnt_in_row)
		if i % 3 == 0:
			n += 1
			amnt_in_row = 1
			
		sb.position.y += (height * n) if n != 0 else 0
		i += 1
		amnt_in_row += 1

func reset_turn():
	path = []
	health = current_battle_health
	current_tile = turn_start_tile
	position = turn_start_tile.global_position
	chosen_tile = turn_start_tile
	target_pos = turn_start_tile.global_position
	handle_start_and_reset_vars()


func reset_can_atk():
	var timer = main.make_timer(.3)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	can_atk = true



func start_turn():
	# start turn
	#if energy <= 0:
	#	reset_energy_based_stats()
	meta.reset_char_sprite_pos($Sprite)
	#meta.set_new_turn_stats(self)
	meta.set_default_round_stats(self)
	meta.set_end_and_start_turn_tile_based_details(self, current_tile)
	var l = get_node("/root/level")
	var default_weight =  meta.unccupied_tile_weight if current_tile.can_move else meta.wall_tile_weight
	l.level_astar.set_point_weight_scale(current_tile.index, default_weight)
	for t in l.level_tiles:
		t.pressing = false
	current_tile.player_on_tile = false
	turn_start_tile = current_tile
	handle_start_and_reset_vars()
	$cam_body.position = Vector2(0, 0)
	$cam_body/cam.current = true
	$cam_body/cam.visible = true


func stop_turn():
	meta.reset_char_sprite_pos($Sprite)
	meta.reset_graphics_and_overlays()
	var l = get_node("/root/level")
	l.level_astar.set_point_weight_scale(current_tile.index, meta.occupied_tile_weight)
	processing_turn = false
	meta.set_end_and_start_turn_tile_based_details(self, current_tile)
	current_tile.player_on_tile = true
	$cam_body/cam.visible = false
	meta.hovering_on_something = false


func move():
	if not chosen_tile or chosen_tile == current_tile:
		return
	if current_move_distance > 0:
		set_tile_target(chosen_tile)
		set_navigation()
		moving = true
	else:
		moving = false


func move_cam(dir):
	if main.shaking or not can_move_cam and dir != "stop" or not meta.player_turn:
		return

	print("in move_cam(), dir="+str(dir))
		
	if "up" in dir:
		mouse_follow_pos = Vector2(0, -1)
		#can_move_cam = true
		#cam_vel.y = -1
	elif "down" in dir:
		mouse_follow_pos = Vector2(0, 1)
		#can_move_cam = true
		#cam_vel.y = 1

	if "left" in dir:
		mouse_follow_pos = Vector2(-1, 0)
		#can_move_cam = true
		#cam_vel.x = -1
	elif "right" in dir:
		mouse_follow_pos = Vector2(1, 0)
		#can_move_cam = true
		#cam_vel.x = 1
	if  dir == "stop" and can_move_cam:
		mouse_follow_pos = Vector2(0, 0)
		return


	# $cam.position = self.position
func clamp_vector(vector, clamp_origin, clamp_length):
    var offset = vector - clamp_origin
    var offset_length = offset.length()
    if offset_length <= clamp_length:
        return vector
    return clamp_origin + offset * (clamp_length / offset_length)


func set_passthrough_tile_based_details(t):
	meta.set_passthrough_tile_based_details(self, t)


func update_passenger_bonuses(new_passenger=false):
	if new_passenger:
		for passenger in passengers:
			if new_passenger["type_name"] == passenger["type_name"]:
				passenger["amount"] += 1
				break
	# REMOVE THE BELOW STUFF (KEEP THE RETURN) MAKE A DIFF FUNC, PAASSENGER META?..
	# THAT IS CALLED WHEN SOMEONE LANDS ON THE TILE AND THEY CHOOSE TO "COLLECT" THE PASSENGER
	# SO THIS SHOULD INSTEAD UPDATE PLAYER VARs 
	# use passenger_details to se tile specifics and return to use those details 
	for passenger in passengers:
		for bonus_dict in passenger["bonuses"]:
			var bonus_val = bonus_dict["bonus_val"]
			var penalty_val = bonus_dict["penalty_val"]
	
			if bonus_dict["bonus_name"] == "atk":
				passenger_atk_bonus = bonus_val * passenger["amount"]
			elif bonus_dict["penalty_name"] == "atk":
				passenger_atk_bonus -= penalty_val
	
			elif bonus_dict["bonus_name"] == "atk_range":
				passenger_atk_range_bonus += bonus_val
			elif bonus_dict["penalty_name"] == "atk_range":
				passenger_atk_range_bonus -= penalty_val
	
			elif bonus_dict["bonus_name"] == "dmg":
				passenger_dmg_bonus += bonus_val
			elif bonus_dict["penalty_name"] == "dmg":
				passenger_dmg_bonus -= penalty_val
	
			elif bonus_dict["bonus_name"] == "move":
				passenger_move_bonus += bonus_val
			elif bonus_dict["penalty_name"] == "move":
				passenger_move_bonus -= penalty_val
	
			elif bonus_dict["bonus_name"] == "health":
				passenger_health_bonus += bonus_val
			elif bonus_dict["penalty_name"] == "health":
				passenger_health_bonus -= penalty_val
			
			elif bonus_dict["bonus_name"] == "defense":
				passenger_defense_bonus += bonus_val
			elif bonus_dict["penalty_name"] == "defense":
				passenger_defense_bonus -= penalty_val


func set_next_current_tile(tile):
	if path[0] != current_tile: # ensure we don't count starting tile
		# meta.check_if_in_op_atk_range()
		current_move_distance -= 1
		current_tile = tile
		position = current_tile.global_position
		set_passthrough_tile_based_details(tile)
		meta.check_if_in_pt_atk_range()
	path.remove(0)
	if moving and len(path) > 0:
		$AnimationPlayer.play("wireframe_" + meta.set_char_anims(self, "move", current_tile, path[0]))


func _physics_process(delta):
	if not mouse_follow_pos:
		return
	
	$cam_body.move_and_slide(mouse_follow_pos * FOLLOW_SPEED)


func _process(delta):
	# note the path is a list of actual tiles 
	#if meta.player_turn:
	if meta.player_turn:
		hold_skill_btn_position()
		#if not meta.hovering_on_something:
		get_node("/root/level").handle_turn_order_display()
		if moving:
			$cam_body.position = $Sprite.position
			if path.size() > 0:
				if not path[0].can_move:
					path = []
					return
				# meta.check_if_in_op_atk_range()
				var d = self.global_position.distance_to(path[0].global_position)
				if d > 4:
					position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
				else:
					if path[0] != current_tile: # ensure we don't count starting tile
						current_move_distance -= 1
					set_next_current_tile(path[0])
					var stop_path = false
					if len(path) > 0:
						if not path[0].can_move:
							stop_path = true
						for enm in get_tree().get_nodes_in_group("enemies"):
							if main.checkIfNodeDeleted(enm) == false and enm.alive and enm.current_tile and enm.current_tile.index == path[0].index:
								stop_path = true
								break
							# if our next move would be the same as the player's stop and end move
					else:
						stop_path = true
					if stop_path:
						path = []
					#if len(path) > 1: # don't remove starting/current index
			elif moving:
				moving = false
				position = current_tile.global_position
	else:
		if len(get_node("/root/level").round_turns) > 0 and main.checkIfNodeDeleted(get_node("/root/level").round_turns[0]) == false:
			get_node("/root/level").handle_turn_order_display()


func _on_top_btn_mouse_entered():
	move_cam("up")


func _on_left_btn_mouse_entered():
	move_cam("left")


func _on_right_btn_mouse_entered():
	move_cam("right")


func _on_bottom_btn_mouse_entered():
	move_cam("down")


func _on_top_btn_mouse_exited():
	move_cam("stop")


func _on_left_btn_mouse_exited():
	move_cam("stop")


func _on_right_btn_mouse_exited():
	move_cam("stop")


func _on_bottom_btn_mouse_exited():
	move_cam("stop")


func _on_AnimationPlayer_animation_finished(anim_name):
	if "knockback" in anim_name or true:
		print("facing is " + str(facing_dir) + "stand_up")
		$AnimationPlayer.play(str(facing_dir) + "stand_up")
	meta.reset_char_sprite_pos($Sprite)


func _on_MenuButton_pressed():
	$cam_body/cl/card/MenuButton.add_skill_buttons(skills)
