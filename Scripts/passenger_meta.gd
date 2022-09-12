extends Node


# Declare member variables here. Examples:
####### stat bonus objects for passengers

var atk_bonus = {"bonus_name": "atk", "bonus_val": 1, "penalty_name": "dmg", "penalty_val": 1}
var reaction_dmg_bonus = {"bonus_name": "reaction_dmg", "bonus_val": 1, "penalty_name": "move", "penalty_val": 1}
var move_bonus = {"bonus_name": "move", "bonus_val": 1, "penalty_name": "defense", "penalty_val": 1}
var defense_bonus = {"bonus_name": "defense", "bonus_val": 1, "penalty_name": "move", "penalty_val": 1}


var wood_requirement = {"req_type": "wood", "amount": 1}
var grass_requirement = {"req_type": "grass", "amount": 1}
var water_requirement = {"req_type": "water", "amount": 1}
var food_requirement = {"req_type": "food", "amount": 1}
#### Passegners


func mouse_sp_func():
	print('mouse_sp_func called')
	pass


func porc_sp_func():
	print('porc_sp_func called')
	pass
	

func warb_sp_func():
	print('warb_sp_func called')
	pass

var mouse_special = funcref(self, "mouse_sp_func")
var porcupine_special = funcref(self, "porc_sp_func")
var warbler_special = funcref(self, "warb_sp_func")

####### TODO: DON'T ADD A BUNCH OF THESE, SEE IF ITS IN ENM OR PLAYER ARRAY ALREADY
####### IF SO UPDATE VALUES, KEEP SIMPLE, ALSO JUST REFERNCE VALS, !!!DON'T SET DICTS TO DICTS!!!
###### PLAYER CHARS SHOULD GET BENEFITS FOR PASSENGERS AS THEY MAY NOT BE WANT  
###### YOU WANT OTHERWISE
var mouse_passenger = {
	"type_name": "mouse",
	"amount": 1,
	"bonuses": [atk_bonus],
	"requirements": [food_requirement],
	"special": mouse_special,
	"special_description": ""
}

# start im wetlands because game world is flooding (its climate change) have fish that only work in water too
var porcupine_passenger = {
	"type_name": "porcupine",
	"amount": 1,
	"bonuses": [reaction_dmg_bonus, atk_bonus],
	"requirements": [food_requirement, grass_requirement],
	"special": porcupine_special,
	"special_description": ""
}

var warbler_passenger = {
	"type_name": "warbler",
	"amount": 1,
	"bonuses": [reaction_dmg_bonus, atk_bonus],
	"requirements": [food_requirement, wood_requirement],
	"special": warbler_special,
	"special_description": ""
}

var passenger_main_list = [mouse_passenger, porcupine_passenger, warbler_passenger]


func set_tile_passenger(tile):
	randomize()
	var passenger = passenger_main_list[rand_range(0, len(passenger_main_list))]
	# conditional level logic here

	return passenger

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
