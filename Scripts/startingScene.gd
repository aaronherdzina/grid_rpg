extends Node

const cursor = preload("res://Scenes/controllerCursor.tscn")

func _ready():
	main.controllerCursorObj = main.instancer(cursor, null, true, "cursor")

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
