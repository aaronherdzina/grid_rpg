extends Node

var char_names = ["Thief", "Brute", "Ranger", "Wizard", "Grunt"]

var current_level_cols = 10
var current_level_rows = 6
var default_level_cols = 10
var default_level_rows = 6

var player_turn = true
var occupied_tile_weight = 1000
var unccupied_tile_weight = 1
var wall_tile_weight = 2000

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


func get_closest_adjacent_tile(starting_node, target_node):
	""" Get closest tile based on adjacent tiles. target_node needs to be a tile """
	var lowest_cost = null
	var hold_tile = null
	var found_tile = null
	var target_tile = null

	for n in target_node.neighbors:
		if n.can_move:
			if hold_tile == null:
				hold_tile = n
			if lowest_cost == null or starting_node.global_position.distance_to(n.global_position) <= lowest_cost:
				lowest_cost = starting_node.global_position.distance_to(n.global_position)
				found_tile = n

	if found_tile != null:
		target_tile = found_tile
	elif hold_tile != null:
		target_tile = hold_tile

	return target_tile
