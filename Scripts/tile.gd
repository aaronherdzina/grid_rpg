extends Node2D

# debug stuff for testing nav
var is_end = false
var is_start = true
var can_move = true
var index = 0
var row = 0
var col = 0
var neighbors = []
var player_spawn = false
##

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
	var l = get_node("/root/level")
	var p = get_node("/root/player")
	var debug_text = ""

	get_tile_neighbors()
	
	if main.debug:
		for t in l.level_tiles:
			t.modulate = Color(1, 1, 1, 1)
			if not t.can_move:
				t.modulate = Color(.4, .4, .4, 1)
		for n in neighbors:
			debug_text += " " + str(n.index)
			n.modulate = Color(0, 0, 1, 1)
	if meta.player_turn:
		p.chosen_tile = self
		p.move()
		

func _on_Button_mouse_entered():
	pass # Replace with function body.


func _on_Button_mouse_exited():
	pass # Replace with function body.
