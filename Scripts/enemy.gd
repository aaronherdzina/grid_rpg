extends Node2D

var speed = rand_range(300, 450)
var path = []
var target_pos = Vector2()
var target_tile = null
var current_tile = null
var processing_turn = false
var id = 0
var char_name = "Enemy"
var chasing_player = false

var move_distance = round(rand_range(2, 5))
var health = 4
var starting_turn_health = 4
var attack = 1
var damage = 3
var defense = 0
var can_attack = true
var energy = 3

var default_energy = 3
var default_attack = 1
var default_damage = 3
var default_defense = 0
var default_distance = move_distance
var remaining_move = default_distance

var battle_energy_debuff = 0
var battle_attack_debuff = 0
var battle_damage_debuff = 0
var battle_defense_debuff = 0
var battle_move_debuff = 0

var alive = true

func set_default_stats():
	attack = default_attack - battle_attack_debuff
	damage = default_damage - battle_damage_debuff
	defense = default_defense - battle_defense_debuff
	move_distance = default_distance - battle_move_debuff
	energy = default_energy - battle_energy_debuff
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
		if l.level_astar.get_point_weight_scale(p) >= meta.max_weight:
			return
		for t in l.level_tiles:
			if p == t.index and t.can_move:
				path.append(t)
				debug_idx_path.append(t.index)
			if len(path) > move_distance:
				break
		if len(path) > move_distance:
			break
	#print('debug_idx_path is ' + str(debug_idx_path) + ' made from start' + str(current_tile.index) + ' to '  + str(target_tile.index) + ' with point array ' + str(point_path))
	if path.size() > 0:
		current_tile = path[0]


func start_turn():
	# start turn
	if energy <= 0:
		set_default_stats()
	var l = get_node("/root/level")
	var default_weight =  meta.unccupied_tile_weight if current_tile.can_move else meta.wall_tile_weight
	l.level_astar.set_point_weight_scale(current_tile.index, default_weight)
	current_tile.enm_on_tile = false
	# process turn
	# consider delay to move animations
	move()
	#######

	# after turn

func remove_enemy():
	var l = get_node("/root/level")
	alive = false
	l.level_astar.set_point_weight_scale(current_tile.index, meta.unccupied_tile_weight)
	current_tile.enm_on_tile = false
	$Sprite.visible = false
	current_tile = null


func stop_turn():
	# astar set point of current tile to
	var l = get_node("/root/level")
	l.level_astar.set_point_weight_scale(current_tile.index, meta.occupied_tile_weight)
	current_tile.enm_on_tile = true
	processing_turn = false


func move():
	var player = get_node("/root/player")
	var nearby_tile = meta.get_closest_adjacent_tile(self, current_tile, (not chasing_player), false)
	chasing_player = false
	for n in current_tile.neighbors:
		if not chasing_player:
			if n.index == player.current_tile.index:
				chasing_player = true
		else:
			# check double neighbors when CONTINUING CHASE
			for next_n in n.neighbors:
				if n.index == player.current_tile.index or\
				   next_n.index == player.current_tile.index:
					break

	if chasing_player:
		print('chasing player')
		nearby_tile = meta.get_closest_adjacent_tile(self, player.current_tile)
	else:
		print('nearby_tile: ' + str(nearby_tile))
	set_tile_target(nearby_tile if nearby_tile else current_tile)
	set_navigation()


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
	health -= dmg
	print(attacker.char_name + ' attacked ' + char_name + ' for ' + str(attack_details["damage"]))
	if health <= 0:
		remove_enemy()


func _process(delta):
	# note the path is a list of actual tiles 
	if alive:
		if path.size() > 0:
			var d = self.global_position.distance_to(path[0].global_position)
			if d > 10:
				position = self.global_position.linear_interpolate(path[0].global_position, (speed * delta)/d)
			else:
				var player = get_node("/root/player")
				current_tile = path[0]
				position = current_tile.global_position
				path.remove(0)
				var stop_path = false
				if len(path) > 0:
					for enm in get_tree().get_nodes_in_group("enemies"):
						if enm != self and enm.current_tile and enm.current_tile.index == path[0].index:
							stop_path = true
							break
					if player.current_tile and path[0].index == player.current_tile.index:
						stop_path = true
						# if our next move would be the same as the player's stop and end move
				else:
					stop_path = true
				if stop_path:
					path = []
		else:
			stop_turn() # does not handle attacking or anything yet
