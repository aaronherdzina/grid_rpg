extends Node

var char_names = ["Thief", "Brute", "Ranger", "Wizard", "Grunt"]

var current_level_cols = 10
var current_level_rows = 6
var default_level_cols = 10
var default_level_rows = 6

var player_turn = true
var max_weight =  999
var occupied_tile_weight = 1000 #10000 is min to be unpassible 
var unccupied_tile_weight = 1
var wall_tile_weight = 2000
var dangerous_terrain = 5

var current_char = {
	"move_distance": 2,
	"damage": 2,
	"attack": 2,
	"health": 10,
	"energy_max": 3
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func get_character_display_text(character):
	var char_name = str(character.char_name)
	var character_stats = " -- " + str(character.char_name) + " -- "
	
	character_stats += "\nHP: " + str(character.health)
	if character.health < character.starting_turn_health:
		character_stats += " / " + str(character.starting_turn_health)
	character_stats += " ---- DEF: " + str(character.defense)

	character_stats += "\nEnergy: " + str(character.energy)
	if character.energy < character.default_energy:
		character_stats += " / " + str(character.default_energy)

	character_stats += "\nMove: " + str(character.move_distance)
	if character.move_distance < character.remaining_move:
		character_stats += " / " + str(character.remaining_move)
	
	character_stats += " ---- ATK: " + str(character.attack)
	if character.attack < character.default_attack:
		character_stats += " / " + str(character.default_attack)

	character_stats += "\nDMG: " + str(character.damage)
	if character.damage < character.default_damage:
		character_stats += " / " + str(character.default_damage)

	return character_stats


func get_adjacent_tiles_in_distance(tile=null, distance=1, type="fill"):
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
			print('above_tile_idx ' + str(above_tile_idx))
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
