extends Node2D

var speed = rand_range(300, 450)
var char_name = "Player"
var path = []
var target_pos = Vector2()
var target_tile = null
var current_tile = null
var chosen_tile = null
var turn_start_tile = null
var previous_tile = null
var moving = false
var move_distance = 3
var remaining_move = 3
var health = 10
var starting_turn_health = 10
var processing_turn = false

var attack = 2
var atk_range = 1
var damage = 3
var defense = 0
var can_attack = true
var energy = 3

var default_energy = 3
var default_atk_range = 1
var default_attack = 2
var default_damage = 3
var default_defense = 0
var default_distance = 3

var battle_energy_debuff = 0
var battle_attack_debuff = 0
var battle_damage_debuff = 0
var battle_defense_debuff = 0
var battle_move_debuff = 0
var alive = true


func set_default_stats():
	attack = default_attack
	damage = default_damage
	defense = default_defense
	move_distance = default_distance
	energy = default_energy
	if energy < 1:
		energy = 1
	if move_distance < 0:
		move_distance = 0
	if defense < 0:
		defense = 0
	if attack < 0:
		attack = 0
	if damage < 0:
		damage = 0
	if atk_range < 0:
		atk_range = 0


func _ready():
	set_process(true)


func attack(target):
	""" Check tile, see if enemy is there and we are in range, if so attack (keep
		stats if we want to undo the attack) ELSE do the move to tile stuff
	"""
	var is_in_attack_range = false
	var adjacent_tiles_in_range = meta.get_adjacent_tiles_in_distance(current_tile, atk_range, "fill")
	for tile in adjacent_tiles_in_range:
		if target.current_tile == tile:
			is_in_attack_range = true
			break

	if not is_in_attack_range:
		chosen_tile = target.current_tile
		move()
		return

	var attack_details = {
		"damage": damage
	}
	if attack > 0 and main.checkIfNodeDeleted(target) == false and target.alive:
		attack -= 1
		target.take_damage(self, attack_details)
		print('attacked!')


func take_damage(attacker, attack_details):
	var dmg = attack_details["damage"] 
	var hold_defense = defense

	if defense > 0:
		defense -= dmg
		dmg -= hold_defense
		if defense < 0:
			defense = 0

	if dmg < 0:
		dmg = 0
	health - dmg
	if health <= 0:
		alive = false


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
	chosen_tile = target_node
	turn_start_tile = target_node
	target_pos = target_node.global_position


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
			if p == t.index and t.can_move:
				path.append(t)
				debug_idx_path.append(t.index)
				break
			if len(path) > remaining_move:
				break
		if len(path) > remaining_move:
			break

	print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]
		#path[0].modulate = Color(0, 0, .5, 1)
		#path[-1].modulate = Color(1, 1, 0, 1)


func handle_start_and_reset_vars():
	if current_tile.forest_path:
		remaining_move += 2
	if moving:
		moving = false


func reset_turn():
	path = []
	health = starting_turn_health
	current_tile = turn_start_tile
	position = turn_start_tile.global_position
	chosen_tile = turn_start_tile
	target_pos = turn_start_tile.global_position
	handle_start_and_reset_vars()


func start_turn():
	# start turn
	if energy <= 0:
		set_default_stats()
	remaining_move = move_distance
	var l = get_node("/root/level")
	var default_weight =  meta.unccupied_tile_weight if current_tile.can_move else meta.wall_tile_weight
	l.level_astar.set_point_weight_scale(current_tile.index, default_weight)
	current_tile.player_on_tile = false
	turn_start_tile = current_tile
	handle_start_and_reset_vars()


func stop_turn():
	var l = get_node("/root/level")
	l.level_astar.set_point_weight_scale(current_tile.index, meta.occupied_tile_weight)
	processing_turn = false
	if current_tile.defense_buff > 0 and defense <= default_defense:
		default_defense += current_tile.defense_buff
		print('got forest bonus')
	current_tile.player_on_tile = true


func move():
	if remaining_move > 0:
		set_tile_target(chosen_tile)
		set_navigation()
		moving = true
	else:
		moving = false


func _process(delta):
	# note the path is a list of actual tiles 
	if meta.player_turn and moving:
		if path.size() > 0:
			if not path[0].can_move:
				path = []
				return
			var d = self.global_position.distance_to(path[0].global_position)
			if d > 10:
				position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
			else:
				if path[0] != current_tile: # ensure we don't count starting tile
					remaining_move -= 1
				current_tile = path[0]
				position = current_tile.global_position
				path.remove(0)
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
