extends Node

var char_names = ["Thief", "Brute", "Ranger", "Wizard", "Grunt"]

var current_level_cols = 10
var current_level_rows = 6
var default_level_cols = 10
var default_level_rows = 6
var player_turn = true
var max_weight =  999.0
var occupied_tile_weight = 1000.0 # 10000 is min to be unpassible 
var unccupied_tile_weight = 1.0
var difficult_terrain_weight = 2.0
var wall_tile_weight = 2000.0
var dangerous_terrain_weight = 5.0

var current_characters_idx = 0
var current_characters = []
var current_character_turn = null
var hovering_on_something = false
var can_spawn_level = true
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var course_1 = {
	"cols": 7,
	"rows": 9,
	"tile_list": ["enemy spawn", "move", "forest path", "move", "move", "move", "move",
				  "move", "water", "water", "wall", "move", "move", "wall",
				  "move", "water", "move", "move", "move", "move", "move",
				  "move", "water", "move", "enemy spawn", "wall", "move", "move",
				  "move", "water", "move", "move", "move", "", "move",
				  "move", "water", "move", "water", "water", "forest path", "move",
				  "enemy spawn", "wall", "move", "water", "water", "water", "move",
				  "move", "move", "move", "water", "water", "water", "move",
				  "move", "move", "move", "enemy spawn", "wall", "water", "player spawn",]
	}

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func fix_char_stat_min_vals(char_node):
	""" Ensure no character value goes below a game mechanic needed minimum 
		# energy=1
		# atk_range=1
		# 'other'=0
		# defense=No Limit (negtive defense results into additional dmg recieved)
	"""
	if char_node.energy < 1:
		char_node.energy = 1
	if char_node.current_battle_atk_range < 1:
		char_node.current_battle_atk_range = 1
	if char_node.current_battle_move_distance < 0:
		char_node.current_battle_move_distance = 0
	if char_node.current_battle_attack < 0:
		char_node.current_battle_attack = 0
	if char_node.current_battle_damage < 0:
		char_node.current_battle_damage = 0


func set_new_turn_stats(char_node):
	char_node.current_attack = char_node.current_battle_attack
	char_node.current_damage = char_node.current_battle_damage
	char_node.current_defense = char_node.current_battle_defense
	char_node.current_atk_range = char_node.current_battle_atk_range
	char_node.current_move_distance = char_node.current_battle_move_distance
	fix_char_stat_min_vals(char_node)


func set_end_and_start_turn_tile_based_details(char_node, tile):
	print("setting end/start turn buffs w/" + str(tile.description))
	char_node.current_atk_range += tile.end_and_start_turn_atk_range
	char_node.current_defense += tile.end_and_start_turn_defense
	char_node.current_attack += tile.end_and_start_turn_attack 
	char_node.current_damage += tile.end_and_start_turn_damage
	char_node.noise += tile.end_and_start_turn_vol
	char_node.health += tile.end_and_start_turn_hp
	char_node.current_move_distance += tile.end_and_start_turn_move


func set_passthrough_tile_based_details(char_node, tile):
	print("setting passthrough buffs w/" + str(tile.description))
	char_node.current_atk_range += tile.passthrough_atk_range
	char_node.current_defense += tile.passthrough_defense
	char_node.current_attack += tile.passthrough_attack 
	char_node.current_damage += tile.passthrough_damage
	char_node.noise += tile.passthrough_vol
	char_node.health += tile.passthrough_hp
	char_node.current_move_distance += tile.passthrough_move

func remove_enemies():
	for enm in get_tree().get_nodes_in_group("enemies"):
		enm.remove_enemy()

func reset_graphics_and_overlays():
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	l.get_node("text_overlay/tile_text").set_text("")
	for t in l.level_tiles:
		t.modulate = Color(1, 1, 1, 1)
		t.get_node("AnimationPlayer").stop()
		t.get_node("background").modulate = t.default_background_color
		t.get_node("Sprite").modulate = Color(1, 1, 1, 1)
		t.z_index = 0
	
	for enm in get_tree().get_nodes_in_group("enemies"):
		enm.z_index = 5
	l.change_turn_display_name(player)


func roll_dice(successes_needed=1, roll_target=3, dice=["../sprites/basic_die.png"], chosen_tile=null):
	var min_roll = 1
	var max_roll = 6
	var successes = 0
	var total_dice_val_difference = 0
# warning-ignore:unused_variable
	var player = get_node("/root/player")
	for die in dice:
		var result = die["values"][round(rand_range(0, len(die["values"]) - 1))]
		var accuracy_mod = 0
		if chosen_tile and accuracy_mod != 0:
			print(result)
			result += accuracy_mod
			print("adding accuradcy mod. Result: " + str(result))
		for tag in die["tags"]:
			if "+1 Accuracy" in tag:
				result += 1
			elif "-1 Accuracy" in tag:
				result -= 1
		if result < min_roll:
			result = min_roll
		if result > max_roll:
			result = max_roll
		die["roll_result"] = result

	for die in dice:
		if die["roll_result"] >= roll_target:
			successes += 1
		total_dice_val_difference = roll_target - die["roll_result"]

	return {"success": successes >= successes_needed, "hit_difference": total_dice_val_difference, "dice": dice}


func take_damage(attacker, attack_details, defender, is_player=false):
	var player = get_node("/root/player")
# warning-ignore:unused_variable
	var l = get_node("/root/level")
	var current_damage = attack_details["damage"] 
	var hold_defense = defender.current_defense
	if hold_defense < 0: hold_defense = 0
	if not is_player and not player.invisible:
		defender.chasing_player = true
	if defender.current_defense > 0:
		defender.current_defense -= current_damage
		current_damage -= hold_defense

	if current_damage <= 0:
		current_damage = 0
		defender.get_node("AnimationPlayer").play("attack_dodged")
	else:
		defender.get_node("AnimationPlayer").play("take_dmg_anim")
	defender.health -= current_damage
	print(attacker.char_name + ' attacked ' + defender.char_name + ' for ' + str(attack_details["damage"]))
	if defender.health <= 0:
		if not is_player:
			defender.remove_enemy()
		else:
			print("player is dead")


# warning-ignore:unused_argument
func get_char_dmg(attacker, defender):
	var dmg = attacker.current_damage
	if attacker.stealth: dmg += attacker.stealth_dmg_bonus
	return dmg


func attack(attacker, defender, player_attacking=false):
	""" Check tile, see if enemy is there and we are in range, if so attack (keep
		stats if we want to undo the attack) ELSE do the move to tile stuff
	"""
	var player = get_node("/root/player")
	var is_in_attack_range = false
	var hit = false
	var adjacent_tiles_in_range = meta.get_adjacent_tiles_in_distance(attacker.current_tile, attacker.current_atk_range, "fill")
	for tile in adjacent_tiles_in_range:
		if defender.current_tile == tile:
			is_in_attack_range = true
			break

	if not is_in_attack_range:
		return false

	var attack_details = {
		"damage": get_char_dmg(attacker, defender)
	}

	if attacker.current_attack > 0 and main.checkIfNodeDeleted(defender) == false and defender.alive:
		attacker.current_attack -= 1
		hit = true
		take_damage(attacker, attack_details, defender, not player_attacking)
		var shake_vel = attack_details["damage"]
		if shake_vel < 5:
			shake_vel = 5
		elif shake_vel > 20:
			shake_vel = 20
		main.cameraShake(attacker.get_node("cam"), shake_vel, .4)
		var dmg_effect = main.DMG_EFFECT_SCENE.instance()
		get_node("/root").call_deferred("add_child", dmg_effect)
		dmg_effect.position = defender.global_position
		dmg_effect.set_new_text("-"+str(attack_details["damage"]), dmg_effect.hurt_red_color)
		var l = get_node("/root/level")
		l.change_turn_display_name(defender)
		
	var l = get_node("/root/level")
	if main.checkIfNodeDeleted(l) == false:
		if l.is_player_stealth():
			player.get_node("cam/overlays and underlays/stealth_overlay").visible = true
			player.get_node("cam/overlays and underlays/chased_overlay").visible = false
		else:
			player.get_node("cam/overlays and underlays/stealth_overlay").visible = player.invisible
			player.get_node("cam/overlays and underlays/chased_overlay").visible = not player.invisible
	return hit


func get_vol_range(is_player=true, node_making_noise=null):
	if not node_making_noise:
		return
# warning-ignore:unused_variable
	var val = 0
	if is_player:
		if node_making_noise.stealh: val -= node_making_noise.stealth_noise_val
	return 

func get_character_display_text(character):
# warning-ignore:unused_variable
	var char_name = str(character.char_name)
	var character_stats = " -- " + str(character.char_name) + " -- "
	var additional_details = ""
	# additional_details are anything else we want to show, status effects, even if they are more "character stats"
	# they are just not the 'main' ones
	
	character_stats += "\nHP: " + str(character.health)
	#if character.health < character.starting_turn_health:
	character_stats += " / " + str(character.starting_turn_health)
	character_stats += " ---- DEF: " + str(character.current_defense)
	character_stats += " / " + str(character.current_battle_defense)

	character_stats += "\nEnergy: " + str(character.energy)
	#if character.energy < character.default_energy:
	character_stats += " / " + str(character.default_energy)

	character_stats += " ---- Move: " + str(character.current_move_distance)
	#if character.current_battle_move_distance < character.remaining_move:
	character_stats += " / " + str(character.current_battle_move_distance)
	
	character_stats += "\nATK: " + str(character.current_attack)
	#if character.current_attack < character.current_battle_attack:
	character_stats += " / " + str(character.current_battle_attack)

	character_stats += " ---- DMG: " + str(character.current_damage)
	#if character.current_damage < character.current_battle_damage:
	character_stats += " / " + str(character.current_battle_damage)
	
	if meta.player_turn:
		additional_details += "\nNOISE: " + str(character.noise) + " tile radius."
	return [character_stats, additional_details]


func get_adjacent_tiles_in_distance(tile=null, distance=1, type="fill"):
	if not tile:
		return
	var l = get_node("/root/level")
	var all_adjacent_tiles = []
	var tile_count = len(l.level_tiles)
	var tile_index = tile.index
	
	# Fill all adjacent
	# cross up down left right
	# star all directions but not inbetween tiles
	
	if type == "fill":
		for t in l.level_tiles:
			if t.col >= tile.col - distance and t.col <= tile.col + distance and\
			   t.row >= tile.row - distance and t.row <= tile.row + distance:
				all_adjacent_tiles.append(t)

	else:
		for i in range(1, distance+1):
# warning-ignore:unused_variable
			var point_neighbors = []
			#point_neighbors = l.level_astar.get_point_connections(tile.index)
			var above_tile_idx = tile_index - (l.current_rows * i)
			var above_right_tile_idx = tile_index - (l.current_rows * i) + i
			var above_left_tile_idx = tile_index - (l.current_rows * i) - i
	
			var right_tile_idx = tile_index + i
			var below_tile_idx = tile_index + (l.current_rows * i)
			var below_right_tile_idx = tile_index + (l.current_rows * i) + i
			var below_left_tile_idx = tile_index + (l.current_rows * i) - i
		
			var left_tile_idx = tile_index - i
			# print('above_tile_idx ' + str(above_tile_idx))
			if tile.col > - 1 + i and above_tile_idx >= 0 and above_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[above_tile_idx])
			if type == "fill" or type == "star":
				if tile.col > - 1 + i and tile.row < l.current_rows-i and above_right_tile_idx >= 0 and above_right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_right_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[above_right_tile_idx])
		
				if tile.col > - 1 + i and tile.row > -1 + i and above_left_tile_idx >= 0 and above_left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[above_left_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[above_left_tile_idx])
	
			if tile.row < l.current_rows-i and right_tile_idx >= 0 and right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[right_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[right_tile_idx])
		
			if tile.col < l.current_cols-i and below_tile_idx >= 0 and below_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[below_tile_idx])
			
			if type == "fill" or type == "star":
				if tile.col > - 1 + i and tile.row < l.current_rows-i and below_right_tile_idx >= 0 and below_right_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_right_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[below_right_tile_idx])
		
				if tile.col > - 1 + i and tile.row > -1 + i and below_left_tile_idx >= 0 and below_left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[below_left_tile_idx]) == false:
					all_adjacent_tiles.append(l.level_tiles[below_left_tile_idx])
		
			if tile.row > -1 + i and left_tile_idx >= 0 and left_tile_idx < tile_count and main.checkIfNodeDeleted(l.level_tiles[left_tile_idx]) == false:
				all_adjacent_tiles.append(l.level_tiles[left_tile_idx])
		
	return all_adjacent_tiles


func get_closest_adjacent_tile(starting_node, target_node, random=false, is_player=false):
	""" Get closest tile based on adjacent tiles. target_node needs to be a tile """
	var lowest_cost = null
	var hold_tile = null
	var found_tile = null
	var target_tile = null
	var rand_list = []
	var player = get_node("/root/player")
	for n in target_node.neighbors:
		if n.can_move:
			if random:
				if not is_player and player and player.current_tile.index != n.index:
					rand_list.append(n)
				for next_n in n.neighbors:
					if not is_player and player and player.current_tile.index != next_n.index:
						rand_list.append(next_n)
			else:
				if hold_tile == null:
					hold_tile = n
				if lowest_cost == null or starting_node.global_position.distance_to(n.global_position) <= lowest_cost:
					lowest_cost = starting_node.global_position.distance_to(n.global_position)
					found_tile = n
	
	if random and len(rand_list) > 0:
		target_tile = rand_list[rand_range(0, len(rand_list))]
	elif found_tile != null:
		target_tile = found_tile
	elif hold_tile != null:
		target_tile = hold_tile

	return target_tile
