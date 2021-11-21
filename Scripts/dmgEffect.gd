extends Node2D


var life_time = 2
var hurt_red_color = Color(1, .15, .15, 1)
var heal_blue_color = Color(.15, .15, 1, 1)
var poison_green_color = Color(.15, 1, .15, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)
	$AnimationPlayer.play("dmg_text_anim")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	life_time -= delta
	if life_time <= 0:
		queue_free()

func set_new_text(text, color):
	$Label.set_text(text)
	$Label.modulate = color
