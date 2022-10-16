extends Node2D


var skill = ""
var set_skill_clr = Color(.8, .8, 1, 1)
var focus_exit_clr = Color(1, 1, 1, 1)
var focus_enter_clr = Color(.8, 1, .8, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_button()


func set_button(new_text=false):
	if new_text:
		skill = new_text
	$Label.set_text(skill)

func _on_Button_pressed():
	var player = get_node("/root/player")
	print("player skill is currently " + str(player.chosen_skill))
	player.chosen_skill =  $Label.get_text()
	print("player skill changed to " + str(player.chosen_skill))
	reset_btn_color(player)


func _on_Button_focus_entered():
	var player = get_node("/root/player")
	reset_btn_color(player)

	if $Label.get_text() == player.chosen_skill:
		modulate = set_skill_clr
	else:
		modulate = focus_enter_clr

func _on_Button_focus_exited():
	var player = get_node("/root/player")
	reset_btn_color(player)

	if $Label.get_text() == player.chosen_skill:
		modulate = set_skill_clr
	else:
		modulate = focus_exit_clr

func reset_btn_color(player):
	if not player:
		player = get_node("/root/player")
	if not player or main.checkIfNodeDeleted(player) == true:
		return

	for s in player.skill_btns:
		if s and main.checkIfNodeDeleted(s) == false:
			if s.get_node("Label").get_text() == player.chosen_skill:
				s.modulate = set_skill_clr
			else:
				s.modulate = focus_exit_clr
