extends Node2D

# debug stuff for testing nav
var is_end = false
var is_start = true
var can_move = true
var index = 0
var row = 0
var column = 0
var neighbors = []
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
	var debug_text = ""

	get_tile_neighbors()
	for t in l.level_tiles:
		t.modulate = Color(1, 1, 1, 1)
		if not t.can_move:
			t.modulate = Color(.4, .4, .4, 1)
	
	for n in neighbors:
		debug_text += " " + str(n.index)
		n.modulate = Color(0, 0, 1, 1)
	print('neighbors ' + str(neighbors) + " " + debug_text)
	for enm in get_tree().get_nodes_in_group("enemies"):
		enm.set_tile_target(self)
		enm.set_navigation()
		

func _on_Button_mouse_entered():
	pass # Replace with function body.


func _on_Button_mouse_exited():
	pass # Replace with function body.
